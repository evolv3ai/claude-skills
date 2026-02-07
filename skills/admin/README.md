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
| `/mcp` | Manage MCP servers (install, diagnose, list, remove) |
| `/skill` | Manage Claude Code skills registry |

## Agents

| Agent | Description |
|-------|-------------|
| `profile-validator` | Validates profile completeness and consistency |
| `tool-installer` | Autonomous installation with preference awareness |
| `mcp-troubleshooter` | Diagnoses MCP server issues |

## Quick Start

```bash
# Check if profile exists
/setup-profile

# Install a tool
/install git

# Troubleshoot an issue
/troubleshoot new

# Manage MCP servers
/mcp diagnose
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
| admin-devops | Remote server/cloud infrastructure |
| admin-infra-* | Cloud provider provisioning |
| admin-app-* | Application deployment (Coolify, KASM) |

## NOT for

Remote servers, VPS, cloud infrastructure → use `admin-devops`
