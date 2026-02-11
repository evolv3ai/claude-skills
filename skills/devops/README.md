# Admin DevOps - Remote Infrastructure

Profile-aware remote infrastructure administration. Server inventory, cloud provisioning, and application deployment.

## Auto-Trigger Keywords

- server, servers, provision, deploy
- cloud, infrastructure, VPS, VM, instance
- inventory, my servers, server list
- OCI, oracle cloud, hetzner, digitalocean, vultr, linode, contabo
- coolify, kasm, self-hosted

## Commands

| Command | Description |
|---------|-------------|
| `/provision` | Provision a new server via cloud provider |
| `/deploy` | Deploy an application (Coolify, KASM) to server |
| `/server-status` | Show server inventory from profile |

## Agents

| Agent | Description |
|-------|-------------|
| `server-provisioner` | Autonomous multi-step cloud deployments |
| `deployment-coordinator` | Orchestrates infrastructure + app deployments |

## Quick Start

```bash
# Provision a new server
/provision hetzner

# Deploy Coolify to a server
/deploy coolify cool-two

# Check server inventory
/server-status --all
```

## Supported Providers

| Provider | Skill | Free Tier |
|----------|-------|-----------|
| OCI (Oracle Cloud) | oci | Yes (ARM64) |
| Hetzner | hetzner | No |
| Contabo | contabo | No |
| DigitalOcean | digital-ocean | No |
| Vultr | vultr | No |
| Linode | linode | No |

## Supported Applications

| Application | Skill | Purpose |
|-------------|-------|---------|
| Coolify | coolify | Self-hosted PaaS |
| KASM | kasm | Browser-based VDI |

## Server Inventory

Servers are stored in the device profile:

```json
{
  "servers": [
    {
      "id": "cool-two",
      "name": "COOL_TWO",
      "host": "123.45.67.89",
      "provider": "contabo",
      "role": "coolify",
      "status": "active"
    }
  ],
  "deployments": {
    "coolify-prod": {
      "type": "coolify",
      "serverId": "cool-two",
      "domain": "coolify.example.com"
    }
  }
}
```

## Related Skills

| Skill | Purpose |
|-------|---------|
| admin | Local machine administration |
| oci, hetzner, contabo, digital-ocean, vultr, linode | Cloud provider provisioning |
| coolify, kasm | Application deployment |

## NOT for

Local machine tasks, MCP servers, Windows/WSL admin → use `admin`
