# KASM Workspaces

**Status**: Production Ready
**Last Updated**: 2026-02-11
**Production Tested**: KASM 1.17.0 on Hetzner VPS (Ubuntu 22.04, 4-core AMD EPYC, 8GB RAM)

---

## Auto-Trigger Keywords

- kasm workspaces, VDI platform, virtual desktop infrastructure, browser-based desktop
- remote desktop streaming, kasm installation, docker vdi, ARM64 vdi
- kasm web interface, container streaming, workspace containers
- kasm on ubuntu, self-hosted vdi, kasm docker, desktop as a service
- kasm ubuntu desktop, kasm chrome workspace, kasm firefox, browser isolation
- kasm persistent profiles, kasm volume mapping, kasm S3 profiles
- kasm backup, kasm restore, kasm database, kasm pg_dump
- kasm cloudflare tunnel, kasm reverse proxy, kasm zone configuration
- kasm troubleshooting, kasm logs, kasm container restart
- kasm no resources available, kasm container destruction error
- kasm base64 error, kasm session token error, kasm binascii
- kasm file manager not opening, kasm keyring error, kasm vs code
- kasm api, kasm api key, kasm get_images, kasm developer api
- kasm workspace configuration, kasm docker run config, kasm docker exec config
- kasm backblaze b2, kasm rclone, kasm s3 backup
- kasm service management, kasm start stop, kasm upgrade
- virtual workspace streaming, containerized desktop, cloud desktop

---

## What This Skill Covers

Complete KASM Workspaces management: installation, configuration, troubleshooting, backup/recovery, and API operations.

**Domains**:
- Installation and upgrades
- Workspace configuration (persistent profiles, volume mappings, Docker overrides)
- Troubleshooting (7+ production-tested playbooks)
- Backup and recovery (database, profiles, S3/B2 sync)
- Networking (Cloudflare Tunnel, reverse proxy, zone config)
- Database operations (common queries, maintenance)
- API reference (correct auth method and endpoints)
- Service management (start/stop, logs, health checks)

---

## Known Issues Prevented

| Issue | How Skill Prevents It |
|-------|-----------------------|
| Wrong API authentication method | Documents correct JSON payload auth (not HTTP Basic Auth) |
| Wrong API endpoint names | Maps UI terms to API terms (images not workspaces) |
| $68 Backblaze bill from missing @endpoint | Documents S3 path format with mandatory @endpoint |
| "No Resources Available" false positive | Provides 3-step diagnostic (resources, hostname, cache) |
| Container destruction zombie errors | Step-by-step cleanup procedure |
| VS Code keyring errors in containers | D-Bus + gnome-keyring Docker Exec Config fix |
| File permission issues after SFTP | Ownership fix commands |
| Session token corruption | Database cleanup queries |
| Swap not configured causing instability | Swap setup in installation steps |

---

## References

- KASM docs: https://kasmweb.com/docs/latest/
- KASM new docs: https://docs.kasm.com/
- KASM GitHub issues: https://github.com/kasmtech/workspaces-issues
- KASM Docker images: https://github.com/kasmtech

---

## License

MIT License
