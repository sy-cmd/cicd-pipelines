#!/bin/bash
set -e

# Configuration
export NOMAD_ADDR=http://192.168.50.17:4646
GITEA_JOB_NAME="gitea-test"
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="gitea-backup-${BACKUP_TIMESTAMP}.tar.gz"

# Samba configuration
SAMBA_HOST="192.168.50.11"
SAMBA_SHARE="Public"
SAMBA_USER="test"
SAMBA_PASS="arm"
SAMBA_PATH="gitea-backups"

echo "=== Gitea Backup Script ==="
echo "Finding Gitea allocation..."

# Find the Gitea allocation ID
ALLOC_ID=$(nomad job status "$GITEA_JOB_NAME" | grep -A 100 "Allocations" | grep "running" | head -1 | awk '{print $1}')

if [ -z "$ALLOC_ID" ]; then
    echo "ERROR: Could not find running allocation for job '$GITEA_JOB_NAME'"
    exit 1
fi

echo "Found allocation: $ALLOC_ID"

# Step 1: Install smbclient in container if needed
echo "Checking for smbclient in container..."
if ! nomad alloc exec "$ALLOC_ID" which smbclient > /dev/null 2>&1; then
    echo "Installing smbclient in container..."
    nomad alloc exec "$ALLOC_ID" apk add --no-cache samba-client || \
    nomad alloc exec "$ALLOC_ID" apt-get update && nomad alloc exec "$ALLOC_ID" apt-get install -y smbclient || \
    echo "WARNING: Could not install smbclient, will try alternative method"
fi

# Step 2: Create backup inside the container
echo "Creating backup inside Gitea container..."
nomad alloc exec "$ALLOC_ID" mkdir -p /tmp/gitea-backups

if ! nomad alloc exec "$ALLOC_ID" /bin/sh -c "cd /data && tar czf /tmp/gitea-backups/$BACKUP_FILE --exclude='.nfs*' gitea git/repositories"; then
    echo "ERROR: Failed to create backup"
    exit 1
fi

# Verify backup was created
CONTAINER_SIZE=$(nomad alloc exec "$ALLOC_ID" stat -c%s /tmp/gitea-backups/$BACKUP_FILE 2>/dev/null || nomad alloc exec "$ALLOC_ID" wc -c < /tmp/gitea-backups/$BACKUP_FILE)
BACKUP_SIZE_HR=$(numfmt --to=iec $CONTAINER_SIZE 2>/dev/null || echo "$CONTAINER_SIZE bytes")
echo "✓ Backup created in container: $BACKUP_SIZE_HR ($CONTAINER_SIZE bytes)"

# Step 3: Upload directly from container to Samba
echo "Uploading to Samba share directly from container..."

# Method 1: Try using smbclient from within container
if nomad alloc exec "$ALLOC_ID" which smbclient > /dev/null 2>&1; then
    echo "Using smbclient from container..."
    
    # Create directory on Samba
    nomad alloc exec "$ALLOC_ID" smbclient "//$SAMBA_HOST/$SAMBA_SHARE" -U "$SAMBA_USER%$SAMBA_PASS" -c "mkdir $SAMBA_PATH" 2>/dev/null || true
    
    # Upload file
    if nomad alloc exec "$ALLOC_ID" smbclient "//$SAMBA_HOST/$SAMBA_SHARE" -U "$SAMBA_USER%$SAMBA_PASS" -c "cd $SAMBA_PATH; put /tmp/gitea-backups/$BACKUP_FILE $BACKUP_FILE"; then
        echo "✓ Successfully uploaded to Samba from container"
        
        # Verify upload
        REMOTE_SIZE=$(smbclient "//$SAMBA_HOST/$SAMBA_SHARE" -U "$SAMBA_USER%$SAMBA_PASS" -c "cd $SAMBA_PATH; ls $BACKUP_FILE" 2>/dev/null | grep "$BACKUP_FILE" | awk '{print $3}')
        
        if [ "$REMOTE_SIZE" = "$CONTAINER_SIZE" ]; then
            echo "✓ Upload verified: sizes match ($REMOTE_SIZE bytes)"
        else
            echo "WARNING: Size mismatch. Container: $CONTAINER_SIZE, Remote: $REMOTE_SIZE"
        fi
    else
        echo "ERROR: Failed to upload to Samba from container"
        exit 1
    fi
else
    # Method 2: Use curl if available (works with some Samba setups)
    echo "Trying curl upload from container..."
    if nomad alloc exec "$ALLOC_ID" which curl > /dev/null 2>&1; then
        if nomad alloc exec "$ALLOC_ID" curl -T "/tmp/gitea-backups/$BACKUP_FILE" "smb://$SAMBA_HOST/$SAMBA_SHARE/$SAMBA_PATH/$BACKUP_FILE" -u "$SAMBA_USER:$SAMBA_PASS"; then
            echo "✓ Successfully uploaded via curl"
        else
            echo "ERROR: curl upload failed"
            exit 1
        fi
    else
        echo "ERROR: No upload method available in container"
        echo "Please install either smbclient or curl in your Gitea container"
        exit 1
    fi
fi

# Step 4: Cleanup
echo "Cleaning up..."
if nomad alloc exec "$ALLOC_ID" /bin/sh -c "rm -rf /tmp/gitea-backups"; then
    echo "✓ Removed backup directory from container"
else
    echo "WARNING: Could not remove backup directory from container"
fi

echo ""
echo "=== Backup completed successfully! ==="
echo "Backup uploaded to: //$SAMBA_HOST/$SAMBA_SHARE/$SAMBA_PATH/$BACKUP_FILE"
echo "Backup size: $BACKUP_SIZE_HR"
echo ""
echo "To download and verify the backup:"
echo "  smbclient //$SAMBA_HOST/$SAMBA_SHARE -U $SAMBA_USER%$SAMBA_PASS -c 'cd $SAMBA_PATH; get $BACKUP_FILE'"
echo "Or"
echo "  smbget -U $SAMBA_USER%$SAMBA_PASS smb://$SAMBA_HOST/$SAMBA_SHARE/$SAMBA_PATH/$BACKUP_FILE"