#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Nginx
apt-get install nginx -y
systemctl enable nginx

# Install Certbot for SSL
apt-get install certbot python3-certbot-nginx -y

# Create application directory
mkdir -p /opt/shisha-log
cd /opt/shisha-log

# Create environment file
cat > .env << EOF
PORT=8080
ENVIRONMENT=${environment}
SUPABASE_URL=${supabase_url}
SUPABASE_ANON_KEY=${supabase_anon_key}
SUPABASE_SERVICE_ROLE_KEY=${supabase_service_role_key}
JWT_SECRET=${jwt_secret}
DATABASE_URL=${database_url}
ALLOWED_ORIGINS=${allowed_origins}
TOKEN_DURATION=${token_duration}
EOF

# Create Docker Compose file
cat > docker-compose.yml << EOF
version: '3.8'

services:
  app:
    image: ${container_registry}/${container_image}
    container_name: shisha-log-app
    restart: unless-stopped
    env_file: .env
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Create Nginx configuration
cat > /etc/nginx/sites-available/shisha-log << EOF
server {
    listen 80;
    server_name ${domain_name};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }

    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/shisha-log /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Login to registry and start application
if [[ "${container_registry}" == "public.ecr.aws" ]]; then
  # For ECR Public, use AWS CLI
  apt-get install -y awscli
  aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
else
  # For other registries
  echo "${registry_password}" | docker login ${container_registry} -u "${registry_username}" --password-stdin
fi

# Start services
docker-compose pull
docker-compose up -d

# Restart Nginx
systemctl restart nginx

# Create deployment script for updates
cat > /opt/shisha-log/deploy.sh << 'EOF'
#!/bin/bash
set -e

cd /opt/shisha-log

echo "Pulling latest image..."
docker-compose pull

echo "Recreating container..."
docker-compose up -d --force-recreate

echo "Waiting for health check..."
sleep 30

if curl -f http://localhost:8080/health; then
    echo "Deployment successful!"
else
    echo "Health check failed, rolling back..."
    docker-compose restart
    exit 1
fi
EOF

chmod +x /opt/shisha-log/deploy.sh

# Create SSL certificate renewal cron job
cat > /etc/cron.d/certbot-renew << EOF
0 2 * * * root certbot renew --quiet --nginx
EOF

# Create SSL setup script
cat > /opt/shisha-log/setup-ssl.sh << 'EOF'
#!/bin/bash
set -e

DOMAIN="${domain_name}"
EMAIL="admin@${domain_name}"
MAX_RETRIES=30
RETRY_DELAY=60

echo "Starting SSL certificate setup for $DOMAIN"

# Function to check if domain resolves to this server
check_dns() {
    SERVER_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
    
    if [ "$SERVER_IP" = "$DOMAIN_IP" ]; then
        return 0
    else
        return 1
    fi
}

# Wait for DNS propagation
echo "Waiting for DNS propagation..."
for i in $(seq 1 $MAX_RETRIES); do
    if check_dns; then
        echo "DNS has propagated successfully!"
        break
    else
        echo "Attempt $i/$MAX_RETRIES: DNS not yet propagated. Server IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4), Domain IP: $(dig +short $DOMAIN | tail -n1)"
        if [ $i -lt $MAX_RETRIES ]; then
            echo "Waiting $RETRY_DELAY seconds before next attempt..."
            sleep $RETRY_DELAY
        else
            echo "DNS propagation timeout. Please run this script manually later."
            exit 1
        fi
    fi
done

# Obtain SSL certificate
echo "Obtaining SSL certificate..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

if [ $? -eq 0 ]; then
    echo "SSL certificate obtained successfully!"
    
    # Test HTTPS
    sleep 5
    if curl -k https://$DOMAIN/health > /dev/null 2>&1; then
        echo "HTTPS is working correctly!"
    else
        echo "Warning: HTTPS test failed, but certificate was installed."
    fi
else
    echo "Failed to obtain SSL certificate."
    exit 1
fi
EOF

chmod +x /opt/shisha-log/setup-ssl.sh

# Create systemd service for SSL setup
cat > /etc/systemd/system/setup-ssl.service << EOF
[Unit]
Description=Setup SSL Certificate
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/shisha-log/setup-ssl.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create timer for SSL setup (runs 5 minutes after boot)
cat > /etc/systemd/system/setup-ssl.timer << EOF
[Unit]
Description=Run SSL Setup after boot
Requires=setup-ssl.service

[Timer]
OnBootSec=5min
Unit=setup-ssl.service

[Install]
WantedBy=timers.target
EOF

# Enable the timer
systemctl daemon-reload
systemctl enable setup-ssl.timer
systemctl start setup-ssl.timer