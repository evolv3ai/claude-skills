# Session State

**Project**: evolv3ai-skills - Claude Code skills repo
**Current Phase**: SimpleMem MCP integration (complete) + remaining learnings capture
**Current Stage**: Implementation
**Last Checkpoint**: 8e43fdc (2026-02-14)
**Planning Docs**: N/A (ad-hoc session)

---

## Completed This Session (2026-02-14)

### ISSUE-0005 Resolution: SimpleMem MCP Tools Not Appearing
Root cause chain (3 problems stacked):
1. **Wrong config file**: MCP servers go in `~/.claude.json` (under `mcpServers` key), NOT `~/.claude/.mcp.json`
2. **Plugin `.mcp.json` conflict**: Plugin-level config with `${ENV_VAR}` placeholders registered a broken server entry (`plugin:simplemem:simplemem`) that overrode working global config
3. **Missing `type` field**: User-level config needs `"type": "http"` explicitly

Fix applied:
- Removed plugin `skills/simplemem/.mcp.json` (broken env var approach)
- Added `mcpServers.simplemem` to `~/.claude.json` on both WSL and Windows
- Corrected all doc references from `~/.claude/.mcp.json` to `~/.claude.json`
- Verified: 7 MCP tools discovered on both platforms (`mcp__simplemem__memory_*`)

Commits: `9a7adb5` → `c622e6a` → `e16fc11`

### ISSUE-0006 Documentation
- REST API `/api/*` is cloud-only, documented in `rules/simplemem.md` and `references/mcp-setup.md`
- Self-hosted uses `/mcp` endpoint exclusively

### Additional Fixes
- Added `memory_delete` to tool table (server exposes 7 tools, not 6)
- Added `SIMPLEMEM_URL` and `SIMPLEMEM_TOKEN` to `~/.admin/.env`
- Added `.admin/.env` sourcing to `~/.zshrc`

## Open Issues

### Learnings to Capture as Rules (ISSUE-0007/0008/0009/0010)
- **ISSUE-0007**: curl JSON escape errors on Windows → use PowerShell script file with ConvertTo-Json
- **ISSUE-0008**: MCP HTTP requires session init before tool calls → document 2-step protocol
- **ISSUE-0009**: Complex PowerShell inline fails in Bash tool → write .ps1 file, run with `pwsh -File`
- **ISSUE-0010**: `del` command not found → use `rm` in Bash tool

Note: 0007/0009/0010 already captured in MEMORY.md cross-platform gotchas. Still need formal rules in admin skill.

## Next Actions

1. **Capture ISSUE-0007/0008/0009/0010 as correction rules** in `skills/admin/rules/` - create cross-platform CLI rules and MCP HTTP protocol rules

2. **Test `/install` pipeline end-to-end** - verify the admin install command works with SimpleMem memory recall/store

3. **memsearch evaluation**: Deferred to later (complementary to SimpleMem, wait for v0.2+)

---

## Previous Sessions

### SimpleMem Skill + Admin Integration (2026-02-13)
**Status**: COMPLETE | **Checkpoint**: 7ba8f5b
Created simplemem skill (knowledge-first hybrid approach), integrated SimpleMem MCP across 4 admin agents + 2 commands, renovated session-scout, fixed admin bugs (ISSUE-0002/0003/0004)

### Admin Vault Implementation (2026-02-12)
**Status**: COMPLETE | **Checkpoint**: 62b0647
Added age-encrypted vault, secrets CLI, migration scripts, vault-guide.md

### Admin Plugin Fixes + Agent Teams (2026-02-11)
**Status**: COMPLETE | **Checkpoint**: 1a25583

### Community Knowledge Research (2026-01-20)
**Status**: COMPLETE
