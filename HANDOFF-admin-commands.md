# Handoff: Admin Plugin Commands Not Visible

**Date**: 2026-02-09
**Issue**: admin skill has 5 /commands but only /skill is visible on native Windows PC
**Status**: UNRESOLVED — keywords removal did not fix it

---

## Problem

- `admin-devops`: 3 commands, ALL visible (deploy, provision, server-status)
- `admin`: 5 commands, only `/skill` visible (install, mcp-manage, setup-profile, troubleshoot are hidden)
- Install pattern: hybrid (all bundle + individual plugins)
- Same issue on WSL machine: 0/5 admin commands visible, `all:admin` shows in system-reminder

## What Was Already Fixed (commit 604fca0)

1. Renamed `/mcp` → `/mcp-manage` (confirmed built-in Claude Code collision)
2. Removed `keywords:` from admin SKILL.md frontmatter
3. Emptied `keywords` array in admin plugin.json (to match admin-devops which works)

**Result: No change.** Same behavior on native Windows PC.

## What Was Investigated and Ruled Out

| Hypothesis | Result |
|-----------|--------|
| File encoding (BOM, CRLF) | Clean LF on all files, identical hex headers |
| YAML frontmatter format | Identical structure across all 8 command files |
| Command name collisions in repo | No duplicates — all 8 names unique |
| Built-in command conflicts | Only `/mcp` confirmed built-in; `/install`, `/setup-profile`, `/troubleshoot` are NOT built-in |
| plugin.json structure | Identical between admin and admin-devops |
| Missing files in cache | All 5 .md files present in `~/.claude/plugins/cache/evolv3ai-skills/admin/0.0.3/commands/` |
| Keywords in SKILL.md/plugin.json | Removed — no effect |

## Key Observations

### On WSL machine (this machine)
- `all:admin` appears in system-reminder skills list
- `all:admin-devops` does NOT appear (individual install takes precedence)
- admin-devops commands listed as `admin-devops:server-status`, etc.
- ZERO admin commands listed anywhere
- Both plugins installed individually AND via `all` bundle

### On native Windows PC
- admin-devops: 3/3 commands visible
- admin: only `/skill` visible (4 hidden)
- Slightly different from WSL (1/5 vs 0/5)

### Structural comparison (current state after fixes)

**admin plugin.json:**
```json
{
  "name": "admin",
  "keywords": [],
  "commands": "./commands/"
}
```

**admin-devops plugin.json:**
```json
{
  "name": "admin-devops",
  "keywords": [],
  "commands": "./commands/"
}
```

These are now structurally identical. Yet admin-devops works and admin doesn't.

## Remaining Differences Between admin and admin-devops

1. **SKILL.md size**: admin is ~209 lines, admin-devops is ~46 lines (much larger skill body)
2. **Number of commands**: admin has 5, admin-devops has 3
3. **Hook type**: admin uses `UserPromptSubmit` hook, admin-devops uses `PreToolUse` hook
4. **Files**: admin has 50+ files (scripts, references, templates), admin-devops has ~30
5. **`.env.template`**: admin has one at root, admin-devops doesn't
6. **`source: plugin`**: admin SKILL.md has this field, admin-devops doesn't (may be non-standard)

## Untested Theories

### Theory 1: `all` bundle conflict (strongest candidate)
The `all` bundle copies the entire repo including `skills/admin/.claude-plugin/plugin.json`. Even though Claude Code "doesn't recursively search nested directories," the `all:admin` skill registration may be overriding the individual admin plugin registration in a way that suppresses commands. This does NOT happen for admin-devops for unknown reasons.

**Test**: Uninstall `all` bundle entirely, keep only individual admin + admin-devops. See if commands appear.

### Theory 2: `source: plugin` in SKILL.md
Admin's SKILL.md has `source: plugin` in frontmatter. Admin-devops doesn't. This is not a standard Anthropic field and could confuse the parser.

**Test**: Remove `source: plugin` from admin's SKILL.md.

### Theory 3: Hook interference
Admin's `UserPromptSubmit` hook (profile-gate.sh) runs on EVERY prompt. If it errors on Windows (e.g., bash script on native Windows), it might interfere with plugin loading.

**Test**: Temporarily remove the hooks/ directory or hooks.json from admin.

### Theory 4: Plugin size/complexity
Admin has 50+ files vs admin-devops ~30. Could hit a size limit or timeout during plugin loading.

**Test**: Strip admin down to minimal (SKILL.md + plugin.json + commands/ only) and see if commands appear.

### Theory 5: Command count
Admin has 5 commands, admin-devops has 3. Could there be a per-plugin command limit?

**Test**: Temporarily remove 2 admin commands and see if the remaining 3 appear.

## Files Changed

- `skills/admin/commands/mcp.md` → renamed to `mcp-manage.md` (commit 604fca0)
- `skills/admin/SKILL.md` — keywords removed
- `skills/admin/.claude-plugin/plugin.json` — keywords emptied
- `skills/admin/README.md` — /mcp → /mcp-manage references
- `skills/admin/agents/profile-validator.md` — /mcp → /mcp-manage reference

## Quick Reference: Plugin Cache Paths

```
~/.claude/plugins/cache/evolv3ai-skills/all/VERSION/         # all bundle (full repo)
~/.claude/plugins/cache/evolv3ai-skills/admin/0.0.3/         # individual admin
~/.claude/plugins/cache/evolv3ai-skills/admin-devops/0.0.3/  # individual admin-devops
~/.claude/plugins/installed_plugins.json                       # what's actually installed
```

## Recommended Next Steps

1. **Try uninstalling `all` bundle** — most likely to reveal if it's the root cause
2. **Try removing `source: plugin`** from admin SKILL.md
3. **Try removing hooks** from admin temporarily
4. **Try minimal admin** — strip to just SKILL.md + plugin.json + commands/
5. **Check `/help` output on Windows** — see exactly which commands Claude Code sees
