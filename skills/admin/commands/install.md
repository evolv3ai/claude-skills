---
name: install
description: Install tools, clone repos, or run custom installers using profile preferences
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
argument-hint: "[tool-name | repo-url | script-path]"
---

# /install Command

Install software using the user's preferred package manager, clone repositories, or run custom installer scripts.

## Prerequisites

**MUST check profile exists first.** If no profile, run `/setup-profile` before proceeding.

## Workflow

### Step 1: Profile Gate

Load the profile to get user preferences:

**PowerShell:**
```powershell
$result = pwsh -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/Test-AdminProfile.ps1" | ConvertFrom-Json
if (-not $result.exists) {
    Write-Host "No profile found. Run /setup-profile first."
    exit 1
}
```

**Bash:**
```bash
result=$("${CLAUDE_PLUGIN_ROOT}/scripts/test-admin-profile.sh")
if [[ $(echo "$result" | jq -r '.exists') != "true" ]]; then
    echo "No profile found. Run /setup-profile first."
    exit 1
fi
```

### Step 2: Determine Install Type

If no argument provided, use TUI to ask:

Ask: "What would you like to install?"

| Option | Description |
|--------|-------------|
| Package/Tool | Install via package manager (winget, scoop, brew, apt) |
| Git Repository | Clone a repository |
| Custom Script | Run an installer script |

### Step 3A: Package Installation

If installing a package:

1. Check if already installed via profile's `tools` section
2. Get preferred package manager from profile
3. Construct install command:

| Manager | Install Command |
|---------|-----------------|
| winget | `winget install <package>` |
| scoop | `scoop install <package>` |
| choco | `choco install <package> -y` |
| brew | `brew install <package>` |
| apt | `sudo apt install -y <package>` |
| npm | `npm install -g <package>` |
| pip/uv | `uv pip install <package>` or `pip install <package>` |

4. Run the install command
5. Update profile with new tool info
6. Log the operation

### Step 3B: Repository Clone

If cloning a repo:

1. Ask for destination path (or use default `~/projects/`)
2. Detect if URL is GitHub/GitLab/etc.
3. Clone the repository:
   ```bash
   git clone <repo-url> <destination>
   ```
4. Ask if user wants to:
   - Install dependencies (`npm install`, `pip install -r requirements.txt`, etc.)
   - Open in editor
   - Run setup scripts
5. Log the operation

### Step 3C: Custom Script

If running a custom installer:

1. Validate script path exists
2. Ask for confirmation before running
3. Execute the script
4. Report results
5. Log the operation

### Step 4: Post-Install

After any installation:

1. Verify installation succeeded
2. Update profile's tools inventory
3. Log the operation using:
   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/scripts/log-admin-event.sh"
   log_admin_event "Installed <tool>" "OK"
   ```
4. Report success with usage tips

## TUI Questions

### Package Selection (if no argument)

Ask: "Which tool would you like to install?"

Common options:
- git, node, python, docker, rust, go
- 7zip, ripgrep, fd, fzf, jq
- Other (specify)

### Dependency Detection (for repos)

If `package.json` found, ask: "Install Node dependencies? (npm/pnpm/yarn/bun)"
If `requirements.txt` found, ask: "Install Python dependencies? (pip/uv)"
If `Cargo.toml` found, ask: "Build Rust project? (cargo build)"

## Error Handling

- Package not found: Suggest alternatives or correct package name
- Permission denied: Suggest running with elevated privileges
- Network error: Check connectivity, suggest retrying
- Already installed: Report current version, offer to update instead

## Examples

```
/install git
/install https://github.com/user/repo
/install ~/scripts/setup-dev.sh
/install  # (interactive mode)
```

## Logging

All installations are logged to `~/.admin/logs/operations.log` with:
- Timestamp
- Operation type
- Tool/repo name
- Success/failure status
- Package manager used
