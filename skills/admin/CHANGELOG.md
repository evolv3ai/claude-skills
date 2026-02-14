# Admin Skill Changelog

All notable changes to the Admin skill are documented here.

Format: [Semantic Versioning](https://semver.org/)
- **MAJOR**: Breaking changes to profile schema or CLI interface
- **MINOR**: New features, backward-compatible
- **PATCH**: Bug fixes, documentation

---

## [0.0.4] - 2026-02-14

### Added
- `skillVersions` object in profile schema - tracks all 10 admin suite skill versions
  - admin, devops, oci, hetzner, contabo, digital-ocean, vultr, linode, coolify, kasm
- Profile creators (`new-admin-profile.sh`, `New-AdminProfile.ps1`) read sibling VERSION files
- Version checkers (`get-admin-version.sh`, `Get-AdminVersion.ps1`) show suite-wide comparison table
  - Green = profile matches current VERSION, yellow + arrow = drift detected
- `adminSkillVersion` and `multiDevice` added to `profile-schema.json` (were in template but missing from schema)
- `rules/admin.md` - Cross-platform CLI correction rules (ISSUE-0007/0008/0009/0010)
  - curl JSON escape on Windows → use .ps1 + ConvertTo-Json
  - MCP HTTP session init protocol → 2-step flow with Mcp-Session-Id
  - PowerShell inline in Bash tool → write .ps1 file, run pwsh -File
  - `del` not found in Bash → use `rm`
  - Log-AdminEvent hallucinated parameter correction

### Verified
- `/install` pipeline tested end-to-end (profile gate → SimpleMem recall → tool-installer → verify-agent → SimpleMem store → logging)

## [0.0.3] - 2026-02-13

### Added
- SimpleMem MCP integration across all agents (graceful degradation)
- `memory_query` recall in `/install` and `/mcp-manage` commands
- `memory_add` store after pipeline completion
- Speaker convention: `admin:tool-installer`, `admin:verify-agent`, etc.

### Fixed
- ISSUE-0005: MCP config path corrected to `~/.claude.json`
- ISSUE-0006: REST API `/api/*` documented as cloud-only

## [0.0.2] - 2026-02-02

### Added
- Alpha consolidation into `admin` (local) + `admin-devops` (remote)
- Shared profile gate reference (`references/profile-gate.md`) synced to admin-devops
- Consolidated references for Windows, WSL, Unix, MCP, and Skills registry
- Consolidation verification script (`scripts/verify-consolidation.sh`)
- Shared asset sync script (`scripts/sync-shared-assets.sh`)

### Changed
- Updated README keywords and task routing to reflect the two-skill model
- Version reset to alpha `0.0.2`

## [1.0.2] - 2026-02-02

### Fixed
- **Profile gate enforcement across all admin-* skills**: Updated admin, admin-windows, admin-wsl, admin-mcp, admin-unix with stronger enforcement language
- Changed profile gate from "MANDATORY FIRST" to "⚠️ MANDATORY - DO THIS FIRST" with explicit STOP instruction
- Updated all skills to use helper scripts instead of inline code
- Added logging requirements to admin-windows skill

### Changed
- All admin-* skills now use `Test-AdminProfile.ps1` / `test-admin-profile.sh` for profile checks
- Simplified profile gate code examples to use helper scripts
- Added "After ANY Operation" logging requirement to admin-windows

---

## [1.0.1] - 2026-02-02

### Fixed
- **Profile detection quoting bug**: Inline PowerShell commands from bash failed due to single-quote string literals preventing `$env:COMPUTERNAME` expansion
- Added `Test-AdminProfile.ps1` and `test-admin-profile.sh` helper scripts for reliable profile detection
- Updated SKILL.md with quoting warning and recommendation to use helper scripts

### Added
- `Test-AdminProfile.ps1` / `test-admin-profile.sh` - Reliable profile existence check (returns JSON)
- Complete scripts table in SKILL.md documenting all helper scripts

---

## [1.0.0] - 2026-02-02

### Added

**Phase 1: Core Loop**
- `Log-AdminEvent.ps1` / `log-admin-event.sh` - Shared logging helpers
- `New-AdminIssue.ps1` / `new-admin-issue.sh` - Issue file creation
- `Update-AdminIssue.ps1` / `update-admin-issue.sh` - Issue updates and resolution
- `Show-AdminSessionStart.ps1` / `show-admin-session-start.sh` - Session start summary
- `templates/issue-template.md` - Issue file template with YAML frontmatter
- Log format: `[ISO8601] [DEVICE] [PLATFORM] [LEVEL] Message`
- Issue categories: troubleshoot, install, devenv, mcp, skills, devops

**Phase 2: Onboarding**
- Multi-device question in setup interview (single vs cloud-synced)
- Baseline directories: profiles/, logs/, issues/, registries/, config/, backups/, scripts/, inbox/
- Optional inventory scan detecting package managers and tools
- Platform-aware defaults (Windows/macOS/Linux/WSL)
- `multiDevice` flag in profile schema

**Phase 3: Module Integration**
- Wired logging into `admin-mcp` install/remove scripts
- Wired logging into `admin-skills` registry update script
- Created `admin-devops/templates/devops-registry.json`
- All modules now create issues on failure

**Phase 4: Passive Context**
- `templates/AGENTS.md` - Always-available context for agents
- `Update-AgentsMd.ps1` / `update-agents-md.sh` - Regenerate AGENTS.md
- Setup interview copies AGENTS.md to ADMIN_ROOT

**Versioning**
- `VERSION` file with semantic version
- `CHANGELOG.md` (this file)
- `adminSkillVersion` field in profile schema
- `Get-AdminVersion.ps1` / `get-admin-version.sh` - Version info and migration hints

### Schema

Profile schema version: `3.0`

New fields added:
- `multiDevice` (boolean)
- `adminSkillVersion` (string)
- `paths.issuesDir`
- `paths.registries`
- `paths.config`
- `paths.backups`
- `paths.scripts`
- `paths.inbox`
- `paths.devopsRegistry`

---

## [0.x.x] - Pre-release

Historical development before formal versioning. See git history for details.

---

## Migration Notes

### From pre-1.0.0 profiles

If your profile doesn't have `adminSkillVersion`:

1. Run `Get-AdminVersion.ps1` or `get-admin-version.sh` to check status
2. Re-run setup interview to update profile structure
3. Or manually add missing fields:
   ```json
   {
     "adminSkillVersion": "1.0.0",
     "multiDevice": false,
     "paths": {
       "issuesDir": "...",
       "registries": "...",
       "config": "...",
       "backups": "...",
       "scripts": "...",
       "inbox": "..."
     }
   }
   ```

### Directory creation

If directories are missing, create them:
```bash
mkdir -p $ADMIN_ROOT/{issues,config,backups,scripts,inbox}
```
