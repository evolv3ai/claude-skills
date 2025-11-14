#!/bin/bash

# Cloudflare Tunnel Complete Setup Script
# This script automates all 10 steps of tunnel creation and deployment
# Based on production-tested vibestack implementation

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo -e "${GREEN}✅ Loaded environment from: $ENV_FILE${NC}"
else
    echo -e "${RED}❌ .env file not found at: $ENV_FILE${NC}"
    echo "Please create .env file based on assets/env-template"
    exit 1
fi

echo -e "${BLUE}🚀 Cloudflare Tunnel Complete Setup${NC}"
echo "======================================"
echo ""

# Validate required environment variables
required_vars=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID"
    "TUNNEL_NAME"
    "TUNNEL_HOSTNAME"
    "SERVICE_IP"
    "SERVICE_PORT"
    "SERVICE_PROTOCOL"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable $var is not set${NC}"
        exit 1
    fi
done

echo -e "${GREEN}📋 Configuration:${NC}"
echo "   Tunnel Name: $TUNNEL_NAME"
echo "   Hostname: $TUNNEL_HOSTNAME"
echo "   Service: $SERVICE_PROTOCOL://$SERVICE_IP:$SERVICE_PORT"
echo "   Account ID: $CLOUDFLARE_ACCOUNT_ID"
echo ""

# =============================================================================
# STEP 1: Create Cloudflare Tunnel
# =============================================================================

echo -e "${BLUE}🔧 Step 1: Creating Cloudflare Tunnel...${NC}"
TUNNEL_RESPONSE=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"$TUNNEL_NAME\",\"config_src\":\"cloudflare\"}")

# Extract tunnel ID from response
TUNNEL_ID=$(echo "$TUNNEL_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TUNNEL_ID" ]; then
    echo -e "${YELLOW}⚠️  Tunnel creation failed or tunnel already exists${NC}"
    echo "Checking for existing tunnel..."
    EXISTING_TUNNEL=$(curl -s -X GET \
      "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel?name=$TUNNEL_NAME" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    TUNNEL_ID=$(echo "$EXISTING_TUNNEL" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -z "$TUNNEL_ID" ]; then
        echo -e "${RED}❌ Could not create or find tunnel${NC}"
        echo "Response: $TUNNEL_RESPONSE"
        exit 1
    else
        echo -e "${GREEN}✅ Using existing tunnel: $TUNNEL_ID${NC}"
    fi
else
    echo -e "${GREEN}✅ Tunnel created successfully: $TUNNEL_ID${NC}"
fi

# Update .env file with tunnel ID
if ! grep -q "TUNNEL_ID=" "$ENV_FILE"; then
    echo "TUNNEL_ID=$TUNNEL_ID" >> "$ENV_FILE"
else
    sed -i.bak "s/TUNNEL_ID=.*/TUNNEL_ID=$TUNNEL_ID/" "$ENV_FILE"
fi

echo ""

# =============================================================================
# STEP 2: Get Zone ID (if not provided)
# =============================================================================

if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    echo -e "${BLUE}🔍 Step 2: Getting Zone ID for domain...${NC}"
    # Extract root domain from hostname (e.g., "app.example.com" -> "example.com")
    TUNNEL_DOMAIN=$(echo "$TUNNEL_HOSTNAME" | rev | cut -d'.' -f1-2 | rev)

    ZONE_ID=$(curl -s -X GET \
      "https://api.cloudflare.com/client/v4/zones?name=$TUNNEL_DOMAIN" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | \
      grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -z "$ZONE_ID" ]; then
        echo -e "${RED}❌ Failed to get zone ID for domain: $TUNNEL_DOMAIN${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Zone ID: $ZONE_ID${NC}"

    # Update .env file with zone ID
    if ! grep -q "CLOUDFLARE_ZONE_ID=" "$ENV_FILE"; then
        echo "CLOUDFLARE_ZONE_ID=$ZONE_ID" >> "$ENV_FILE"
    else
        sed -i.bak "s/CLOUDFLARE_ZONE_ID=.*/CLOUDFLARE_ZONE_ID=$ZONE_ID/" "$ENV_FILE"
    fi
else
    ZONE_ID="$CLOUDFLARE_ZONE_ID"
    echo -e "${GREEN}✅ Using provided Zone ID: $ZONE_ID${NC}"
fi

echo ""

# =============================================================================
# STEP 3: Create DNS CNAME Record
# =============================================================================

echo -e "${BLUE}🌐 Step 3: Creating DNS CNAME record...${NC}"
HOSTNAME_PART=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f1)
TUNNEL_DOMAIN_TARGET="$TUNNEL_ID.cfargotunnel.com"

DNS_RESPONSE=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\":\"CNAME\",
    \"name\":\"$HOSTNAME_PART\",
    \"content\":\"$TUNNEL_DOMAIN_TARGET\",
    \"proxied\":true,
    \"comment\":\"Cloudflare Tunnel for $SERVICE_PROTOCOL service\"
  }")

DNS_SUCCESS=$(echo "$DNS_RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2)

if [ "$DNS_SUCCESS" = "true" ]; then
    echo -e "${GREEN}✅ DNS CNAME record created: $TUNNEL_HOSTNAME -> $TUNNEL_DOMAIN_TARGET${NC}"

    # Extract and save DNS record ID
    DNS_RECORD_ID=$(echo "$DNS_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$DNS_RECORD_ID" ]; then
        if ! grep -q "DNS_RECORD_ID=" "$ENV_FILE"; then
            echo "DNS_RECORD_ID=$DNS_RECORD_ID" >> "$ENV_FILE"
        else
            sed -i.bak "s/DNS_RECORD_ID=.*/DNS_RECORD_ID=$DNS_RECORD_ID/" "$ENV_FILE"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  DNS record creation failed or already exists${NC}"
    echo "Checking for existing DNS record..."
    EXISTING_DNS=$(curl -s -X GET \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$TUNNEL_HOSTNAME" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

    EXISTING_RECORD_ID=$(echo "$EXISTING_DNS" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$EXISTING_RECORD_ID" ]; then
        echo -e "${GREEN}✅ Found existing DNS record: $EXISTING_RECORD_ID${NC}"
        if ! grep -q "DNS_RECORD_ID=" "$ENV_FILE"; then
            echo "DNS_RECORD_ID=$EXISTING_RECORD_ID" >> "$ENV_FILE"
        else
            sed -i.bak "s/DNS_RECORD_ID=.*/DNS_RECORD_ID=$EXISTING_RECORD_ID/" "$ENV_FILE"
        fi
    fi
fi

echo ""

# =============================================================================
# STEP 4: Configure Tunnel Ingress Rules
# =============================================================================

echo -e "${BLUE}⚙️  Step 4: Configuring tunnel ingress rules...${NC}"

# Build ingress configuration based on service protocol
if [ "$SERVICE_PROTOCOL" = "https" ]; then
    # HTTPS service (e.g., KASM on 8443)
    INGRESS_CONFIG="{
      \"config\": {
        \"ingress\": [
          {
            \"hostname\": \"$TUNNEL_HOSTNAME\",
            \"service\": \"https://$SERVICE_IP:$SERVICE_PORT\",
            \"originRequest\": {
              \"noTLSVerify\": true,
              \"connectTimeout\": \"30s\",
              \"tlsTimeout\": \"30s\",
              \"tcpKeepAlive\": \"30s\",
              \"keepAliveConnections\": 10,
              \"keepAliveTimeout\": \"90s\"
            }
          },
          {
            \"service\": \"http_status:404\"
          }
        ]
      }
    }"
else
    # HTTP service (e.g., Coolify on 8000)
    INGRESS_CONFIG="{
      \"config\": {
        \"ingress\": [
          {
            \"hostname\": \"$TUNNEL_HOSTNAME\",
            \"service\": \"http://$SERVICE_IP:$SERVICE_PORT\",
            \"originRequest\": {
              \"connectTimeout\": \"30s\",
              \"tcpKeepAlive\": \"30s\",
              \"keepAliveConnections\": 10,
              \"keepAliveTimeout\": \"90s\"
            }
          },
          {
            \"service\": \"http_status:404\"
          }
        ]
      }
    }"
fi

INGRESS_RESPONSE=$(curl -s -X PUT \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$INGRESS_CONFIG")

INGRESS_SUCCESS=$(echo "$INGRESS_RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2)

if [ "$INGRESS_SUCCESS" = "true" ]; then
    echo -e "${GREEN}✅ Tunnel ingress rules configured successfully${NC}"
else
    echo -e "${RED}❌ Failed to configure tunnel ingress rules${NC}"
    echo "Response: $INGRESS_RESPONSE"
    exit 1
fi

echo ""

# =============================================================================
# STEP 5: Get Tunnel Token
# =============================================================================

echo -e "${BLUE}🔑 Step 5: Retrieving tunnel credentials...${NC}"

# Add small delay to ensure tunnel is fully initialized
sleep 2

TUNNEL_CREDS_RESPONSE=$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/token" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

TUNNEL_TOKEN=$(echo "$TUNNEL_CREDS_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TUNNEL_TOKEN" ]; then
    echo -e "${RED}❌ Failed to retrieve tunnel credentials${NC}"
    echo "Response: $TUNNEL_CREDS_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Tunnel credentials retrieved successfully${NC}"

# Save tunnel token to .env (but warn about security)
if ! grep -q "TUNNEL_TOKEN=" "$ENV_FILE"; then
    echo "TUNNEL_TOKEN=$TUNNEL_TOKEN" >> "$ENV_FILE"
else
    sed -i.bak "s|TUNNEL_TOKEN=.*|TUNNEL_TOKEN=$TUNNEL_TOKEN|" "$ENV_FILE"
fi

echo -e "${YELLOW}⚠️  SECURITY: Tunnel token saved to .env - DO NOT commit to version control!${NC}"

echo ""

# =============================================================================
# STEP 6-7: Generate Configuration Files
# =============================================================================

echo -e "${BLUE}📝 Step 6-7: Generating configuration files...${NC}"

# Create config directory
CONFIG_DIR="$SCRIPT_DIR/../config"
mkdir -p "$CONFIG_DIR"

# Generate tunnel config.yml
cat > "$CONFIG_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: $TUNNEL_HOSTNAME
    service: $SERVICE_PROTOCOL://$SERVICE_IP:$SERVICE_PORT
EOF

# Add HTTPS-specific options if needed
if [ "$SERVICE_PROTOCOL" = "https" ]; then
cat >> "$CONFIG_DIR/config.yml" << EOF
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
EOF
else
cat >> "$CONFIG_DIR/config.yml" << EOF
    originRequest:
      connectTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
EOF
fi

cat >> "$CONFIG_DIR/config.yml" << EOF
  - service: http_status:404
EOF

# Generate systemd service file
cat > "$CONFIG_DIR/cloudflared-$TUNNEL_NAME.service" << EOF
[Unit]
Description=Cloudflare Tunnel ($TUNNEL_NAME)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✅ Configuration files generated in: $CONFIG_DIR${NC}"
echo ""

# =============================================================================
# STEP 8-10: Deploy to Server (if SSH configured)
# =============================================================================

if [ -n "$SERVER_IP" ] && [ -n "$SSH_USER" ] && [ -n "$SSH_KEY_PATH" ]; then
    echo -e "${BLUE}📦 Step 8-10: Deploying to server...${NC}"

    # Install cloudflared on remote server
    echo "Installing cloudflared on $SERVER_IP..."
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << 'ENDSSH'
set -e

# Check if already installed
if command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared already installed: $(cloudflared --version)"
else
    echo "Installing cloudflared..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    else
        URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    fi

    curl -L "$URL" -o /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    echo "cloudflared installed: $(cloudflared --version)"
fi

# Create cloudflared directory
sudo mkdir -p /etc/cloudflared
ENDSSH

    # Copy configuration files
    echo "Uploading configuration..."
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no \
        "$CONFIG_DIR/config.yml" "$SSH_USER@$SERVER_IP:/tmp/config.yml"
    scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no \
        "$CONFIG_DIR/cloudflared-$TUNNEL_NAME.service" "$SSH_USER@$SERVER_IP:/tmp/service.file"

    # Deploy credentials and start service
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" << ENDSSH
set -e

# Move config file
sudo mv /tmp/config.yml /etc/cloudflared/config.yml
sudo chmod 644 /etc/cloudflared/config.yml

# Create credentials from token
echo '$TUNNEL_TOKEN' | sudo tee /etc/cloudflared/tunnel-credentials.json > /dev/null
sudo chmod 600 /etc/cloudflared/tunnel-credentials.json

# Install systemd service
sudo mv /tmp/service.file /etc/systemd/system/cloudflared-$TUNNEL_NAME.service
sudo chmod 644 /etc/systemd/system/cloudflared-$TUNNEL_NAME.service

# Start service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-$TUNNEL_NAME
sudo systemctl start cloudflared-$TUNNEL_NAME

echo "✅ Tunnel deployed and started"
sleep 3
sudo systemctl status cloudflared-$TUNNEL_NAME --no-pager
ENDSSH

    echo -e "${GREEN}✅ Deployment complete!${NC}"
else
    echo -e "${YELLOW}ℹ️  Skipping server deployment (SSH not configured)${NC}"
    echo "To deploy manually:"
    echo "  1. Copy files from $CONFIG_DIR to your server"
    echo "  2. Follow instructions in SKILL.md Step 9"
fi

echo ""

# =============================================================================
# FINAL SUMMARY
# =============================================================================

echo -e "${GREEN}🎉 Cloudflare Tunnel Setup Complete!${NC}"
echo "===================================="
echo ""
echo "📋 Summary:"
echo "   ✅ Tunnel created: $TUNNEL_ID"
echo "   ✅ DNS record configured: $TUNNEL_HOSTNAME"
echo "   ✅ Ingress rules configured"
echo "   ✅ Configuration files generated"
if [ -n "$SERVER_IP" ]; then
    echo "   ✅ Deployed to server: $SERVER_IP"
fi
echo ""
echo "🌐 Access Information:"
echo "   Public URL: https://$TUNNEL_HOSTNAME"
echo "   Local URL: $SERVICE_PROTOCOL://$SERVICE_IP:$SERVICE_PORT"
echo ""

if [ -n "$SERVER_IP" ]; then
    echo "🔧 Service Management:"
    echo "   Check status: ssh -i $SSH_KEY_PATH $SSH_USER@$SERVER_IP 'sudo systemctl status cloudflared-$TUNNEL_NAME'"
    echo "   View logs: ssh -i $SSH_KEY_PATH $SSH_USER@$SERVER_IP 'sudo journalctl -u cloudflared-$TUNNEL_NAME -f'"
    echo "   Restart: ssh -i $SSH_KEY_PATH $SSH_USER@$SERVER_IP 'sudo systemctl restart cloudflared-$TUNNEL_NAME'"
    echo ""
fi

echo "🧪 Test the connection:"
echo "   Wait 2-3 minutes for tunnel to fully establish"
echo "   Then visit: https://$TUNNEL_HOSTNAME"
echo ""
echo "📄 All configuration details saved in: $ENV_FILE"
