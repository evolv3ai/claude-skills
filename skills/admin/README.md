# Admin - Local Machine Companion

Profile-aware local machine administration for Windows, WSL, macOS, and Linux.

## Auto-Trigger Keywords

- install, installed, is installed, check if installed
- 7zip, 7-zip, git, node, python, docker, npm
- winget, scoop, brew, apt
- clone repo, add to PATH
- mcp server, dev environment
- windows, wsl, macos, linux

## Commands

| Command | Description |
|---------|-------------|
| `/setup-profile` | Create or reconfigure device profile via TUI interview |
| `/install` | Install tools, clone repos, run custom installers |
| `/troubleshoot` | Track and resolve issues using markdown files |
| `/mcp-bot` | Manage MCP servers (install, diagnose, list, remove) |
| `/skills-bot` | Manage Claude Code skills registry |

## Agents

| Agent | Description |
|-------|-------------|
| `profile-validator` | Validates profile completeness and consistency |
| `tool-installer` | Autonomous installation with preference awareness |
| `mcp-bot` | Diagnoses and manages MCP servers |
| `docs-agent` | Structured file I/O (profiles, issues, logs) |
| `verify-agent` | Dynamic system health verification |

## Quick Start

```bash
# Check if profile exists
/setup-profile

# Install a tool
/install git

# Troubleshoot an issue
/troubleshoot new

# Manage MCP servers
/mcp-bot diagnose
```

## Features

- **TUI-First**: Interactive interviews via AskUserQuestion, not shell prompts
- **Profile-Aware**: Adapts to your preferences (uv over pip, scoop over winget)
- **Cross-Platform**: Windows, WSL, macOS, Linux with platform detection
- **Issue Tracking**: Markdown-based issue files in `~/.admin/issues/`
- **Registries**: JSON registries for MCP servers and skills in `~/.admin/`

## Profile Structure

```
~/.admin/
├── profiles/{hostname}.json    # Device profile
├── mcp-registry.json           # MCP server inventory
├── skills-registry.json        # Skills inventory
├── issues/                     # Issue tracking
│   └── ISSUE-001-*.md
└── logs/
    └── operations.log
```

## Related Skills

| Skill | Purpose |
|-------|---------|
| devops | Remote server/cloud infrastructure |
| contabo | Contabo cloud provider provisioning |
| digital-ocean | DigitalOcean cloud provider provisioning |
| hetzner | Hetzner cloud provider provisioning |
| linode | Linode cloud provider provisioning |
| oci | Oracle Cloud Infrastructure provisioning |
| vultr | Vultr cloud provider provisioning |
| coolify | Coolify application deployment |
| kasm | KASM Workspaces deployment |

## NOT for

Remote servers, VPS, cloud infrastructure → use `devops`
