## nomad-backup 
+ it updates and installs smbclient which is used to upload the backup file 
+ it installs the nomad binary that is used to CLI commands when performing the backup process. we get the snap shot from the available server in the cluster
+ we upload the backup file to Samba from the git-runner  

## consul-backup 
+ it updates and installs smbclient which is used to upload the backup file 
+ it installs the consul binary that is used to CLI commands when performing the backup process. we get the snap shot from the available server in the cluster
+ we upload the backup file to Samba from the git-runner 

## gitea-backup 
+ installs the nomad binary and smbclient
+ and runs **gitea-back.sh** which exec into a gitea service that is running on the cluster and performs the backup commands, uploads them to Samba