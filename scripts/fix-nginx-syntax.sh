#!/bin/bash

echo "Fixing Nginx configuration syntax..."

# Fix the Nginx configuration
sudo tee /etc/nginx/sites-available/shisha-log > /dev/null << 'EOF'
# HTTP server - redirect all traffic to HTTPS
server {
    listen 80;
    server_name api.shisha.toof.jp;
    
    # Allow Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    # Redirect all other HTTP traffic to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl;
    server_name api.shisha.toof.jp;

    # SSL configuration (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/api.shisha.toof.jp/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.shisha.toof.jp/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Proxy configuration
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization" always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
EOF

# Test the configuration
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "Configuration is valid. Reloading Nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx configuration fixed and reloaded!"
    
    # Test endpoints
    echo ""
    echo "Testing endpoints..."
    echo "HTTPS Health Check:"
    curl -I https://api.shisha.toof.jp/health 2>/dev/null | head -2
    echo ""
    echo "HTTP Redirect test:"
    curl -I http://api.shisha.toof.jp/health 2>/dev/null | head -2
else
    echo "❌ Configuration test failed!"
    exit 1
fi