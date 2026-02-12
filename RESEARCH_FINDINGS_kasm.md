# KASM Skill Rebuild - Research Findings

**Date**: 2026-02-11
**Sources**: Official KASM docs, personal kasm-admin docs (~40 files), current skill audit, GitHub issues
**Purpose**: Comprehensive research to inform full rebuild of `skills/kasm/` skill

---

## 1. KASM Platform Overview

### Current Version
- **Latest**: 1.18.1 (user's server runs 1.17.0)
- **New in 1.18**: Bulk import for users/servers (CSV), new docs site at docs.kasm.com

### Architecture
- Container-based VDI - streams desktops to browsers via KasmVNC
- Components: Web App, API Server, Manager, Agent, Database (PostgreSQL), Proxy
- Single-server or multi-server deployment options
- All components run as Docker containers

### System Requirements
- **Docker**: >= 25.0.5
- **Docker Compose**: >= 2.40.2
- **Minimum**: 2 cores, 4GB RAM, 75GB SSD
- **Per session**: Default 2,768MB RAM + 2 cores
- **Swap**: Strongly recommended even with sufficient RAM
- **Supported OS**: Ubuntu 22.04/24.04, Debian 11/12, Oracle Linux 8/9, RHEL 8/9/10, Raspberry Pi OS 11/12, AlmaLinux 8/9, Rocky Linux 8/9
- **Architectures**: amd64 and arm64 (not all workspace images available on arm64)

### Key Paths
- Installation: `/opt/kasm/current/`
- Logs: `/opt/kasm/current/log/` (raw + json)
- Start/Stop: `/opt/kasm/current/bin/start` and `/opt/kasm/current/bin/stop`
- Database: PostgreSQL in `kasm_db` container, user `kasmapp`, db `kasm`, port 5432
- Profiles: `/mnt/kasm_profiles/{username}/{image_id}`
- Docker dir: `/var/lib/docker`

---

## 2. API Facts (Corrected from Audit)

### Authentication
- **WRONG** (old skill): HTTP Basic Auth with `api_key:api_key_secret`
- **CORRECT**: JSON payload with `api_key` and `api_key_secret` in request body
- All requests are POST with JSON body

### Correct Endpoint Names
| Function | WRONG (old skill) | CORRECT |
|----------|-------------------|---------|
| List workspaces | `get_workspaces` | `get_images` |
| Update workspace | `update_workspace` | `update_image` |
| System info | `get_server_info` | `system_info` |
| Create storage | `create_storage_mapping` | `create_storage_provider` |
| Get storage | `get_storage_mappings` | `get_storage_providers` |

### API Terminology
- KASM API calls workspaces "images" (Docker images that back workspaces)
- Storage "mappings" in UI are "storage_providers" in API
- "Servers" are agent nodes that run containers

---

## 3. Installation Knowledge

### Fresh Install Steps (from personal experience + official docs)
1. Ensure Docker CE + Compose plugin installed
2. Download KASM installer (version-specific URL)
3. Run installer with `--accept-eula` flag
4. Extract admin credentials from `install_log.txt`
5. Access at `https://SERVER_IP` (self-signed cert)
6. Configure swap file (critical for stability)

### Download URL Pattern
```
https://kasm-static-content.s3.amazonaws.com/kasm_release_{version}.tar.gz
```
Note: Version format is like `1.18.1.xxxxxx` - needs exact build number.

### Post-Install Essentials
- Configure swap: `fallocate -l 8G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile`
- Add to `/etc/fstab`: `/swapfile none swap sw 0 0`
- Get credentials: `grep "admin@kasm.local" /opt/kasm/current/install_log.txt`

---

## 4. Workspace Configuration (Production-Tested)

### Volume Mappings JSON Format
```json
{
  "/mnt/dev_shared": {
    "bind": "/dv",
    "mode": "rw",
    "uid": 1000,
    "gid": 1000,
    "required": true,
    "skip_check": false
  }
}
```
Fields: `bind` (container path), `mode` (rw/ro), `uid`/`gid` (ownership), `required` (fail if missing), `skip_check` (skip existence check)

### Docker Run Config Override
```json
{
  "hostname": "dev-workspace",
  "privileged": false,
  "shm_size": "512m",
  "environment": {
    "START_PULSEAUDIO": "0",
    "DBUS_SESSION_BUS_ADDRESS": "unix:path=/run/user/1000/bus"
  }
}
```

### Docker Exec Config (First Launch)
```json
{
  "first_launch": {
    "user": "root",
    "cmd": "bash -c 'mkdir -p /run/user/1000 && chmod 700 /run/user/1000 && chown 1000:1000 /run/user/1000 && dbus-daemon --session --address=unix:path=/run/user/1000/bus --nofork --nopidfile --syslog-only &'"
  }
}
```

### Resource Configuration
- Set at workspace level: CPU cores and memory (MB)
- Default: 2 cores, 2768MB
- For lightweight tasks: 1 core, 1024MB is viable
- `shm_size`: Default 512m, increase for Chrome-heavy workloads

---

## 5. Persistent Profiles (Production-Tested)

### Volume Mount Method
- Path format: `/mnt/kasm_profiles/{username}/{image_id}`
- Variables: `{username}`, `{user_id}`, `{image_id}`
- Set at workspace or group level
- Group setting: `allow_persistent_profile` = true

### S3 Method (Backblaze B2)
- Path format: `s3://bucket-name@s3.region.backblazeb2.com/path/{username}/`
- **CRITICAL**: The `@endpoint` part is mandatory - without it, KASM does bucket listing which caused $68 bill from 16M API calls
- Requires: AWS Access Key ID + Secret in Server Settings
- Restart API after changing S3 credentials
- V4 signatures only

### Profile Environment Variables
- `KASM_PROFILE_SIZE_LIMIT`: Size in KB (e.g., 2000000 = 2GB)
- `KASM_PROFILE_FILTER`: Comma-separated excludes (`.cache,.vnc,Downloads,Uploads`)

### User Options at Launch
- **Enabled**: Load existing profile
- **Disabled**: No profile
- **Reset**: Delete and recreate

### Multi-Server Notes
- Requires shared storage (NFS, HDFS, GFS, SMB, SSHFS)
- Path must be accessible from all Agent hosts

---

## 6. Troubleshooting Playbooks (From Real Incidents)

### "No Resources Available" Error
**Root cause options**:
1. Stale hostname in database: `UPDATE managers SET manager_hostname='current-hostname' WHERE ...`
2. Agent actually lacks resources (check with `free -h`, `df -h`)
3. False positive from cached state - restart services

**Fix sequence**:
```bash
# Check resources first
free -h
df -h /var/lib/docker

# If hostname mismatch:
sudo docker exec -it kasm_db psql -U kasmapp -d kasm -c "SELECT manager_id, manager_hostname FROM managers;"
sudo docker exec -it kasm_db psql -U kasmapp -d kasm -c "UPDATE managers SET manager_hostname='$(hostname)' WHERE manager_hostname != '$(hostname)';"

# If cached state:
sudo /opt/kasm/current/bin/stop
sudo /opt/kasm/current/bin/start
```

### Container Destruction Failures (Zombie Containers)
**Symptom**: `docker.errors.APIError: 500 Server Error... "cannot remove container"... "could not kill"`
**Fix**:
```bash
sudo /opt/kasm/current/bin/stop
sudo docker rm -f <CONTAINER_ID>
sudo docker volume prune -f
sudo systemctl restart docker
sudo /opt/kasm/current/bin/start
```

### Base64/binascii Errors
**Symptom**: `binascii.Error` in `api_server/utils.py:183`, CherryPy stack trace
**Root cause**: Corrupt session tokens or malformed API requests
**Fix**: Clean session tokens from database:
```bash
sudo docker exec -it kasm_db psql -U kasmapp -d kasm -c "DELETE FROM session_tokens WHERE expiration < NOW();"
```

### Session Token Stale Data Error
**Symptom**: `StaleDataError: UPDATE statement on table 'session_tokens' expected to update 1 row(s); 0 were matched`
**Fix**: Same as above - clean stale session tokens

### File Manager Not Opening (Jammy Containers)
**Troubleshooting sequence**:
1. Test from terminal: `nautilus &` or `thunar &` or `pcmanfm &`
2. Disable PulseAudio: Docker Run Config `{"environment": {"START_PULSEAUDIO": "0"}}`
3. Check user permissions: uid 1000
4. Verify X11: `echo $DISPLAY && xrandr`
5. Restart container session (fresh)

### VS Code / Keyring Errors in KASM Containers
**Symptom**: GNOME keyring errors, MCP/VS Code settings not persisting
**Fix**: Docker Exec Config first_launch that sets up D-Bus + gnome-keyring-daemon
```json
{
  "first_launch": {
    "user": "root",
    "cmd": "bash -c 'mkdir -p /run/user/1000 && chmod 700 /run/user/1000 && chown 1000:1000 /run/user/1000 && dbus-daemon --session --address=unix:path=/run/user/1000/bus --nofork --nopidfile --syslog-only &'"
  }
}
```

### File Permission Issues (After SFTP Upload)
**Cause**: Files uploaded via SFTP have wrong ownership (root instead of kasm-user)
**Fix**: `chown -R 1000:1000 /mnt/kasm_profiles/ && chmod -R 755 /mnt/kasm_profiles/`

### Storage Provider Validation Errors (Dropbox/Nextcloud)
**Symptom**: False "No Agent slots" errors, storage validation failures
**Root cause**: Cached application state from failed storage provider
**Fix**: Restart API, Agent, Manager services:
```bash
sudo docker restart kasm_api kasm_agent kasm_manager
```

---

## 7. Backup & Recovery

### Official Methods
1. **Config Export/Import**: Admin UI > Diagnostics > Export/Import (JSON format)
2. **Database Backup**: `sudo docker exec kasm_db pg_dump -U kasmapp -Fc kasm > kasm_backup.dump`
3. **Built-in Script** (1.11.0+): `/opt/kasm/current/bin/utils/db_backup`
4. **Database Restore**: `sudo docker exec -i kasm_db pg_restore -U kasmapp -d kasm -c < kasm_backup.dump`

### Backblaze B2 Backup (Production-Tested)
- Use rclone for S3-compatible sync
- **Exclude patterns**: `.cache`, `.vnc`, `Downloads`, `Uploads`, `node_modules`, `.git`, `build/`, `dist/`
- **Lesson learned**: Missing `@endpoint` in S3 path caused 16M API calls ($68 bill)
- **Optimization**: Reduced from 48+ to 6 syncs/day with lock file mechanism
- **Monitoring**: Cron at 6 AM for daily reports

### Backup Script Pattern
```bash
rclone sync /mnt/kasm_profiles/ remote:bucket/profiles/ \
  --exclude "*.tmp" --exclude "*.cache" \
  --exclude ".vnc/**" --exclude "Downloads/**" \
  --exclude "Uploads/**" --exclude "node_modules/**" \
  --exclude ".git/**" --bwlimit 50M
```

---

## 8. Networking & Access

### Cloudflare Tunnel (Production-Tested)
- Requires `noTLSVerify: true` in tunnel config (KASM uses self-signed cert)
- Zone config: Set Upstream Auth Address to server IP or "proxy"
- Set Proxy Port to 0 for auto-detection

### Zone Configuration
- Access: Infrastructure > Zones > Edit default zone
- Upstream Auth Address: IP/FQDN of KASM server (single-server) or Web App role (multi-server)
- Proxy Port: Set to 0 for auto-detect from window.location.port
- Changes apply to NEW sessions only

### Reverse Proxy Support
- Nginx, Caddy, HAProxy, Apache all documented
- WebSocket upgrade required for desktop streaming

---

## 9. Service Management

### Start/Stop
```bash
sudo /opt/kasm/current/bin/stop    # Stop all services
sudo /opt/kasm/current/bin/start   # Start all services
```

### Individual Container Restart
```bash
sudo docker restart kasm_api       # API server only
sudo docker restart kasm_agent     # Agent only
sudo docker restart kasm_manager   # Manager only
sudo docker restart kasm_proxy     # Proxy only
```

### Logs
```bash
sudo docker logs -f kasm_api           # API logs (live)
sudo docker logs -f --tail 50 kasm_agent  # Agent logs (last 50)
sudo docker logs -n 1000 -f <CONTAINER_ID>  # Workspace container logs
```
File logs: `/opt/kasm/current/log/` (raw + JSON format)

---

## 10. Database Operations

### Connection
```bash
sudo docker exec -it kasm_db psql -U kasmapp -d kasm
```

### Common Queries
```sql
-- List all images/workspaces
SELECT image_id, friendly_name, enabled FROM images;

-- Check managers
SELECT manager_id, manager_hostname FROM managers;

-- Clean stale session tokens
DELETE FROM session_tokens WHERE expiration < NOW();

-- Fix hostname mismatch
UPDATE managers SET manager_hostname='correct-hostname' WHERE manager_hostname='old-hostname';

-- Check storage providers
SELECT * FROM storage_providers;
```

---

## 11. User's Production Environment

### Server
- Hetzner VPS: 5.161.200.197
- AMD EPYC 4-core, 8GB RAM, Ubuntu 22.04
- KASM uses ~960MB (~12.5% of RAM)
- Groups: "Vibe Coders" for shared access

### Shared Workspace
- Host path: `/mnt/dev_shared` mapped to container `/dv` (bind mount)
- Folder structure: `/dv/projects/`, `/dv/resources/`, `/dv/tools/`
- Sync to Backblaze B2 via rclone

### Users
- admin@kasm.local, dev, aty, claude
- Multiple VS Code extensions persisted via persistent profiles

---

## 12. What the New Skill Should Cover

### Core Domains (from user request + research)
1. **Installation** - Fresh install, upgrades, system requirements
2. **Configuration** - Workspaces, profiles, volume mappings, Docker overrides, zones
3. **Troubleshooting** - All the playbooks above (7+ real-world scenarios)
4. **Backup & Recovery** - Config export, database backup, S3 sync
5. **Management** - Service control, user management, API operations
6. **Networking** - Cloudflare Tunnel, reverse proxy, zone config
7. **Storage** - Persistent profiles, volume mappings, S3/B2 integration

### Design Notes (from user)
- "Flexible pieces of knowledge" not brittle shell scripts
- "TUI interviews" for configuration workflows
- "All-purpose skill for all things related to KASM"
- Knowledge-based approach: teach Claude the patterns, not hardcode scripts

### What to Keep from Old Skill
- Cloudflare Tunnel reference (accurate, working)
- Env template (good reference for variables)
- General skill structure (SKILL.md + references/)

### What to Remove
- Shell scripts (lib/, modules/, wizard)
- Hardcoded version numbers
- Wrong API code (kasm-api.sh)
- Non-existent file references
- input-schema.json (non-standard)

---

## 13. Known GitHub Issues (Community)

- Persistent Profile Data Loss (#622) - S3 mounted drives losing small files
- Browser workspace install fails after 1.16->1.17 upgrade (#744)
- OIDC/TLS verification failures (#834)
- Out of memory: Killed process (dockerd) loop (#680)
- RDP client errors behind Cloudflare (#728, #539)
- Networking issues with bridge mode (#693)

---

## 14. Recommended Skill Architecture

```
skills/kasm/
  SKILL.md                          # Main entry point (progressive disclosure)
  README.md                         # Auto-trigger keywords
  .claude-plugin/plugin.json        # Marketplace manifest (keywords: [])
  references/
    installation.md                 # Fresh install + upgrade guide
    workspace-configuration.md      # Profiles, volumes, Docker overrides
    troubleshooting.md              # All playbooks from section 6
    backup-recovery.md              # All backup methods + S3 sync
    networking.md                   # Cloudflare Tunnel, reverse proxy, zones
    database-operations.md          # SQL queries, common DB tasks
    api-reference.md                # Correct API auth + endpoints
    service-management.md           # Start/stop, logs, container ops
```

SKILL.md should use progressive disclosure:
- Step 0: Determine what the user needs (install, configure, troubleshoot, backup)
- Branch to appropriate reference file
- Each reference file is self-contained with copy-paste-ready commands
