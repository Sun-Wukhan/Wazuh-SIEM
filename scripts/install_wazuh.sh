#!/bin/bash

# Wazuh Docker Installation Script
# Based on: https://documentation.wazuh.com/current/deployment-options/docker/wazuh-container.html

set -e

# Log all output
exec > >(tee -a /var/log/wazuh-install.log)
exec 2>&1

echo "Starting Wazuh installation at $(date)"

# Update system
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
echo "Installing required packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git

# Install Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker wazuhuser

# Install Docker Compose (standalone)
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone Wazuh Docker repository
echo "Cloning Wazuh Docker repository..."
cd /opt
git clone https://github.com/wazuh/wazuh-docker.git -b v${wazuh_version}
chown -R wazuhuser:wazuhuser /opt/wazuh-docker

# Navigate to single-node directory
cd /opt/wazuh-docker/single-node

# Generate certificates
echo "Generating SSL certificates..."
docker compose -f generate-indexer-certs.yml run --rm generator

# Set proper ownership
chown -R wazuhuser:wazuhuser /opt/wazuh-docker

# Deploy Wazuh stack
echo "Deploying Wazuh stack..."
docker compose up -d

# Wait for services to be ready
echo "Waiting for Wazuh services to start..."
sleep 60

# Check if services are running
docker compose ps

# Create systemd service for auto-start
echo "Creating systemd service for Wazuh..."
cat > /etc/systemd/system/wazuh-docker.service << EOF
[Unit]
Description=Wazuh Docker Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/wazuh-docker/single-node
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wazuh-docker.service

# Create convenience script for user
cat > /home/wazuhuser/wazuh-control.sh << 'EOF'
#!/bin/bash
cd /opt/wazuh-docker/single-node

case "$1" in
    start)
        echo "Starting Wazuh stack..."
        docker compose up -d
        ;;
    stop)
        echo "Stopping Wazuh stack..."
        docker compose down
        ;;
    restart)
        echo "Restarting Wazuh stack..."
        docker compose down
        docker compose up -d
        ;;
    status)
        echo "Wazuh stack status:"
        docker compose ps
        ;;
    logs)
        docker compose logs -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF

chmod +x /home/wazuhuser/wazuh-control.sh
chown wazuhuser:wazuhuser /home/wazuhuser/wazuh-control.sh

# Final status check
echo "Installation completed at $(date)"
echo "Wazuh Dashboard URL: https://$(curl -s ifconfig.me):443"
echo "Default credentials: admin / SecretPassword"
echo "Use '/home/wazuhuser/wazuh-control.sh status' to check services"

# Log final status
docker compose ps >> /var/log/wazuh-install.log
echo "Wazuh installation completed successfully!" >> /var/log/wazuh-install.log
