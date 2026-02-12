# Project Brief: Admin Vault - age-encrypted secrets for admin suite

**Created**: 2026-02-12
**Status**: Ready for Planning

---

## Vision

Add lightweight, git-safe secrets encryption to the admin skills suite using `age` encryption, replacing plaintext `.env` storage with an encrypted vault while preserving the existing satellite/profile architecture.

## Problem/Opportunity

The admin suite manages cloud provider API keys, MCP server credentials, and deployment secrets across multiple `.env` files - all stored as plaintext on disk. File permissions are the only protection. If `$ADMIN_ROOT` is synced (Dropbox, git), secrets travel in the clear. The existing architecture already separates "pointers" (satellite `.env`, profile JSON) from "values" (master `.env`, deployment `.env.local`) - encryption fits naturally at the values layer.

## Target Audience

- **Primary**: Admin skill users (solo devs managing cloud infrastructure)
- **Scale**: <100 secrets per vault, 1-3 devices
- **Context**: Production enhancement to existing admin skill

## Core Functionality (MVP)

1. **Encrypted vault file** (`$ADMIN_ROOT/vault.age`) - Single age-encrypted file replacing plaintext `$ADMIN_ROOT/.env`. Contains all cloud provider tokens, app credentials, and shared secrets. Git-safe, sync-safe.

2. **Cross-platform decrypt-on-load** - Modified `load-profile.sh` and `Load-Profile.ps1` decrypt vault to environment variables (memory only, never written to disk). Falls back to plaintext `.env` when vault disabled.

3. **CLI wrapper** (`secrets`) - Adapted from josh-stephens/secrets-management. Bash script for ad-hoc secret retrieval: `secrets HCLOUD_TOKEN`, `secrets --list`, `eval $(secrets -s)`.

4. **TypeScript decrypt utility** - Uses `age-encryption` npm package for admin TS scripts. Same key file (`~/.age/key.txt`), interoperable with CLI.

5. **Migration tooling** - Script to encrypt existing `.env` into `vault.age`, verify round-trip, and optionally delete plaintext.

6. **Feature flag** - `ADMIN_VAULT=enabled` in satellite `~/.admin/.env` (4th var). When disabled, existing plaintext behavior preserved.

**Out of Scope for MVP** (defer to Phase 2):
- Per-deployment vault encryption (individual `.env.local` files) - start with master vault only
- MCP registry env var migration (store `vault:KEY_NAME` refs instead of plaintext) - requires registry schema change
- Multi-device key sharing (manual `~/.age/key.txt` copy for now)
- Rotation/expiry policies
- Team/multi-identity encryption (age supports multiple recipients, defer)

## Tech Stack (Validated)

- **Encryption**: [age](https://age-encryption.org/) - modern, audited, by FiloSottile (Go core, official TS port)
- **CLI tool**: `age` binary (apt/brew/scoop install)
- **TypeScript**: [`age-encryption`](https://www.npmjs.com/package/age-encryption) npm package (v0.2.4+, Node.js 20+, pure TS, noble crypto)
- **Key storage**: `~/.age/key.txt` (standard age location, never committed)
- **Vault storage**: `$ADMIN_ROOT/vault.age` (age-encrypted, ASCII-armored for text-safe sync)

**Key Dependencies**:
- **age CLI**: Required for bash/PowerShell decrypt. Install: `sudo apt install age` / `brew install age` / `scoop install age`
- **age-encryption npm**: Required for TypeScript scripts. Install: `npm install age-encryption`
- **Interoperability**: Same key format works across CLI and TS library (X25519 keys)

## Research Findings

### Similar Solutions Reviewed

- **josh-stephens/secrets-management**: Direct inspiration. Bash CLI wrapper around age, single vault at `~/.ssh/secrets/`, key at `~/.age/key.txt`. Simple and effective. We adapt the `secrets` script to work with `$ADMIN_ROOT/vault.age` instead of `~/.ssh/secrets/`.
- **Infisical**: Full secrets management platform. Docker-based, ~2.5GB infrastructure, web UI, audit logs. Massive overkill for solo/small-team admin use. The repo we're referencing was created specifically to migrate away from Infisical.
- **SOPS + age**: Mozilla SOPS can use age as backend. Adds structured encryption (encrypt values but not keys in YAML/JSON). Overkill for `.env` files but worth noting for future MCP registry integration.
- **1Password CLI / Bitwarden CLI**: External secret stores with CLI access. Adds vendor dependency and network requirement. Not suitable for offline/air-gapped admin work.

### Technical Validation

- **age-encryption npm**: Official implementation by age creator (FiloSottile/typage). Pure TypeScript, noble crypto libs only. ES2023, Node.js 20+. Generates keys compatible with age CLI. API is clean: `Encrypter.encrypt()` / `Decrypter.decrypt()`.
- **ASCII armor**: age supports PEM-based text encoding (`age.armor.encode/decode`). This makes vault.age a text file safe for git diff, sync tools, and text editors.
- **Cross-platform age CLI**: Available on all platforms (apt, brew, scoop, choco). Same binary, same key format. PowerShell can call `age --decrypt` via `Start-Process` or direct execution.
- **Key compatibility**: `~/.age/key.txt` format is `AGE-SECRET-KEY-1...` (Bech32). Both CLI and npm package read/write this format.

### Known Challenges

- **PowerShell + age CLI**: PowerShell needs `age --decrypt -i $keyPath $vaultPath` piped to string parsing. No native PowerShell age module exists - must shell out to CLI binary. Works fine, just not "native PS".
- **WSL path translation**: Vault at `$ADMIN_ROOT/vault.age` where `ADMIN_ROOT` may be `/mnt/c/Users/...`. Existing `load-profile.sh` already handles this (lines 169-173). Same pattern applies to vault path.
- **First-run experience**: Need age CLI installed + key generated before vault works. Migration script should handle this. Feature flag ensures graceful degradation.
- **Satellite .env grows from 3 to 4 vars**: Adding `ADMIN_VAULT=enabled`. Minimal impact but profile schema needs update.

## Integration Architecture

```
~/.admin/.env (satellite - 4 vars, no secrets)
  ADMIN_ROOT=/mnt/c/Users/Owner/.admin
  ADMIN_DEVICE=WOPR3
  ADMIN_PLATFORM=wsl
  ADMIN_VAULT=enabled          # NEW - feature flag

~/.age/key.txt (age private key - never committed/synced)
  AGE-SECRET-KEY-1QFWZ...

$ADMIN_ROOT/
  vault.age                    # NEW - encrypted vault (replaces .env)
  .env                         # KEPT - plaintext fallback (migration/disabled mode)
  profiles/WOPR3.json          # UNCHANGED - no secrets, path refs only
  registries/mcp-registry.json # UNCHANGED for MVP (Phase 2: vault refs)
```

### Load Flow (vault enabled)

```
load-profile.sh
  1. Read ~/.admin/.env → get ADMIN_ROOT, ADMIN_VAULT
  2. if ADMIN_VAULT=enabled AND vault.age exists:
       age --decrypt -i ~/.age/key.txt $ADMIN_ROOT/vault.age | load_env_file /dev/stdin
     else:
       load_env_file $ADMIN_ROOT/.env   # existing behavior
  3. Continue with profile load (unchanged)
```

### Load Flow (PowerShell)

```
Load-Profile.ps1
  1. Read satellite .env → get ADMIN_ROOT, ADMIN_VAULT
  2. if ADMIN_VAULT=enabled AND vault.age exists:
       $plaintext = age --decrypt -i ~/.age/key.txt $ADMIN_ROOT/vault.age
       Parse $plaintext as .env format → export vars
     else:
       Load-EnvFile $ADMIN_ROOT/.env   # existing behavior
  3. Continue with profile load (unchanged)
```

### TypeScript Usage

```typescript
import { decryptVault } from './admin-vault'

const secrets = await decryptVault()  // reads key + vault, returns Map<string, string>
const token = secrets.get('HCLOUD_TOKEN')
```

## Scope Validation

**Why Build This?**: No existing solution fits the admin architecture. Josh's approach is the closest match but needs adaptation for the satellite `.env` / `$ADMIN_ROOT` pattern. Building a thin integration layer (~200 lines across bash/PS/TS) is less overhead than adopting any external secrets manager.

**Why This Approach?**: age is the gold standard for simple file encryption - audited, maintained by a renowned cryptographer, has an official TypeScript port. The vault pattern (single encrypted file) matches Josh's proven approach. Feature flag ensures zero risk during migration.

**What Could Go Wrong?**:
1. **Lost age key** - No vault access. Mitigation: Document key backup in setup flow. Key is small enough to print/store physically.
2. **age CLI not installed** - Vault decrypt fails. Mitigation: Feature flag falls back to plaintext. `check_dependencies()` in load-profile.sh already has this pattern (line 98-104 for jq).
3. **Stale plaintext .env after migration** - User forgets to delete. Mitigation: Migration script warns, verification step compares vault contents against original.

## Estimated Effort

- **MVP**: ~4-6 hours with Claude Code
- **Breakdown**:
  - Bash `secrets` CLI wrapper + `load-profile.sh` integration: ~1.5h
  - PowerShell `Load-Profile.ps1` vault integration: ~1h
  - TypeScript `admin-vault.ts` utility module: ~1h
  - Migration script (encrypt existing .env → vault.age): ~0.5h
  - Profile schema update (ADMIN_VAULT flag): ~0.5h
  - Documentation + SKILL.md updates: ~0.5h

## Success Criteria (MVP)

- [ ] `age --decrypt` successfully decrypts `vault.age` to original `.env` contents
- [ ] `source load-profile.sh` exports same vars from vault as from plaintext `.env`
- [ ] `Load-Profile.ps1 -Export` exports same vars from vault (PowerShell)
- [ ] `secrets HCLOUD_TOKEN` returns correct value
- [ ] `eval $(secrets -s)` loads all vars to shell
- [ ] TypeScript `decryptVault()` returns correct Map
- [ ] Feature flag `ADMIN_VAULT=disabled` preserves existing plaintext behavior
- [ ] Migration script round-trips `.env` → `vault.age` → decrypted output with zero diff
- [ ] `vault.age` is ASCII-armored and git-diffable (header changes visible)

## File Changes

### New Files
- `skills/admin/scripts/secrets` - Bash CLI wrapper (adapted from josh-stephens)
- `skills/admin/scripts/secrets.ps1` - PowerShell equivalent
- `skills/admin/scripts/admin-vault.ts` - TypeScript decrypt utility
- `skills/admin/scripts/migrate-to-vault.sh` - Migration script
- `skills/admin/scripts/migrate-to-vault.ps1` - PowerShell migration
- `skills/admin/references/vault-guide.md` - User documentation

### Modified Files
- `skills/admin/scripts/load-profile.sh` - Add vault decrypt before env load
- `skills/admin/scripts/Load-Profile.ps1` - Add vault decrypt before env load
- `skills/admin/.env.template` - Add ADMIN_VAULT variable
- `skills/admin/assets/profile-schema.json` - Add vault config section
- `skills/admin/SKILL.md` - Document vault feature

## Next Steps

**If proceeding**:
1. Run `/plan-project` to generate IMPLEMENTATION_PHASES.md
2. Review phases and adjust
3. Start Phase 1 (install age, generate key, build secrets wrapper)

**Phase 2 ideas** (post-MVP):
- Per-deployment `.env.local` encryption
- MCP registry `vault:KEY_NAME` references (encrypted env vars)
- Multi-recipient encryption (share vault across devices)
- `/secrets` admin command for Claude Code TUI
- SOPS integration for structured file encryption (JSON/YAML)

---

**Research References**:
- [josh-stephens/secrets-management](https://github.com/josh-stephens/secrets-management) - Direct inspiration, bash CLI wrapper
- [FiloSottile/typage](https://github.com/FiloSottile/typage) - Official TypeScript age implementation
- [age-encryption npm](https://www.npmjs.com/package/age-encryption) - v0.2.4+, Node.js 20+
- [age-encryption.org](https://age-encryption.org/) - age specification and docs
- [FiloSottile/age](https://github.com/FiloSottile/age) - Reference Go implementation
