# Use a stable Debian base image
FROM debian:stable-slim

# Install system tools and Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sshpass \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        python3 \
        python3-pip \
        python3-venv \
        openssh-client \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Create virtual environment for Python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages in venv
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir ansible ansible-core

# Install HashiCorp tools
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        vault \
        consul \
        nomad \
        terraform && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Post-install configuration
RUN setcap cap_ipc_lock=+ep /usr/bin/vault || echo "Warning: setcap failed"
RUN ansible-galaxy collection install community.general

# Create and switch to non-root user
RUN useradd -m goldenuser && \
    mkdir -p /home/goldenuser && \
    chown goldenuser:goldenuser /home/goldenuser

# Create vault directories and default config
RUN mkdir -p /vault/config /vault/data && \
    chown -R goldenuser:goldenuser /vault

# Create default vault config
RUN echo 'storage "file" {\n  path = "/vault/data"\n}\n\nlistener "tcp" {\n  address = "0.0.0.0:8200"\n  tls_disable = 1\n}\n\nui = true' > /vault/config/vault.hcl && \
    chown goldenuser:goldenuser /vault/config/vault.hcl

# Create simple entrypoint
RUN echo '#!/bin/sh\nexec "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

WORKDIR /home/goldenuser
USER goldenuser

ENV VAULT_SKIP_VERIFY=true

ENV PATH="/opt/venv/bin:$PATH"

CMD ["ansible", "--version"]