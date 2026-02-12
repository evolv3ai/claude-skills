# Implementation Phases: Admin Vault

**Project**: Admin Vault - age-encrypted secrets for admin suite
**Total Phases**: 5
**Estimated Total**: ~5 hours
**Stack**: age CLI + age-encryption npm + Bash + PowerShell + TypeScript
**Brief**: `PROJECT_BRIEF.md`

---

## Phase 1: Foundation - age setup and secrets CLI wrapper (~1 hour)

**Type**: Feature | **Priority**: Critical
**Goal**: Install age, generate key, create the `secrets` bash CLI wrapper adapted from josh-stephens/secrets-management

### Tasks

1. **Verify age CLI availability**
   - Check if `age` and `age-keygen` are in PATH
   - If not installed, document install commands per platform (apt/brew/scoop)
   - Add `age` to admin profile schema as a tracked tool

2. **Create `secrets` bash CLI wrapper** (`skills/admin/scripts/secrets`)
   - Adapt from josh-stephens/secrets-management `secrets` script
   - Change vault path from `~/.ssh/secrets/` to `$ADMIN_ROOT/vault.age`
   - Read `ADMIN_ROOT` from satellite `~/.admin/.env`
   - Key location: `~/.age/key.txt` (standard)
   - Commands: `secrets KEYNAME`, `secrets --list`, `secrets --export`, `secrets -s`, `secrets --decrypt`, `secrets --encrypt FILE`, `secrets --help`
   - ASCII-armor output for text-safe vault file

3. **Create initial vault from .env.template**
   - Write a test plaintext credentials file
   - Encrypt with `age -r $(age-keygen -y ~/.age/key.txt) -a -o vault.age credentials.txt`
   - Verify round-trip: decrypt and diff against original
   - Delete plaintext test file

4. **Test CLI wrapper end-to-end**
   - `secrets --list` shows all keys
   - `secrets HCLOUD_TOKEN` returns single value
   - `eval $(secrets -s)` exports all vars
   - `secrets --decrypt` shows full plaintext

### Key Files
- `skills/admin/scripts/secrets` (new)
- `~/.age/key.txt` (generated)
- `$ADMIN_ROOT/vault.age` (new, encrypted)

### Dependencies
- `age` CLI installed
- `~/.admin/.env` satellite file exists

---

## Phase 2: Bash integration - load-profile.sh vault support (~1 hour)

**Type**: Feature | **Priority**: Critical
**Goal**: Modify `load-profile.sh` to decrypt vault when `ADMIN_VAULT=enabled`

### Tasks

1. **Add `ADMIN_VAULT` to satellite .env parsing**
   - In `resolve_admin_root()` area, add `resolve_vault_mode()` function
   - Reads `ADMIN_VAULT=enabled|disabled` from satellite `.env`
   - Default: `disabled` (backward compatible)

2. **Add `load_vault()` function**
   - Check `ADMIN_VAULT` flag
   - If enabled + `$ADMIN_ROOT/vault.age` exists + `age` in PATH + `~/.age/key.txt` exists:
     - `age --decrypt -i ~/.age/key.txt "$ADMIN_ROOT/vault.age"` piped to temp or process substitution
     - Feed decrypted output through existing `load_env_file` parser
   - If any prereq missing: warn and fall back to plaintext `.env`

3. **Add `check_vault_dependencies()` function**
   - Verify: `age` binary in PATH
   - Verify: `~/.age/key.txt` exists and readable
   - Verify: `$ADMIN_ROOT/vault.age` exists
   - Return specific error for each missing prereq

4. **Modify main load flow**
   - Before existing `load_env_file "$ADMIN_ROOT/.env"` calls, check vault mode
   - If vault enabled: call `load_vault()`
   - If vault disabled or failed: fall through to existing `load_env_file`
   - Log which mode was used: `[INFO] Loaded secrets from vault` or `[INFO] Loaded secrets from .env (plaintext)`

5. **Test both modes**
   - `ADMIN_VAULT=enabled`: verify vars loaded from vault
   - `ADMIN_VAULT=disabled`: verify existing behavior unchanged
   - Missing vault.age: verify graceful fallback with warning

### Key Files
- `skills/admin/scripts/load-profile.sh` (modified)
- `skills/admin/.env.template` (modified - add ADMIN_VAULT)

### Dependencies
- Phase 1 complete (secrets CLI + vault.age exist)

---

## Phase 3: PowerShell integration - Load-Profile.ps1 vault support (~1 hour)

**Type**: Feature | **Priority**: High
**Goal**: Mirror bash vault support in PowerShell for Windows-native workflows

### Tasks

1. **Add `Get-VaultMode` function**
   - Read `ADMIN_VAULT` from satellite `.env`
   - Return `$true` if enabled, `$false` otherwise

2. **Add `Test-VaultReady` function**
   - Check: `age` binary in PATH (Windows: `age.exe`)
   - Check: `~/.age/key.txt` exists (Windows path: `$HOME\.age\key.txt`)
   - Check: `$ADMIN_ROOT\vault.age` exists
   - Return detailed status object with which prereqs are met/missing

3. **Add `Load-Vault` function**
   - Call `age --decrypt -i $keyPath $vaultPath` via `& age` or `Start-Process`
   - Capture stdout as string
   - Parse string through existing `Load-EnvFile` logic (adapted for string input)
   - Return hashtable of key=value pairs

4. **Modify `Load-AdminProfile` function**
   - Before existing `Load-EnvFile` calls, check vault mode
   - If vault enabled + ready: call `Load-Vault`
   - If not: fall through to existing `Load-EnvFile`
   - Write-Log which mode was used

5. **Create `secrets.ps1` PowerShell wrapper**
   - PowerShell equivalent of bash `secrets` script
   - `.\secrets.ps1 KEYNAME`, `.\secrets.ps1 -List`, `.\secrets.ps1 -Export`
   - Uses same `~/.age/key.txt` and `$ADMIN_ROOT/vault.age`

### Key Files
- `skills/admin/scripts/Load-Profile.ps1` (modified)
- `skills/admin/scripts/secrets.ps1` (new)

### Dependencies
- Phase 1 complete (vault.age exists)

---

## Phase 4: TypeScript integration - admin-vault module (~1 hour)

**Type**: Feature | **Priority**: Medium
**Goal**: Create TypeScript utility using `age-encryption` npm package for programmatic vault access

### Tasks

1. **Create `admin-vault.ts` module** (`skills/admin/scripts/admin-vault.ts`)
   - Import `age-encryption` package
   - `decryptVault()` → reads key + vault, returns `Map<string, string>`
   - `getSecret(name: string)` → returns single secret value
   - `listSecrets()` → returns array of key names
   - Resolves `ADMIN_ROOT` from satellite `.env` (same logic as bash)
   - Key path: `~/.age/key.txt`

2. **Handle cross-platform paths**
   - WSL path translation for ADMIN_ROOT
   - Windows native paths for key file
   - Use `os.homedir()` + `path.join()` for portability

3. **Add .env parser**
   - Parse decrypted plaintext into key=value Map
   - Handle comments, blank lines, quoted values (match bash parser behavior)

4. **Add error handling**
   - Missing key file: throw with install instructions
   - Missing vault: throw with migration instructions
   - Decrypt failure: throw with "wrong key?" message
   - Missing age-encryption package: throw with `npm install` instructions

5. **Test module**
   - Verify `decryptVault()` returns same values as `secrets --export`
   - Verify `getSecret('HCLOUD_TOKEN')` matches `secrets HCLOUD_TOKEN`
   - Verify cross-platform path resolution

### Key Files
- `skills/admin/scripts/admin-vault.ts` (new)

### Dependencies
- Phase 1 complete (vault.age exists)
- `age-encryption` npm package installed

---

## Phase 5: Migration tooling and documentation (~1 hour)

**Type**: Enhancement | **Priority**: High
**Goal**: Scripts to migrate existing plaintext .env to vault, plus documentation

### Tasks

1. **Create `migrate-to-vault.sh`** (`skills/admin/scripts/migrate-to-vault.sh`)
   - Check prereqs: age installed, key exists (generate if not)
   - Read source: `$ADMIN_ROOT/.env` (or user-specified path)
   - Encrypt: `age -r $(age-keygen -y ~/.age/key.txt) -a -o $ADMIN_ROOT/vault.age $source`
   - Verify: decrypt vault and diff against original (must be identical)
   - Report: count of secrets migrated
   - Prompt: "Delete plaintext .env? (y/n)" - default no
   - Enable: set `ADMIN_VAULT=enabled` in satellite `.env`

2. **Create `migrate-to-vault.ps1`** (`skills/admin/scripts/migrate-to-vault.ps1`)
   - PowerShell equivalent of bash migration script
   - Same flow: check → encrypt → verify → report → prompt → enable

3. **Update `.env.template`**
   - Add `ADMIN_VAULT=` variable with documentation
   - Add `# VAULT` section header

4. **Update profile schema** (`skills/admin/assets/profile-schema.json`)
   - Add `vault` section to schema: `{ enabled: boolean, vaultPath: string, keyPath: string, migratedAt: string }`

5. **Create `vault-guide.md`** (`skills/admin/references/vault-guide.md`)
   - Setup: install age, generate key, first encryption
   - Daily use: `secrets` CLI commands, `eval $(secrets -s)`
   - Migration: step-by-step from plaintext to vault
   - Backup: how to back up `~/.age/key.txt` safely
   - Troubleshooting: common errors and fixes
   - Multi-device: how to share key across devices (manual copy, Tailscale, etc.)

6. **Update admin SKILL.md**
   - Add vault section to skill documentation
   - Document `ADMIN_VAULT` feature flag
   - Add vault-related error prevention entries

7. **Test full migration flow**
   - Start with plaintext `.env` at `$ADMIN_ROOT/.env`
   - Run migration script
   - Verify `source load-profile.sh` works with vault
   - Verify `Load-Profile.ps1 -Export` works with vault
   - Verify `secrets KEYNAME` works
   - Verify fallback: set `ADMIN_VAULT=disabled`, confirm plaintext mode

### Key Files
- `skills/admin/scripts/migrate-to-vault.sh` (new)
- `skills/admin/scripts/migrate-to-vault.ps1` (new)
- `skills/admin/.env.template` (modified)
- `skills/admin/assets/profile-schema.json` (modified)
- `skills/admin/references/vault-guide.md` (new)
- `skills/admin/SKILL.md` (modified)

### Dependencies
- Phases 1-4 complete

---

## Phase Summary

| Phase | Name | Type | Est. Hours | Dependencies |
|-------|------|------|-----------|-------------|
| 1 | Foundation - age + secrets CLI | Feature | 1.0 | None |
| 2 | Bash integration | Feature | 1.0 | Phase 1 |
| 3 | PowerShell integration | Feature | 1.0 | Phase 1 |
| 4 | TypeScript integration | Feature | 1.0 | Phase 1 |
| 5 | Migration + docs | Enhancement | 1.0 | Phases 1-4 |

**Note**: Phases 2, 3, and 4 can run in parallel after Phase 1.

---

## Post-MVP (Phase 2 Ideas)

- Per-deployment `.env.local` encryption
- MCP registry `vault:KEY_NAME` references
- Multi-recipient encryption (share vault across devices)
- `/secrets` admin command for Claude Code TUI
- SOPS integration for structured JSON/YAML encryption
- Key rotation tooling
