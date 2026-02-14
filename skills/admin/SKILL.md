---
name: admin
description: |
  Local machine administration for Windows, WSL, macOS, Linux. Install tools, check
  if software is installed, manage packages, configure dev environments. Works with
  winget, scoop, brew, apt, npm, pip, uv. Profile-aware: adapts to your preferences.

  Use when: install 7zip, is git installed, clone repo, check if node installed,
  add to PATH, configure MCP servers, manage dev tools, set up environment.

  NOT for: VPS, cloud servers, remote infrastructure → use devops skill.
license: MIT
source: plugin
---

# Admin - Local Machine Companion (Alpha)

**Script paths**: All paths below are relative to this skill's base directory.
Prepend the base directory shown above when running scripts (e.g., `{base}/scripts/test-admin-profile.sh`).

---

## 🛑 PROFILE GATE — MANDATORY FIRST STEP

**HALT. You MUST check for a profile before ANY operation. This is non-negotiable.**

### Step 1: Check Satellite .env

The fastest check is whether `~/.admin/.env` exists. This satellite file is created
during setup and contains 3 vars: `ADMIN_ROOT`, `ADMIN_DEVICE`, `ADMIN_PLATFORM`.

**Bash (WSL/Linux/macOS):**
```bash
scripts/test-admin-profile.sh
```

**PowerShell (Windows):**
```powershell
pwsh -NoProfile -File "scripts/Test-AdminProfile.ps1"
```

Returns JSON: `{"exists":true|false,"path":"...","device":"...","platform":"..."}`

### Step 2: If `exists: false` → HALT AND RUN SETUP

**DO NOT CONTINUE with the user's task. You must create a profile first.**

Use the TUI interview below to gather preferences, then call the setup script.

---

## 🎤 TUI Setup Interview (Agent-Driven)

When profile does not exist, ask these questions using your TUI capabilities (e.g., `AskUserQuestion`).

### Q1: Storage Location (Required)

Ask: **"Will you use Admin on a single device or multiple devices?"**

| Option | Description |
|--------|-------------|
| Single device (Recommended) | Local storage at `~/.admin`. Simple, no sync needed. |
| Multiple devices | Cloud-synced folder (Dropbox, OneDrive, NAS). Profiles shared across machines. |

If "Multiple devices" selected, follow up: **"Enter the path to your cloud-synced folder"**
- Examples: `C:\Users\You\Dropbox\.admin`, `~/Dropbox/.admin`, `N:\Shared\.admin`

### Q2: Tool Preferences (Optional)

Ask: **"Set tool preferences now, or use defaults?"**

If yes, ask each:
- **Package manager:** winget (default) / scoop / choco / brew / apt
- **Python manager:** uv (default) / pip / conda / poetry
- **Node manager:** npm (default) / pnpm / yarn / bun
- **Default shell:** pwsh (default) / powershell / bash / zsh

### Q3: Inventory Scan (Optional)

Ask: **"Run a quick inventory scan to detect installed tools?"**
- Yes: Scans for git, node, python, docker, ssh, etc. and records versions
- No: Creates minimal profile, tools detected on first use

---

## 🔧 Create Profile (After Interview)

Pass the user's answers to the setup script.

**PowerShell:**
```powershell
pwsh -NoProfile -File "scripts/New-AdminProfile.ps1" `
  -AdminRoot "C:/Users/You/.admin" `
  -PkgMgr "winget" `
  -PyMgr "uv" `
  -NodeMgr "npm" `
  -ShellDefault "pwsh" `
  -RunInventory
```

**Bash:**
```bash
scripts/new-admin-profile.sh \
  --admin-root "$HOME/.admin" \
  --pkg-mgr "brew" \
  --py-mgr "uv" \
  --node-mgr "npm" \
  --shell-default "zsh" \
  --run-inventory
```

Add `-MultiDevice` (PowerShell) or `--multi-device` (Bash) if user selected multi-device setup.

### After Profile Created

1. Verify: Re-run `Test-AdminProfile.ps1` or `test-admin-profile.sh` → should return `exists: true`
2. Load profile: See `references/profile-gate.md` for load commands
3. **Now** proceed with the user's original task

---

## CRITICAL: Secrets and .env

- NEVER store live `.env` files or credentials inside any skill folder.
- `.env.template` files belong only in `templates/` within a skill.
- Store live secrets in `~/.admin/.env` and reference from there.

## Vault: Encrypted Secrets (age)

Secrets can be encrypted at rest using [age encryption](https://age-encryption.org/). When `ADMIN_VAULT=enabled` in `~/.admin/.env`, `load-profile.sh` and `Load-Profile.ps1` decrypt `$ADMIN_ROOT/vault.age` instead of reading plaintext `.env`.

**Setup**: `age-keygen -o ~/.age/key.txt` then `secrets --encrypt $ADMIN_ROOT/.env`

**CLI (Bash)**: `secrets KEYNAME` | `secrets --list` | `eval $(secrets -s)` | `secrets --edit`

**CLI (PowerShell)**: `secrets.ps1 KEY` | `secrets.ps1 -List` | `secrets.ps1 -Source` | `secrets.ps1 -Status`

**Feature flag**: `ADMIN_VAULT=enabled|disabled` in satellite `~/.admin/.env`. Falls back to plaintext when disabled or deps missing.

**Cross-platform**: Bash (`scripts/secrets`), PowerShell (`scripts/secrets.ps1`), TypeScript (`scripts/admin-vault.ts` with `age-encryption` npm).

**Migration**: Run `scripts/migrate-to-vault.sh` (Linux/WSL) or `scripts/migrate-to-vault.ps1` (Windows).

**Guide**: `references/vault-guide.md`

## Task Qualification (MANDATORY)
- If the task involves **remote servers/VPS/cloud**, stop and hand off to **devops**.
- If the task is **local machine administration**, continue.
- If ambiguous, ask a clarifying question before proceeding.

## Task Routing

| Task | Reference |
|------|-----------|
| Install tool/package | references/{platform}.md |
| Windows administration | references/windows.md |
| WSL administration | references/wsl.md |
| macOS/Linux admin | references/unix.md |
| MCP server management | references/mcp.md |
| Skill registry | references/skills-registry.md |
| Memory integration | references/memory-integration.md |
| **Remote servers/cloud** | **→ Use devops skill** |

## Profile-Aware Adaptation (Always Check Preferences)

- Python: `preferences.python.manager` (uv/pip/conda/poetry)
- Node: `preferences.node.manager` (npm/pnpm/yarn/bun)
- Packages: `preferences.packages.manager` (scoop/winget/choco/brew/apt)

Never suggest install commands without checking preferences first.

## Package Installation Workflow (All Platforms)

1. Detect environment (Windows/WSL/Linux/macOS)
2. Load profile via profile gate
3. Check if tool already installed (`profile.tools`)
4. Use preferred package manager
5. Log the operation

## Logging (MANDATORY)

Log every operation with the shared helpers.

**Bash** — params: `MESSAGE` `LEVEL` (INFO|WARN|ERROR|OK):
```bash
source scripts/log-admin-event.sh
log_admin_event "Installed ripgrep" "OK"
```

**PowerShell** — params: `-Message` `-Level` (INFO|WARN|ERROR|OK):
```powershell
pwsh -NoProfile -File "scripts/Log-AdminEvent.ps1" -Message "Installed ripgrep" -Level OK
```

**Note**: There are no `-Tool`, `-Action`, `-Status`, or `-Details` parameters. Use `-Message` with a descriptive string.

## Scripts / References

- Core scripts: `scripts/` (profile, logging, issues, AGENTS.md)
- MCP scripts: `scripts/mcp-*`
- Skills registry scripts: `scripts/skills-*`
- References: `references/*.md`

---

## Quick Pointers

- Cross-platform guidance: `references/cross-platform.md`
- Shell detection: `references/shell-detection.md`
- Device profiles: `references/device-profiles.md`
- PowerShell tips: `references/powershell-commands.md`
