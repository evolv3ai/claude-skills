---
paths: "**/*.sh", "**/*.yml", "**/*.yaml", "**/Makefile", "**/*.env", "**/deploy*", "**/coolify*", "**/.github/**"
---

# Coolify CLI Corrections

Claude has limited training data for the Coolify CLI (released late 2025). Use these patterns when generating or reviewing Coolify CLI commands.

## Command Structure

The CLI follows: `coolify <resource> <action> [args] [flags]`

## Context Management

```bash
# Add self-hosted instance
coolify context add <name> <url> <token>

# Set cloud token
coolify context set-token cloud <token>

# Switch active context
coolify context use <name>

# Verify connection
coolify context verify

# Show instance version
coolify context version
```

## Application Commands

```bash
# Correct patterns
coolify app list
coolify app get <uuid>
coolify app start <uuid>
coolify app stop <uuid>
coolify app restart <uuid>
coolify app logs <uuid>
coolify app env list <uuid>
coolify app env create <uuid> --key KEY --value VALUE
coolify app env sync <uuid> --file .env

# WRONG - Claude may hallucinate these
# coolify apps list          -> use "app" not "apps"
# coolify application list   -> use "app" not "application"
# coolify app deploy <uuid>  -> deploy is top-level, not under app
```

## Deployment Commands

```bash
# Correct - deploy is a top-level command
coolify deploy uuid <uuid>
coolify deploy name <app-name>
coolify deploy batch <uuid1>,<uuid2>

# WRONG
# coolify app deploy <uuid>     -> deploy is top-level
# coolify deploy --app <name>   -> use "deploy name <name>"
# coolify deploy <uuid>         -> must specify "uuid" or "name" subcommand
```

## Database Commands

```bash
coolify database list
coolify database get <uuid>
coolify database create --server-uuid <uuid> --type postgres
coolify database start <uuid>
coolify database stop <uuid>
coolify database restart <uuid>

# Backup automation
coolify database backup list <db-uuid>
coolify database backup create <db-uuid> --frequency "daily" --enabled
coolify database backup trigger <backup-uuid>
coolify database backup executions <backup-uuid>
```

## Service Commands

```bash
coolify service list
coolify service get <uuid>
coolify service start <uuid>
coolify service stop <uuid>
coolify service restart <uuid>

# BUG: service env update returns 404 (issue #48)
# Workaround: delete + recreate
coolify service env delete <uuid> --key MY_KEY
coolify service env create <uuid> --key MY_KEY --value "new_value"
```

## Server Commands

```bash
coolify server list
coolify server get <uuid>
coolify server add --name web-1 --ip 192.168.1.100 --private-key-uuid <uuid> --user root
coolify server validate <uuid>
```

## Output Formats

```bash
# JSON output for scripting (pipe to jq)
coolify app list --format json | jq '.[].name'

# Table (default, human-readable)
coolify app list --format table

# Pretty-printed JSON
coolify app list --format pretty
```

## Environment Variable Sync Behavior

```bash
# CRITICAL: sync only creates/updates, does NOT delete
coolify app env sync <uuid> --file .env
# Variables in Coolify but NOT in .env are preserved (one-directional merge)
```

## Known Bugs to Avoid

| Command | Issue | Workaround |
|---------|-------|------------|
| `app env sync` with arrays | "cannot unmarshal array" | Use simple KEY=VALUE only |
| `service env update` | Returns 404 | Delete + recreate instead |
| Table output with wide content | Misaligned columns | Use `--format json` |

## Global Flags (Available on All Commands)

```
--context <name>       Use specific instance
--format <format>      Output: table|json|pretty
--token <token>        Override auth token
--host <url>           Override hostname
-s, --show-sensitive   Show secrets
-f, --force            Skip confirmations
--debug                Debug logging
```

## Config File Location

- Linux/macOS: `~/.config/coolify/config.json`
- Windows: `%USERPROFILE%\.config\coolify\config.json`
