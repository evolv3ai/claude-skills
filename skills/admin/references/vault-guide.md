# Admin Vault Guide

Lightweight, git-safe secrets management using [age encryption](https://age-encryption.org/) integrated with the admin suite's satellite `.env` / profile architecture.

## Quick Start

### 1. Install age

```bash
# Linux/WSL
sudo apt install age

# macOS
brew install age

# Windows
scoop install age
# or: choco install age
```

### 2. Generate key

```bash
mkdir -p ~/.age
age-keygen -o ~/.age/key.txt
chmod 600 ~/.age/key.txt
```

Save the public key shown (starts with `age1...`). Back up `~/.age/key.txt` somewhere safe.

### 3. Migrate existing .env

```bash
# Run migration script
./skills/admin/scripts/migrate-to-vault.sh

# Or manually:
PUBLIC_KEY=$(age-keygen -y ~/.age/key.txt)
age -e -r "$PUBLIC_KEY" -a -o $ADMIN_ROOT/vault.age $ADMIN_ROOT/.env
```

### 4. Enable vault

Add to `~/.admin/.env`:
```
ADMIN_VAULT=enabled
```

### 5. Test

```bash
secrets --status           # Check everything is wired up
secrets --list             # See all keys
secrets HCLOUD_TOKEN       # Get a single value
eval $(secrets -s)         # Load all to shell
```

## Daily Usage

### Retrieve secrets

```bash
# Single value
secrets HCLOUD_TOKEN
HCLOUD_TOKEN=$(secrets HCLOUD_TOKEN)

# All values as env vars
eval $(secrets -s)

# List keys
secrets --list

# View all (for debugging)
secrets --decrypt
```

### Edit vault

```bash
# Opens vault in $EDITOR, re-encrypts on save
secrets --edit
```

### Add new secret

```bash
secrets --edit
# Add: NEW_API_KEY=abc123
# Save and close editor
```

### Encrypt from scratch

```bash
# Write secrets to a temp file
cat > /tmp/new-secrets.env << 'EOF'
HCLOUD_TOKEN=your-token
OCI_TENANCY_OCID=your-ocid
EOF

# Encrypt to vault
secrets --encrypt /tmp/new-secrets.env

# Delete plaintext
rm /tmp/new-secrets.env
```

## Integration with admin scripts

### Bash (load-profile.sh)

```bash
source load-profile.sh

# If ADMIN_VAULT=enabled in ~/.admin/.env:
#   → Decrypts vault, exports vars to environment
# If ADMIN_VAULT=disabled or not set:
#   → Loads plaintext $ADMIN_ROOT/.env (existing behavior)

# Explicit call:
load_admin_secrets
```

### PowerShell (Load-Profile.ps1)

```powershell
. .\Load-Profile.ps1
Load-AdminProfile -Export    # Includes vault decryption

# Explicit call:
$secrets = Load-AdminSecrets -ExportToEnvironment
$secrets['HCLOUD_TOKEN']

# Or use secrets.ps1 directly:
$token = .\secrets.ps1 HCLOUD_TOKEN
.\secrets.ps1 -Source | Invoke-Expression   # Load all to $env:
```

### TypeScript (admin-vault.ts)

```typescript
import { decryptVault, getSecret, listSecrets, exportSecrets } from './admin-vault'

// Get all secrets
const secrets = await decryptVault()   // Map<string, string>
const token = secrets.get('HCLOUD_TOKEN')

// Convenience functions
const token = await getSecret('HCLOUD_TOKEN')
const keys = await listSecrets()        // string[]
const count = await exportSecrets()     // exports to process.env, returns count
```

Requires: `npm install age-encryption`

## Architecture

```
~/.admin/.env (satellite - 4 vars, no secrets)
  ADMIN_ROOT=/mnt/c/Users/Owner/.admin
  ADMIN_DEVICE=WOPR3
  ADMIN_PLATFORM=wsl
  ADMIN_VAULT=enabled              ← Feature flag

~/.age/key.txt (private key - NEVER commit/sync)
  AGE-SECRET-KEY-1...

$ADMIN_ROOT/vault.age (encrypted - git-safe, sync-safe)
  -----BEGIN AGE ENCRYPTED FILE-----
  [base64 encrypted content]
  -----END AGE ENCRYPTED FILE-----

$ADMIN_ROOT/.env (plaintext fallback - used when vault disabled)
  HCLOUD_TOKEN=xxx
  OCI_TENANCY_OCID=xxx
  ...
```

## Feature Flag

The `ADMIN_VAULT` variable in `~/.admin/.env` controls behavior:

| Value | Behavior |
|-------|----------|
| `enabled` | Decrypt vault.age, export secrets to env |
| `disabled` | Load plaintext .env (original behavior) |
| not set | Same as disabled |

**Graceful degradation**: If vault is enabled but dependencies are missing (age CLI, key file, vault file), scripts warn and fall back to plaintext `.env`.

## Key Backup

The age private key at `~/.age/key.txt` is the single point of failure. If lost, the vault cannot be decrypted.

**Backup strategies**:
- Print the key (it's one line, ~74 characters)
- Store in a password manager (1Password, Bitwarden)
- Copy to a USB drive stored securely
- Store encrypted copy in a different system

**Do NOT**:
- Commit `~/.age/key.txt` to git
- Sync via Dropbox/OneDrive (unless encrypted)
- Store alongside vault.age (defeats encryption)

## Multi-Device

To use the same vault on multiple devices:

1. Copy `~/.age/key.txt` to the other device (secure channel: USB, SSH, password manager)
2. Sync `$ADMIN_ROOT/vault.age` via git, Dropbox, or rsync
3. Set `ADMIN_VAULT=enabled` in the device's `~/.admin/.env`

The vault file is encrypted and safe to sync via any channel. Only the key must be transferred securely.

## Troubleshooting

### "Age key not found"
```bash
age-keygen -o ~/.age/key.txt
chmod 600 ~/.age/key.txt
```

### "Vault not found"
```bash
secrets --encrypt $ADMIN_ROOT/.env
# Or run: migrate-to-vault.sh
```

### "Decryption failed"
- Wrong key: `age-keygen -y ~/.age/key.txt` shows the public key. It must match the one used to encrypt.
- Corrupted vault: Re-encrypt from plaintext backup.

### "age not installed"
```bash
sudo apt install age    # Linux/WSL
brew install age        # macOS
scoop install age       # Windows
```

### Vault enabled but still loading plaintext
Check `~/.admin/.env` has `ADMIN_VAULT=enabled` (not `ADMIN_VAULT=true` or other values).

### PowerShell: "age is not recognized"
Add age to PATH or install via scoop/choco which auto-configures PATH.
