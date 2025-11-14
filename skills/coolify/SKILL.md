---
name: coolify
description: |
  This skill provides complete knowledge for installing and managing Coolify, an open-source self-hosted PaaS (Platform as a Service) that enables deployment of applications, databases, and services with a Heroku-like experience. It should be used when setting up self-hosted application deployment platforms, installing Coolify on Ubuntu/ARM64 servers, or troubleshooting Docker-based PaaS deployments.

  Use when: installing Coolify on Ubuntu ARM64, setting up self-hosted PaaS, deploying applications with Docker, configuring Coolify on OCI instances, troubleshooting Coolify web interface access, setting up Traefik proxy with Coolify, managing Docker-based deployments.

  Keywords: coolify, self-hosted paas, open source heroku, docker deployment platform, coolify installation, ARM64 paas, coolify web interface, traefik proxy, application deployment, coolify on ubuntu, coolify docker, self-hosted netlify, coolify port 8000, coolify proxy ports
license: MIT
---

# Coolify

**Status**: Production Ready
**Last Updated**: 2025-11-13
**Dependencies**: Docker, Docker Compose
**Latest Versions**: Coolify 4.x (latest via install script), Docker 24.x+

---

## Quick Start (15 Minutes)

### 1. Install Docker (Required Dependency)

Coolify requires Docker and Docker Compose:

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
- Coolify is Docker-native and requires Docker to run
- ARM64 support requires Docker 20.10+ with ARM64 compatibility
- Docker Compose Plugin is required (not standalone docker-compose)

### 2. Install Coolify

Install Coolify using the official automated installer:

```bash
# Set admin credentials (optional - installer will prompt if not set)
export ROOT_USERNAME="admin"
export ROOT_USER_EMAIL="admin@yourdomain.com"
export ROOT_USER_PASSWORD="your-secure-password"

# Install Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Wait for services to start (30 seconds)
sleep 30

# Verify installation
docker ps | grep coolify
```

**Installation creates:**
- Coolify web interface on port 8000
- Traefik proxy on ports 80/443 (HTTP/HTTPS)
- PostgreSQL database (internal)
- Redis cache (internal)
- Multiple supporting containers

### 3. Access Web Interface and Complete Setup

```bash
# Open in browser (replace with your server IP)
http://YOUR_SERVER_IP:8000

# Login with credentials set during installation
# Or use credentials from install output

# Complete initial setup wizard:
# 1. Add localhost as first server
# 2. Create first project
# 3. Deploy first application
```

**First deployment:**
- Connect GitHub/GitLab repository
- Choose deployment type (Nixpacks, Dockerfile, Docker Compose)
- Configure domain and environment variables
- Deploy application

---

## Known Issues Prevention

This skill prevents **6** documented issues:

### Issue #1: Docker Not Installed or Incompatible Version
**Error**: "Docker is not installed" or version compatibility errors
**Source**: Missing Docker or outdated version
**Why It Happens**: Coolify requires Docker 20.10+ with Compose Plugin
**Prevention**: Install Docker CE with Compose Plugin before Coolify installation

### Issue #2: Port 8000 Already in Use
**Error**: "Cannot bind to port 8000" during installation
**Source**: Another service using port 8000
**Why It Happens**: Port conflict with existing web service
**Prevention**: Check port availability with `sudo netstat -tlnp | grep 8000` before installation

### Issue #3: Web Interface Not Accessible After Install
**Error**: Cannot access Coolify at http://server:8000
**Source**: Firewall blocking port 8000 or services still starting
**Why It Happens**: UFW or cloud firewall rules blocking access
**Prevention**: Open port 8000 in firewall before installation, wait 60s for services

### Issue #4: Insufficient Memory for Docker Containers
**Error**: Containers fail to start or restart constantly
**Source**: Not enough RAM for Coolify services + deployed apps
**Why It Happens**: Coolify requires 2GB+ RAM minimum
**Prevention**: Ensure server has at least 4GB RAM (2GB for Coolify, 2GB for apps)

### Issue #5: Admin Credentials Not Found
**Error**: Cannot find admin login credentials after installation
**Source**: Credentials output scrolled off screen or lost
**Why It Happens**: Installation completes but credentials not saved
**Prevention**: Set credentials via environment variables or save installation output to file

### Issue #6: Proxy Ports Conflict (80/443)
**Error**: "Port 80 already in use" or proxy fails to start
**Source**: Existing web server (nginx, apache) using ports 80/443
**Why It Happens**: Multiple services trying to bind to same ports
**Prevention**: Stop existing web servers or configure Coolify to use different ports

---

## Critical Rules

### Always Do

✅ **Install Docker first** - Docker CE 20.10+ with Compose Plugin required
✅ **Check port availability** - Ports 8000, 80, 443, 6001, 6002 must be free
✅ **Ensure adequate RAM** - Minimum 4GB RAM (2GB Coolify, 2GB apps)
✅ **Save admin credentials** - Export or save installation output
✅ **Open firewall ports** - Allow 8000 (web UI), 80/443 (proxy)
✅ **Wait for services to start** - 30-60 seconds after installation
✅ **Use localhost as first server** - Initial setup requires localhost server

### Never Do

❌ **Never install on systems with <2GB RAM** - Coolify won't run properly
❌ **Never skip Docker installation** - Coolify requires Docker to function
❌ **Never use standalone docker-compose** - Must use Docker Compose Plugin
❌ **Never expose port 8000 publicly without HTTPS** - Use Cloudflare tunnel or reverse proxy
❌ **Never run multiple instances on same server** - Port conflicts will occur
❌ **Never delete Coolify data directory** - Located at /data/coolify, contains all deployments
❌ **Never stop Coolify containers manually** - Use Coolify's built-in management

---

## Configuration Details

### Firewall Configuration

Open required ports for Coolify:

```bash
# Enable UFW firewall
sudo ufw --force enable

# Allow SSH (critical - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow Coolify web interface
sudo ufw allow 8000/tcp

# Allow HTTP/HTTPS proxy (for deployed apps)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Coolify proxy ports
sudo ufw allow 6001/tcp
sudo ufw allow 6002/tcp

# Check firewall status
sudo ufw status
```

### Service Management

Manage Coolify services:

```bash
# Check all Coolify containers
docker ps | grep coolify

# View Coolify logs
docker logs coolify

# Restart Coolify
docker restart coolify

# View proxy logs (Traefik)
docker logs coolify-proxy

# Check Coolify version
docker exec coolify cat /version

# Update Coolify to latest version
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

### Accessing Coolify Remotely

**Option 1: Direct IP Access (Development Only)**
```
http://YOUR_SERVER_IP:8000
```

**Option 2: Cloudflare Tunnel (Recommended for Production)**
```bash
# Use cloudflare-tunnel skill to expose Coolify securely
# Example: coolify.yourdomain.com -> http://localhost:8000
```

**Option 3: Reverse Proxy with HTTPS**
```
# Use nginx or caddy with Let's Encrypt SSL
```

---

## Deployment Types Supported

### 1. Nixpacks (Automatic Detection)
- Automatically detects language and framework
- Supports: Node.js, Python, Ruby, Go, Rust, PHP, Java
- Zero configuration required
- Recommended for standard frameworks

### 2. Dockerfile (Custom Build)
- Use existing Dockerfile in repository
- Full control over build process
- Supports multi-stage builds
- Best for complex applications

### 3. Docker Compose (Multi-Service)
- Deploy multiple containers together
- Supports service dependencies
- Internal networking automatically configured
- Ideal for full-stack applications

### 4. Static Sites
- Deploy static HTML/CSS/JS sites
- Built-in CDN support
- Automatic HTTPS with Traefik
- Perfect for frontend frameworks

---

## Production Example

This skill is based on **vibestack** project:
- **Infrastructure**: Oracle Cloud ARM64 instance (A1.Flex, 4 OCPU, 24GB RAM)
- **Coolify Version**: 4.x (latest stable)
- **Deployed Apps**: Multiple Next.js and Node.js applications
- **Cost**: $0/month (OCI Always Free tier)
- **Access Method**: Cloudflare Tunnel (secure external access)
- **Performance**: Excellent - handles 10+ concurrent deployments
- **Validation**: ✅ Production-tested for 6+ months

---

## Troubleshooting

### Coolify Web Interface Not Loading

```bash
# Check if Coolify container is running
docker ps | grep coolify

# Check Coolify logs for errors
docker logs coolify

# Check port 8000 is listening
sudo netstat -tlnp | grep 8000

# Test local access
curl -v http://localhost:8000
```

### Applications Not Accessible via Domain

```bash
# Check Traefik proxy status
docker ps | grep coolify-proxy
docker logs coolify-proxy

# Verify DNS CNAME record points to server IP
dig yourdomain.com

# Check proxy ports are open
sudo netstat -tlnp | grep -E ":(80|443)"
```

### Deployment Fails with Build Errors

```bash
# View deployment logs in Coolify web UI
# Or check Docker build logs:
docker logs <deployment-container-name>

# Common fixes:
# - Ensure Dockerfile syntax is correct
# - Check Node.js/Python version compatibility
# - Verify environment variables are set
# - Review build command configuration
```

### High Memory Usage

```bash
# Check container resource usage
docker stats

# Identify high-memory containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# Restart specific deployment to free memory
# (Use Coolify web UI for safe restart)
```

---

## Official Documentation

- **Coolify Website**: https://coolify.io
- **GitHub Repository**: https://github.com/coollabsio/coolify
- **Documentation**: https://coolify.io/docs
- **Discord Community**: https://discord.gg/coolify

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
          │  Traefik Proxy     │  Ports 80/443
          │  (coolify-proxy)   │  (Automatic HTTPS)
          └────────┬───────────┘
                   │
       ┌───────────┼───────────────────┐
       │           │                   │
   ┌───▼────┐  ┌──▼─────┐      ┌─────▼─────┐
   │Coolify │  │ App 1  │      │  App N    │
   │Web UI  │  │ (Node) │ ...  │(Python)   │
   │Port    │  └────┬───┘      └─────┬─────┘
   │8000    │       │                │
   └────────┘       │                │
                    │                │
          ┌─────────▼────────────────▼────┐
          │   Internal Docker Network      │
          │  (PostgreSQL, Redis, etc.)     │
          └────────────────────────────────┘
```

---

## Next Steps After Installation

1. **Complete Initial Setup**
   - Add localhost as server in Coolify UI
   - Configure server resources (CPU, memory limits)
   - Set up persistent storage locations

2. **Deploy First Application**
   - Connect GitHub/GitLab account
   - Select repository to deploy
   - Configure build settings and environment variables
   - Deploy and test application

3. **Configure Domain Access**
   - Add custom domain in Coolify
   - Point DNS A/CNAME record to server IP
   - Enable automatic HTTPS via Traefik

4. **Set Up Secure External Access** (Optional)
   - Use cloudflare-tunnel skill for secure access
   - Configure tunnel to expose Coolify web interface
   - Set up DNS for tunnel hostname

5. **Configure Backups**
   - Set up automated database backups
   - Configure application data backups
   - Store backups on external storage (S3, R2, etc.)

---

## Cost Estimation

**Infrastructure Options:**

| Provider | Specs | Monthly Cost | Notes |
|----------|-------|--------------|-------|
| OCI Always Free | 4 OCPU ARM64, 24GB RAM | $0 | Recommended for small projects |
| DigitalOcean | 2 vCPU, 4GB RAM | $24 | Good for medium traffic |
| Hetzner | 2 vCPU, 4GB RAM | ~$5 | Best price/performance |
| AWS Lightsail | 2 vCPU, 4GB RAM | $24 | Easy setup |

**Coolify Itself**: Free and open-source (MIT license)

---

**Production Ready**: ✅ Validated on Oracle Cloud ARM64 infrastructure
