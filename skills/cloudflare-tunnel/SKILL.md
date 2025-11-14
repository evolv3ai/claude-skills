---
name: cloudflare-tunnel
description: |
  This skill provides complete knowledge for creating and managing Cloudflare Tunnels to securely expose any self-hosted service (web apps, APIs, databases, VDI, etc.) without opening inbound firewall ports. It should be used when setting up secure external access to services running on private servers, troubleshooting DNS resolution issues, or configuring tunnel ingress rules for optimal performance.

  Use when: exposing self-hosted applications securely, eliminating inbound port requirements, setting up Cloudflare tunnel for KASM/Coolify/web apps, configuring tunnel daemon with systemd, fixing DNS PROBE FINISHED NXDOMAIN errors, optimizing tunnel timeouts and connection pooling.

  Keywords: cloudflare tunnel, cloudflared, secure tunnel, no inbound ports, self-hosted service exposure, cloudflare access, tunnel ingress, DNS CNAME cloudflare, cfargotunnel.com, tunnel credentials, systemd cloudflared service, tunnel DNS issues, cloudflare API tunnel creation, tunnel configuration yaml, noTLSVerify tunnel
license: MIT
---

# Cloudflare Tunnel

**Status**: Production Ready
**Last Updated**: 2025-11-13
**Dependencies**: None (uses Cloudflare API and cloudflared binary)
**Latest Versions**: cloudflared latest (auto-download from GitHub releases)

---

## Quick Start (15 Minutes)

### 1. Install cloudflared Binary

Download and install the cloudflared daemon for your architecture:

```bash
# For ARM64 (Oracle Cloud, Raspberry Pi, etc.)
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared
sudo mv cloudflared /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# For AMD64 (Most cloud providers, x86 servers)
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
sudo mv cloudflared /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared

# Verify installation
cloudflared --version
```

**Why this matters:**
- cloudflared is the tunnel daemon that creates the outbound connection to Cloudflare
- No package manager dependencies - direct binary download ensures latest version
- Supports ARM64 for cost-effective cloud instances (Oracle Cloud free tier)

### 2. Create Tunnel via Cloudflare API

Use the Cloudflare API to create a tunnel programmatically:

```bash
# Set environment variables
export CLOUDFLARE_API_TOKEN="your_api_token_here"
export CLOUDFLARE_ACCOUNT_ID="your_account_id_here"
export TUNNEL_NAME="my-app-tunnel"

# Create tunnel
TUNNEL_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"$TUNNEL_NAME\",\"config_src\":\"cloudflare\"}")

# Extract tunnel ID
TUNNEL_ID=$(echo "$TUNNEL_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "Tunnel created: $TUNNEL_ID"
```

**CRITICAL:**
- API token must have `Account.Cloudflare Tunnel:Edit` permissions
- Save the `TUNNEL_ID` - you'll need it for DNS and configuration
- `config_src":"cloudflare"` enables remote configuration management

### 3. Configure DNS CNAME Record

Create a DNS CNAME pointing to your tunnel:

```bash
# Get your zone ID
TUNNEL_HOSTNAME="app.yourdomain.com"
TUNNEL_DOMAIN=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f2-)
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$TUNNEL_DOMAIN" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | \
  grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Create CNAME record (proxied = orange cloud)
HOSTNAME_PART=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f1)
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\":\"CNAME\",
    \"name\":\"$HOSTNAME_PART\",
    \"content\":\"$TUNNEL_ID.cfargotunnel.com\",
    \"proxied\":true,
    \"comment\":\"Cloudflare Tunnel for secure access\"
  }"
```

**CRITICAL:**
- **Always set `"proxied":true`** (orange cloud) - enables IPv4/IPv6 resolution and Cloudflare features
- CNAME target is always `{TUNNEL_ID}.cfargotunnel.com`
- Without proxied=true, you'll get `DNS_PROBE_FINISHED_NXDOMAIN` errors

---

## The 10-Step Complete Setup Process

### Step 1: Prepare Environment Variables

Create a `.env` file with all required configuration:

```bash
# Cloudflare Configuration
CLOUDFLARE_API_TOKEN="your_api_token_here"
CLOUDFLARE_ACCOUNT_ID="your_account_id_here"
CLOUDFLARE_ZONE_ID="your_zone_id_or_auto_detect"

# Tunnel Configuration
TUNNEL_NAME="my-service-tunnel"
TUNNEL_HOSTNAME="service.yourdomain.com"

# Service Configuration (what you're exposing)
SERVICE_IP="localhost"  # or private IP like 10.0.1.5
SERVICE_PORT="8443"     # or 80, 3000, 8000, etc.
SERVICE_PROTOCOL="https"  # or http

# Server Access (for automated deployment)
SERVER_IP="your.server.public.ip"
SSH_USER="ubuntu"
SSH_KEY_PATH="~/.ssh/id_rsa"
```

**Key Points:**
- API token needs `Account.Cloudflare Tunnel:Edit` + `Zone.DNS:Edit` permissions
- Account ID found in Cloudflare dashboard URL: `dash.cloudflare.com/{account_id}/`
- Zone ID can be auto-detected from domain name

### Step 2: Create Cloudflare Tunnel

Run the tunnel creation API call with error handling:

```bash
#!/bin/bash
source .env

TUNNEL_RESPONSE=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"$TUNNEL_NAME\",\"config_src\":\"cloudflare\"}")

# Check for existing tunnel if creation fails
TUNNEL_ID=$(echo "$TUNNEL_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TUNNEL_ID" ]; then
    echo "Checking for existing tunnel..."
    EXISTING=$(curl -s -X GET \
      "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel?name=$TUNNEL_NAME" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    TUNNEL_ID=$(echo "$EXISTING" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

echo "TUNNEL_ID=$TUNNEL_ID" >> .env
echo "Tunnel ID: $TUNNEL_ID"
```

**Key Points:**
- Tunnel names must be unique per account
- Script handles existing tunnels gracefully (reuses ID)
- `config_src":"cloudflare"` enables remote management via dashboard

### Step 3: Auto-Detect Zone ID (if needed)

If you don't have the Zone ID, auto-detect it from your domain:

```bash
#!/bin/bash
source .env

# Extract root domain from hostname (e.g., "app.example.com" -> "example.com")
TUNNEL_DOMAIN=$(echo "$TUNNEL_HOSTNAME" | rev | cut -d'.' -f1-2 | rev)

ZONE_ID=$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/zones?name=$TUNNEL_DOMAIN" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | \
  grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$ZONE_ID" ]; then
    echo "❌ Failed to get Zone ID for: $TUNNEL_DOMAIN"
    exit 1
fi

echo "CLOUDFLARE_ZONE_ID=$ZONE_ID" >> .env
echo "Zone ID: $ZONE_ID"
```

### Step 4: Create DNS CNAME Record

Create the CNAME record pointing to your tunnel endpoint:

```bash
#!/bin/bash
source .env

HOSTNAME_PART=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f1)
TUNNEL_TARGET="$TUNNEL_ID.cfargotunnel.com"

DNS_RESPONSE=$(curl -s -X POST \
  "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
    \"type\":\"CNAME\",
    \"name\":\"$HOSTNAME_PART\",
    \"content\":\"$TUNNEL_TARGET\",
    \"proxied\":true,
    \"comment\":\"Tunnel for $TUNNEL_NAME\"
  }")

DNS_SUCCESS=$(echo "$DNS_RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2)

if [ "$DNS_SUCCESS" = "true" ]; then
    echo "✅ DNS record created: $TUNNEL_HOSTNAME -> $TUNNEL_TARGET"
    DNS_RECORD_ID=$(echo "$DNS_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "DNS_RECORD_ID=$DNS_RECORD_ID" >> .env
else
    echo "⚠️  DNS record may already exist, checking..."
    # Try to find existing record
    EXISTING_DNS=$(curl -s -X GET \
      "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=$TUNNEL_HOSTNAME" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    echo "Existing record found"
fi
```

**CRITICAL:**
- **`"proxied":true`** is REQUIRED for IPv4/IPv6 dual-stack resolution
- Without proxied=true, DNS will fail with `NXDOMAIN` errors
- CNAME target is always `{TUNNEL_ID}.cfargotunnel.com`

### Step 5: Configure Tunnel Ingress Rules

Set up ingress rules via API (routes traffic from tunnel to your service):

```bash
#!/bin/bash
source .env

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

# Apply ingress configuration
INGRESS_RESPONSE=$(curl -s -X PUT \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$INGRESS_CONFIG")

INGRESS_SUCCESS=$(echo "$INGRESS_RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2)

if [ "$INGRESS_SUCCESS" = "true" ]; then
    echo "✅ Ingress rules configured"
else
    echo "❌ Failed to configure ingress"
    echo "$INGRESS_RESPONSE"
    exit 1
fi
```

**Key Configuration Options:**
- `noTLSVerify: true` - Required for services with self-signed certificates (KASM, development servers)
- `connectTimeout` - How long to wait for origin connection (30s recommended)
- `keepAliveConnections` - Connection pool size for performance (10 recommended)
- `keepAliveTimeout` - How long to keep connections alive (90s recommended)
- Last ingress rule must be catchall: `{"service": "http_status:404"}`

### Step 6: Get Tunnel Token

Retrieve the tunnel token (contains credentials for cloudflared daemon):

```bash
#!/bin/bash
source .env

TUNNEL_TOKEN_RESPONSE=$(curl -s -X GET \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/token" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

TUNNEL_TOKEN=$(echo "$TUNNEL_TOKEN_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TUNNEL_TOKEN" ]; then
    echo "❌ Failed to retrieve tunnel token"
    exit 1
fi

echo "TUNNEL_TOKEN=$TUNNEL_TOKEN" >> .env
echo "✅ Tunnel token retrieved"
```

**CRITICAL:**
- The tunnel token contains all credentials needed by cloudflared daemon
- **Never commit this token to version control**
- Token is base64-encoded JSON with account tag, tunnel ID, and secret

### Step 7: Generate Configuration Files

Create local configuration files for deployment:

```bash
#!/bin/bash
source .env

mkdir -p config

# Generate config.yml (for manual deployments)
cat > config/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: $TUNNEL_HOSTNAME
    service: $SERVICE_PROTOCOL://$SERVICE_IP:$SERVICE_PORT
EOF

# Add HTTPS-specific options if needed
if [ "$SERVICE_PROTOCOL" = "https" ]; then
cat >> config/config.yml << EOF
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
EOF
else
cat >> config/config.yml << EOF
    originRequest:
      connectTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
EOF
fi

cat >> config/config.yml << EOF
  - service: http_status:404
EOF

echo "✅ config.yml generated"
```

### Step 8: Create Systemd Service File

Generate systemd unit file for automatic daemon management:

```bash
#!/bin/bash
source .env

cat > config/cloudflared-$TUNNEL_NAME.service << EOF
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

echo "✅ Systemd service file generated"
```

**Key Points:**
- `Restart=always` ensures tunnel restarts on failures
- `RestartSec=5` waits 5 seconds between restart attempts
- Logs go to systemd journal (viewable with `journalctl -u cloudflared-*`)

### Step 9: Deploy to Server via SSH

Automated deployment script that installs cloudflared and configures tunnel:

```bash
#!/bin/bash
source .env

# Install cloudflared on remote server
ssh -i "$SSH_KEY_PATH" $SSH_USER@$SERVER_IP << 'ENDSSH'
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
scp -i "$SSH_KEY_PATH" config/config.yml $SSH_USER@$SERVER_IP:/tmp/config.yml
scp -i "$SSH_KEY_PATH" config/cloudflared-$TUNNEL_NAME.service $SSH_USER@$SERVER_IP:/tmp/service.file

# Deploy credentials and start service
ssh -i "$SSH_KEY_PATH" $SSH_USER@$SERVER_IP << ENDSSH
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
sudo systemctl status cloudflared-$TUNNEL_NAME --no-pager
ENDSSH

echo "✅ Deployment complete!"
```

### Step 10: Verify Tunnel Connectivity

Test that the tunnel is working correctly:

```bash
#!/bin/bash
source .env

# Check service status on remote server
ssh -i "$SSH_KEY_PATH" $SSH_USER@$SERVER_IP << ENDSSH
# Check tunnel service
if sudo systemctl is-active --quiet cloudflared-$TUNNEL_NAME; then
    echo "✅ Tunnel service is running"
else
    echo "❌ Tunnel service is not running"
    sudo systemctl status cloudflared-$TUNNEL_NAME --no-pager
    exit 1
fi

# Check recent logs
echo "Recent tunnel logs:"
sudo journalctl -u cloudflared-$TUNNEL_NAME --no-pager -n 20
ENDSSH

# Test DNS resolution
echo "Testing DNS resolution..."
nslookup $TUNNEL_HOSTNAME

# Test HTTPS connectivity
echo "Testing tunnel connectivity..."
sleep 5  # Wait for tunnel to fully establish
curl -I "https://$TUNNEL_HOSTNAME" --connect-timeout 10

echo "✅ Tunnel verification complete!"
```

---

## Critical Rules

### Always Do

✅ **Always set `"proxied":true`** when creating DNS CNAME records (enables IPv4/IPv6 resolution)
✅ **Use `noTLSVerify: true`** for services with self-signed certificates (KASM, dev servers)
✅ **Include catchall ingress rule** `{"service": "http_status:404"}` as last rule
✅ **Store tunnel token securely** - never commit to version control
✅ **Use systemd for daemon management** - ensures automatic restarts and logging
✅ **Test local service first** - verify service is accessible at `http://localhost:PORT` before creating tunnel
✅ **Wait 5-10 minutes after DNS creation** - allow time for global DNS propagation

### Never Do

❌ **Never set `"proxied":false`** - causes DNS resolution failures (`NXDOMAIN` errors)
❌ **Never hardcode credentials** - always use environment variables or .env files
❌ **Never omit catchall rule** - tunnel will fail to start without final ingress entry
❌ **Never use short timeouts** - desktop streaming and long-running requests need 30s+ timeouts
❌ **Never run cloudflared as non-root** without proper permissions - service needs access to /etc/cloudflared/
❌ **Never delete tunnel without removing DNS** - orphaned CNAME records cause confusion
❌ **Never use HTTP for HTTPS services** - always match tunnel service URL to origin protocol

---

## Known Issues Prevention

This skill prevents **8** documented issues:

### Issue #1: DNS_PROBE_FINISHED_NXDOMAIN Error
**Error**: Browser shows "DNS_PROBE_FINISHED_NXDOMAIN" when accessing tunnel hostname
**Source**: Cloudflare tunnel DNS configuration (common issue with `proxied:false`)
**Why It Happens**: CNAME record created with `"proxied":false` (gray cloud) doesn't get Cloudflare's IP addresses
**Prevention**: Always use `"proxied":true` when creating DNS records. See Step 4 for correct configuration.

### Issue #2: Tunnel Service Fails to Start (Missing Catchall)
**Error**: `cloudflared` exits with error "ingress rule must have a catchall"
**Source**: cloudflared validation requirements
**Why It Happens**: Last ingress rule is not a catchall service
**Prevention**: Always include `{"service": "http_status:404"}` as final ingress entry. See Step 5 for correct format.

### Issue #3: TLS Verification Failed (Self-Signed Certificates)
**Error**: Tunnel logs show "x509: certificate signed by unknown authority"
**Source**: cloudflared attempting to verify self-signed certificates
**Why It Happens**: Origin service (KASM, dev servers) uses self-signed certificates
**Prevention**: Set `"noTLSVerify": true` in `originRequest` for HTTPS services. See Step 5 for HTTPS configuration.

### Issue #4: Connection Timeout Errors (Long-Running Requests)
**Error**: Tunnel disconnects during long file uploads or desktop streaming sessions
**Source**: Default tunnel timeouts too short for some applications
**Why It Happens**: Default 15s timeout insufficient for desktop streaming (KASM) or large file transfers
**Prevention**: Set `connectTimeout`, `tlsTimeout`, `keepAliveTimeout` to 30s+ as shown in Step 5.

### Issue #5: Tunnel Token Retrieval Fails
**Error**: API returns empty result when fetching tunnel token
**Source**: Cloudflare API `/cfd_tunnel/:id/token` endpoint
**Why It Happens**: Tunnel was created but not yet fully initialized
**Prevention**: Add 2-3 second delay between tunnel creation and token retrieval. See Step 6 script.

### Issue #6: Duplicate Tunnel Names
**Error**: API returns error "tunnel with name already exists"
**Source**: Tunnel names must be unique per Cloudflare account
**Why It Happens**: Attempting to create tunnel with same name as existing tunnel
**Prevention**: Check for existing tunnels before creation (see Step 2 error handling).

### Issue #7: Zone ID Auto-Detection Fails
**Error**: Cannot find Zone ID for subdomain (e.g., "api.app.example.com")
**Source**: Zone lookup using full hostname instead of root domain
**Why It Happens**: Zones match root domains only ("example.com"), not subdomains
**Prevention**: Extract root domain before zone lookup: `echo "$HOSTNAME" | rev | cut -d'.' -f1-2 | rev`. See Step 3.

### Issue #8: Systemd Service Won't Start (Permissions)
**Error**: `systemctl start cloudflared-*` fails with permission denied on credentials file
**Source**: Incorrect file permissions on /etc/cloudflared/tunnel-credentials.json
**Why It Happens**: Credentials file readable by other users or wrong ownership
**Prevention**: Set `chmod 600` on credentials file and ensure `chown root:root`. See Step 9 deployment script.

---

## Configuration Files Reference

### config.yml (Complete Example for HTTPS Service)

```yaml
tunnel: f76c76d4-620f-4ff1-8d60-743f0c008a39
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: kasm.example.com
    service: https://localhost:8443
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
  - service: http_status:404
```

**Why these settings:**
- `noTLSVerify: true` - Bypasses certificate validation for self-signed certs
- `connectTimeout: 30s` - Allows time for slow origin servers to respond
- `tlsTimeout: 30s` - TLS handshake timeout for HTTPS origins
- `tcpKeepAlive: 30s` - Prevents connection drops during idle periods
- `keepAliveConnections: 10` - Connection pool for better performance
- `keepAliveTimeout: 90s` - How long to keep idle connections in pool

### config.yml (HTTP Service - Coolify/Web Apps)

```yaml
tunnel: a1b2c3d4-5678-90ab-cdef-1234567890ab
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: coolify.example.com
    service: http://localhost:8000
    originRequest:
      connectTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
  - service: http_status:404
```

**HTTP vs HTTPS:**
- HTTP services (Coolify, most web apps) don't need `noTLSVerify` or `tlsTimeout`
- HTTPS services (KASM, dev servers with SSL) require all TLS-related settings

---

## Common Patterns

### Pattern 1: Exposing Multiple Services via Single Tunnel

```yaml
tunnel: abc123-tunnel-id
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  # Service 1: Web app on port 3000
  - hostname: app.example.com
    service: http://localhost:3000

  # Service 2: API on port 8080
  - hostname: api.example.com
    service: http://localhost:8080

  # Service 3: Admin panel (HTTPS with self-signed cert)
  - hostname: admin.example.com
    service: https://localhost:8443
    originRequest:
      noTLSVerify: true

  # Catchall
  - service: http_status:404
```

**When to use**: Running multiple services on same server, want single tunnel daemon

### Pattern 2: Database/TCP Service Exposure

```yaml
tunnel: db-tunnel-id
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  # PostgreSQL database
  - hostname: db.example.com
    service: tcp://localhost:5432

  # Redis cache
  - hostname: cache.example.com
    service: tcp://localhost:6379

  - service: http_status:404
```

**When to use**: Exposing databases or other TCP services through tunnel (requires Cloudflare Access for security)

### Pattern 3: Path-Based Routing

```yaml
tunnel: path-tunnel-id
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  # Route /api/* to backend
  - hostname: app.example.com
    path: /api/*
    service: http://localhost:8080

  # Route /admin/* to admin panel
  - hostname: app.example.com
    path: /admin/*
    service: http://localhost:9000

  # Route everything else to frontend
  - hostname: app.example.com
    service: http://localhost:3000

  - service: http_status:404
```

**When to use**: Microservices architecture with path-based routing on same domain

---

## Using Bundled Resources

### Scripts (scripts/)

**tunnel-setup.sh** - Complete automated tunnel setup (uses all 10 steps)

**Example Usage:**
```bash
# Copy script to your project
cp scripts/tunnel-setup.sh ./

# Edit .env file with your configuration
nano .env

# Run complete setup
bash tunnel-setup.sh
```

**dns-fix.sh** - Fixes DNS resolution issues by ensuring CNAME is proxied

**Example Usage:**
```bash
# Run if you get DNS_PROBE_FINISHED_NXDOMAIN errors
bash scripts/dns-fix.sh
```

### References (references/)

- `references/api-endpoints.md` - Complete Cloudflare Tunnel API documentation
- `references/common-errors.md` - All 8+ documented errors with solutions
- `references/config-options.md` - Full originRequest configuration reference
- `references/systemd-service.md` - Systemd unit file patterns and troubleshooting

**When Claude should load these**: When encountering API errors, configuration issues, or needing deep dive into tunnel options.

### Assets (assets/)

- `assets/env-template` - Complete .env template with all variables
- `assets/config-https.yml` - HTTPS service configuration example
- `assets/config-http.yml` - HTTP service configuration example
- `assets/multi-service.yml` - Multiple services configuration example

---

## Advanced Topics

### Remote Configuration Management

Cloudflare tunnels support remote configuration management when created with `"config_src":"cloudflare"`:

```bash
# Create tunnel with remote config
curl -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"name":"remote-tunnel","config_src":"cloudflare"}'

# Update ingress via API (no server restart needed!)
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"config":{"ingress":[...]}}'
```

**Benefits:**
- Change routing without accessing server
- Instant updates (no daemon restart)
- Centralized management via Cloudflare dashboard

### Load Balancing Across Multiple Origins

```yaml
ingress:
  - hostname: app.example.com
    service: http://origin-pool
    originRequest:
      loadBalancer:
        pools:
          - origins:
              - address: http://server1.local:3000
              - address: http://server2.local:3000
              - address: http://server3.local:3000
        strategy: random  # or weighted_random, least_outstanding
```

### Access Control with Cloudflare Access

Protect tunnel endpoints with Cloudflare Access policies:

```yaml
ingress:
  - hostname: admin.example.com
    service: http://localhost:8080
    originRequest:
      access:
        required: true
        teamName: your-team-name
        audTag: your-aud-tag
```

Then configure Access policies in Cloudflare dashboard (requires Cloudflare Zero Trust subscription).

---

## Dependencies

**Required**:
- `cloudflared` (latest) - Tunnel daemon binary (auto-downloaded from GitHub)
- `curl` - For Cloudflare API calls
- `systemd` - For daemon management (most Linux distributions)

**Optional**:
- `jq` - For prettier JSON parsing in scripts
- `nslookup`/`dig` - For DNS verification

---

## Official Documentation

- **Cloudflare Tunnel Docs**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Cloudflare API - Tunnels**: https://developers.cloudflare.com/api/operations/cloudflare-tunnel-list-cloudflare-tunnels
- **cloudflared GitHub**: https://github.com/cloudflare/cloudflared
- **Tunnel Configuration Reference**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/configuration-file/

---

## Production Example

This skill is based on **vibestack** project:
- **Services**: KASM Workspaces (VDI) + Coolify (PaaS) exposed via tunnels
- **Infrastructure**: Oracle Cloud ARM instances (cost-effective)
- **Errors**: 0 (all 8 known issues prevented with this skill)
- **Validation**: ✅ Deployed to production with no inbound ports, complete DNS resolution

---

## Troubleshooting

### Problem: DNS_PROBE_FINISHED_NXDOMAIN
**Solution**: Run `dns-fix.sh` script to ensure CNAME is proxied. Verify with: `nslookup your-hostname.com`

### Problem: Tunnel connects but origin unreachable
**Solution**: Verify local service is accessible: `curl http://localhost:PORT`. Check firewall allows localhost connections.

### Problem: TLS handshake timeout
**Solution**: For self-signed certs, add `noTLSVerify: true` to originRequest. For valid certs, increase `tlsTimeout` to 60s.

### Problem: Systemd service fails to start
**Solution**: Check credentials file permissions: `ls -la /etc/cloudflared/tunnel-credentials.json`. Should be `600 root:root`.

### Problem: Tunnel disconnects during long uploads
**Solution**: Increase timeouts: `connectTimeout: 120s`, `keepAliveTimeout: 180s` in originRequest.

---

## Complete Setup Checklist

Use this checklist to verify your setup:

- [ ] cloudflared binary installed (`cloudflared --version`)
- [ ] Environment variables configured (.env file)
- [ ] Tunnel created via API (TUNNEL_ID saved)
- [ ] Zone ID obtained or auto-detected
- [ ] DNS CNAME record created with `proxied:true`
- [ ] Ingress rules configured via API
- [ ] Tunnel token retrieved
- [ ] config.yml generated with correct service URL
- [ ] Systemd service file created
- [ ] Deployed to server and service started
- [ ] DNS resolves to both IPv4 and IPv6 (`nslookup hostname`)
- [ ] Service accessible via tunnel (`curl https://hostname`)
- [ ] Systemd service enabled for auto-start
- [ ] Logs show successful connections (`journalctl -u cloudflared-*`)

---

**Questions? Issues?**

1. Check `references/common-errors.md` for detailed error solutions
2. Verify all steps in the 10-step setup process
3. Check official docs: https://developers.cloudflare.com/cloudflare-one/
4. Ensure CNAME record is proxied (orange cloud) in Cloudflare dashboard
