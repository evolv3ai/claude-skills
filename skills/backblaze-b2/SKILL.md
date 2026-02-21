---
name: backblaze-b2
description: |
  Manage cloud storage with Backblaze B2 CLI (v4.x). Upload, download, sync files and folders to B2 buckets. Create and manage buckets, application keys, and lifecycle rules.

  Use when: backing up files to B2, syncing directories to cloud storage, managing B2 buckets, creating application keys, or troubleshooting "unauthorized", "bad_auth_token", or "Bucket name is already in use" errors.
compatibility: claude-code-only
---

# Backblaze B2 CLI

Scaffold backup scripts, sync workflows, and bucket management using the B2 CLI v4.x.

## Install

```bash
uv tool install b2        # recommended
# or: pipx install b2

b2 version                # verify: expect 4.x
```

## Authorize

```bash
# Interactive
b2 account authorize

# Direct
b2 account authorize <applicationKeyId> <applicationKey>

# Environment variables (recommended for automation)
export B2_APPLICATION_KEY_ID="your-key-id"
export B2_APPLICATION_KEY="your-application-key"
```

Credentials at: Backblaze Console → App Keys → Create New Key

## Critical Rules

### Always

- Use `--dry-run` before any `--delete` sync
- Create **bucket-restricted** application keys for production (least privilege)
- Use `--keep-days N` instead of `--delete` when recovery matters
- Prefix bucket names with `org-project-env-` (they're globally unique)
- Set credentials via env vars for scripts, never hardcode

### Never

- Commit application keys to git
- Use `--delete` in sync without `--dry-run` first
- Share master application keys — create restricted keys instead
- Ignore empty source warnings (`--allow-empty-source` can wipe a bucket)

## B2 v4 CLI Syntax (Training Cutoff Correction)

B2 CLI v4 restructured all commands into subcommand groups. Claude's training data may reference the old flat syntax. Always use the v4 grouped form:

| Old (v3) | New (v4) |
|----------|----------|
| `b2 authorize-account` | `b2 account authorize` |
| `b2 create-bucket` | `b2 bucket create` |
| `b2 delete-bucket` | `b2 bucket delete` |
| `b2 list-buckets` | `b2 bucket list` |
| `b2 upload-file` | `b2 file upload` |
| `b2 download-file` | `b2 file download` |
| `b2 list-file-names` | `b2 ls` |
| `b2 create-key` | `b2 key create` |
| `b2 delete-key` | `b2 key delete` |

## Common Patterns

### Automated Backup Script

```bash
#!/bin/bash
BUCKET="my-backup-bucket"
SOURCE="/data/important"
DEST="b2://${BUCKET}/backups/$(date +%Y-%m-%d)"

b2 sync \
  --keep-days 30 \
  --exclude-regex '.*\.tmp$' \
  --exclude-regex '.*\.log$' \
  "$SOURCE" "$DEST"
```

### Bucket-Restricted Key

```bash
b2 key create app-readonly listFiles,readFiles --bucket my-app-bucket
# Save the output keyId + applicationKey securely
```

## Error Prevention

### "unauthorized" / "bad_auth_token"
Expired credentials or wrong key. Fix: `b2 account authorize` to refresh.

### "Bucket name is already in use"
B2 bucket names are globally unique across all accounts. Use unique prefixes.

### Permission denied on upload
Application key lacks `writeFiles` capability. Check with `b2 key list`.

### "command not found: b2"
Install path not in PATH. For uv: add `~/.local/bin` to PATH.

### "Account info file does not exist"
Run `b2 account authorize` first — no cached credentials yet.

## Setup Checklist

- [ ] B2 CLI installed (`b2 version` shows 4.x)
- [ ] Account authorized (`b2 account get` works)
- [ ] Bucket created or identified
- [ ] Application key created with minimal capabilities
- [ ] Environment variables set for automation
- [ ] First sync tested with `--dry-run`
