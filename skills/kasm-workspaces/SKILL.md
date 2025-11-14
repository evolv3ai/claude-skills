---
name: kasm-workspaces
description: |
  This skill provides complete knowledge for installing and managing KASM Workspaces, a container-based Virtual Desktop Infrastructure (VDI) platform for streaming desktop and application environments to web browsers. It should be used when setting up remote desktop access, installing VDI platforms on Ubuntu/ARM64 servers, or troubleshooting browser-based desktop streaming.

  Use when: installing KASM Workspaces on Ubuntu ARM64, setting up virtual desktop infrastructure, configuring browser-based remote desktops, deploying VDI on OCI instances, troubleshooting KASM web interface access, managing Docker-based desktop streaming, setting up secure remote workspace access.

  Keywords: kasm workspaces, VDI platform, virtual desktop infrastructure, browser-based desktop, remote desktop streaming, kasm installation, docker vdi, ARM64 vdi, kasm web interface, kasm port 8443, container streaming, workspace containers, kasm on ubuntu, self-hosted vdi, kasm docker
license: MIT
---

# KASM Workspaces

**Status**: Production Ready
**Last Updated**: 2025-11-13
**Dependencies**: Docker, Docker Compose
**Latest Versions**: KASM Workspaces 1.17.0, Docker 24.x+

---

## Quick Start (20 Minutes)

### 1. Install Docker (Required Dependency)

KASM requires Docker and Docker Compose:

```bash
# Install Docker dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
docker --version
docker compose version
```

**Why this matters:**
- KASM is Docker-native and requires Docker to run
- ARM64 support requires Docker 20.10+ with ARM64 compatibility
- KASM uses 8+ containers for full VDI functionality

### 2. Download and Install KASM Workspaces

Install KASM using the official installer:

```bash
# Create installation directory
mkdir -p ~/kasm-install
cd ~/kasm-install

# Download KASM Workspaces (version 1.17.0)
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.17.0.7f020d.tar.gz

# Extract installer
tar -xf kasm_release_1.17.0.7f020d.tar.gz

# Run installation (silent mode)
cd kasm_release
sudo bash kasm_release/install.sh -v -s

# Wait for services to start (30 seconds)
sleep 30
```

**Installation creates:**
- KASM web interface on port 8443 (HTTPS)
- 8+ Docker containers (API, manager, agent, database, etc.)
- PostgreSQL database (internal)
- Redis cache (internal)
- Guacamole for session management

### 3. Extract Admin Credentials and Access Web Interface

```bash
# Extract admin credentials from installation logs
ADMIN_USERNAME="admin@kasm.local"
ADMIN_PASSWORD=$(sudo grep "admin@kasm.local" ~/kasm-install/kasm_release/install_log.txt | grep -o "Password: [^[:space:]]*" | tail -1 | cut -d" " -f2)

echo "Admin Username: $ADMIN_USERNAME"
echo "Admin Password: $ADMIN_PASSWORD"

# Access web interface (replace with your server IP)
# https://YOUR_SERVER_IP:8443
```

**Important:**
- Web interface uses self-signed SSL certificate (accept browser warning)
- Change default password immediately after first login
- Admin credentials are auto-generated during installation

---

## Known Issues Prevention

This skill prevents **7** documented issues:

### Issue #1: Docker Not Installed or Incompatible Version
**Error**: "Docker is not installed" or version compatibility errors
**Source**: Missing Docker or outdated version
**Why It Happens**: KASM requires Docker 20.10+ for container streaming
**Prevention**: Install Docker CE with Compose Plugin before KASM installation

### Issue #2: Insufficient Containers Running (< 8)
**Error**: KASM web interface loads but workspaces don't launch
**Source**: Not all KASM containers started successfully
**Why It Happens**: Memory constraints or Docker service issues
**Prevention**: Ensure 8GB+ RAM available, verify all containers with `docker ps | grep kasm`

### Issue #3: Self-Signed Certificate Warning
**Error**: Browser shows "Your connection is not private" warning
**Source**: KASM uses self-signed SSL certificate by default
**Why It Happens**: No valid SSL certificate configured during installation
**Prevention**: Accept browser warning (click "Advanced" → "Proceed"), or configure custom SSL cert

### Issue #4: Web Interface Not Accessible (Port 8443)
**Error**: Cannot access KASM at https://server:8443
**Source**: Firewall blocking port 8443 or services still starting
**Why It Happens**: UFW or cloud firewall rules blocking HTTPS access
**Prevention**: Open port 8443 in firewall before installation, wait 60s for services

### Issue #5: Admin Credentials Not Found
**Error**: Cannot find admin login credentials after installation
**Source**: Installation logs not saved or credentials scrolled off screen
**Why It Happens**: Installation completes but credentials not extracted
**Prevention**: Extract credentials from ~/kasm-install/kasm_release/install_log.txt

### Issue #6: Insufficient Memory for Workspaces
**Error**: Desktop sessions fail to launch or are extremely slow
**Source**: Not enough RAM for KASM services + desktop containers
**Why It Happens**: KASM requires 4GB+ for services, 2-4GB per active desktop session
**Prevention**: Ensure server has at least 8GB RAM (4GB KASM, 4GB for 1-2 concurrent sessions)

### Issue #7: Session Ports Not Accessible (3000-4000)
**Error**: Desktop sessions connect but display is black or frozen
**Source**: Firewall blocking session ports 3000-4000
**Why It Happens**: Browser cannot establish WebSocket connections to session ports
**Prevention**: Open TCP ports 3000-4000 in firewall for session streaming

---

## Critical Rules

### Always Do

✅ **Install Docker first** - Docker CE 20.10+ with Compose Plugin required
✅ **Ensure adequate RAM** - Minimum 8GB RAM (4GB KASM, 4GB sessions)
✅ **Open firewall ports** - 8443 (web UI), 3000-4000 (sessions), 3389 (RDP optional)
✅ **Save admin credentials** - Extract from install_log.txt immediately
✅ **Accept SSL warning** - Self-signed certificate is expected
✅ **Wait for all containers** - Verify 8+ containers running before use
✅ **Change default password** - Critical security step after first login

### Never Do

❌ **Never install on systems with <4GB RAM** - KASM won't run properly
❌ **Never skip Docker installation** - KASM requires Docker to function
❌ **Never expose port 8443 publicly without additional security** - Use Cloudflare tunnel or VPN
❌ **Never delete KASM data directory** - Located at /opt/kasm, contains all sessions/configs
❌ **Never stop KASM containers individually** - Use docker compose commands from install directory
❌ **Never run KASM on same server as other web services using 8443** - Port conflict
❌ **Never ignore memory warnings** - Each active desktop session consumes 2-4GB RAM

---

## Configuration Details

### Firewall Configuration

Open required ports for KASM:

```bash
# Enable UFW firewall
sudo ufw --force enable

# Allow SSH (critical - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow KASM web interface (HTTPS)
sudo ufw allow 8443/tcp

# Allow RDP access (optional)
sudo ufw allow 3389/tcp

# Allow KASM session ports (WebSocket streaming)
sudo ufw allow 3000:4000/tcp

# Check firewall status
sudo ufw status
```

### Service Management

Manage KASM services:

```bash
# Check all KASM containers
docker ps | grep kasm

# View KASM API logs
docker logs kasm_api

# View KASM manager logs
docker logs kasm_manager

# Restart all KASM services
cd ~/kasm-install/kasm_release
sudo docker compose restart

# Stop all KASM services
cd ~/kasm-install/kasm_release
sudo docker compose stop

# Start all KASM services
cd ~/kasm-install/kasm_release
sudo docker compose start

# Check KASM version
docker exec kasm_api cat /version
```

### Accessing KASM Remotely

**Option 1: Direct IP Access (Development Only)**
```
https://YOUR_SERVER_IP:8443
```

**Option 2: Cloudflare Tunnel (Recommended for Production)**
```bash
# Use cloudflare-tunnel skill to expose KASM securely
# Example: kasm.yourdomain.com -> https://localhost:8443
# Note: Requires noTLSVerify: true for self-signed cert
```

**Option 3: VPN Access**
```bash
# Use Cloudflare Zero Trust Access or WireGuard VPN
# Keeps KASM on private network, access via VPN tunnel
```

---

## Workspace Types Available

### 1. Desktop Workspaces
- **Ubuntu Desktop**: Full Ubuntu XFCE/KDE desktop environment
- **Windows**: Windows 10/11 (requires Windows license)
- **Kali Linux**: Penetration testing desktop environment
- **CentOS/Fedora**: Enterprise Linux desktops

### 2. Application Workspaces
- **Chrome/Firefox**: Isolated browser sessions
- **VS Code**: Browser-based development environment
- **Terminal**: Linux terminal with tools
- **GIMP/Inkscape**: Graphics applications

### 3. Custom Workspaces
- Build custom Docker images for specific use cases
- Deploy custom applications in isolated containers
- Configure persistent storage for user data

---

## Production Example

This skill is based on **vibestack** project:
- **Infrastructure**: Oracle Cloud ARM64 instance (A1.Flex, 4 OCPU, 24GB RAM)
- **KASM Version**: 1.17.0 (latest stable)
- **Deployed Workspaces**: Ubuntu Desktop, Chrome, Firefox, VS Code
- **Concurrent Users**: 2-4 simultaneous desktop sessions
- **Cost**: $0/month (OCI Always Free tier)
- **Access Method**: Cloudflare Tunnel (secure external access)
- **Performance**: Excellent - smooth desktop streaming over WAN
- **Validation**: ✅ Production-tested for 6+ months

---

## Troubleshooting

### KASM Web Interface Not Loading

```bash
# Check if all KASM containers are running
docker ps | grep kasm

# Verify container count (should be 8+)
docker ps | grep kasm | wc -l

# Check KASM API logs for errors
docker logs kasm_api

# Check port 8443 is listening
sudo netstat -tlnp | grep 8443

# Test local HTTPS access
curl -k -v https://localhost:8443
```

### Workspace Sessions Won't Launch

```bash
# Check KASM agent status
docker ps | grep kasm_agent
docker logs kasm_agent

# Verify session ports are open
sudo netstat -tlnp | grep -E ":(3000|3001|3002)"

# Check available memory
free -h

# Check Docker network
docker network ls | grep kasm
```

### Black Screen or Frozen Desktop

```bash
# Check browser console for WebSocket errors
# (Open browser DevTools → Console tab)

# Verify firewall allows ports 3000-4000
sudo ufw status | grep "3000:4000"

# Check session container logs
docker logs <session-container-name>

# Restart KASM services
cd ~/kasm-install/kasm_release
sudo docker compose restart
```

### High CPU or Memory Usage

```bash
# Check resource usage per container
docker stats

# Identify resource-heavy sessions
docker ps --format "table {{.Names}}\t{{.Status}}"

# Terminate idle sessions via KASM web UI
# (Admin → Sessions → Terminate)

# Restart specific container
docker restart <container-name>
```

---

## Official Documentation

- **KASM Website**: https://www.kasmweb.com
- **Documentation**: https://kasmweb.com/docs/latest/
- **GitHub Repository**: https://github.com/kasmtech
- **Community Forum**: https://kasmweb.com/community
- **Docker Hub**: https://hub.docker.com/u/kasmweb

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  Internet                        │
└──────────────────┬──────────────────────────────┘
                   │
          ┌────────▼──────────┐
          │  Cloudflare Tunnel │  (Optional - Secure Access)
          │  or Direct Access   │
          └────────┬───────────┘
                   │
          ┌────────▼──────────┐
          │  KASM Web UI       │  Port 8443 (HTTPS)
          │  (kasm_manager)    │
          └────────┬───────────┘
                   │
       ┌───────────┼───────────────────┐
       │           │                   │
   ┌───▼────┐  ┌──▼─────┐      ┌─────▼─────┐
   │ KASM   │  │Session │      │ Session   │
   │ API    │  │  #1    │ ...  │   #N      │
   │        │  │(Chrome)│      │(Ubuntu)   │
   └────┬───┘  └────┬───┘      └─────┬─────┘
        │           │                │
        │      Ports 3000-4000       │
        │           │                │
   ┌────▼───────────▼────────────────▼────┐
   │   Internal Docker Network             │
   │  (PostgreSQL, Redis, Guacamole)       │
   └───────────────────────────────────────┘
```

---

## Next Steps After Installation

1. **Complete Initial Setup**
   - Login with admin credentials from install_log.txt
   - Change default admin password immediately
   - Configure server settings (CPU, memory limits)
   - Set up user authentication (local or SSO)

2. **Add Workspace Images**
   - Navigate to Admin → Workspaces
   - Select workspace images to enable (Ubuntu, Chrome, etc.)
   - Configure resource limits per workspace type
   - Test workspace launch and functionality

3. **Create User Accounts**
   - Add users via Admin → Users
   - Assign workspace permissions to users
   - Configure session timeout policies
   - Set up user storage quotas

4. **Configure External Access** (Optional)
   - Use cloudflare-tunnel skill for secure HTTPS access
   - Configure DNS for custom domain (kasm.yourdomain.com)
   - Set up Zero Trust Access or VPN for additional security

5. **Monitor and Optimize**
   - Monitor container resource usage with `docker stats`
   - Review session logs for performance issues
   - Adjust workspace resource limits as needed
   - Set up automated backups for KASM data

---

## Cost Estimation

**Infrastructure Options:**

| Provider | Specs | Monthly Cost | Notes |
|----------|-------|--------------|-------|
| OCI Always Free | 4 OCPU ARM64, 24GB RAM | $0 | Recommended - supports 2-4 concurrent sessions |
| DigitalOcean | 4 vCPU, 8GB RAM | $48 | Good for 3-5 concurrent sessions |
| Hetzner | 4 vCPU, 8GB RAM | ~$10 | Best price/performance ratio |
| AWS Lightsail | 4 vCPU, 8GB RAM | $40 | Easy setup, AWS integration |

**KASM Workspaces**: Free Community Edition (up to 5 concurrent sessions)
**Enterprise Edition**: Paid license required for >5 concurrent sessions

---

**Production Ready**: ✅ Validated on Oracle Cloud ARM64 infrastructure
