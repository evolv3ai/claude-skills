# Session State

**Project**: evolv3ai-skills - Claude Code skills repo
**Current Phase**: SimpleMem integration + admin bug fixes
**Current Stage**: Testing / Issue resolution
**Last Checkpoint**: 7ba8f5b (2026-02-13)
**Planning Docs**: N/A (ad-hoc session)

---

## What Was Built This Session

### 1. SimpleMem Skill (commit `19a5bd7`)
Created production skill for SimpleMem persistent LLM agent memory:
- `skills/simplemem/SKILL.md` - Knowledge-first hybrid approach, 295-char description
- `skills/simplemem/README.md` - Auto-trigger keywords
- `skills/simplemem/rules/simplemem.md` - 7 correction rules
- `skills/simplemem/references/` - 5 reference docs (architecture, mcp-setup, cross-session, cli-reference, api-reference)
- `skills/simplemem/templates/config.py.example` - Multi-provider config template

### 2. Admin SimpleMem Integration (commit `6d7589e`)
Integrated SimpleMem MCP with admin skill agents and commands:
- `skills/admin/references/memory-integration.md` - Architecture, patterns, privacy rules
- Updated 4 agents (docs-agent, verify-agent, tool-installer, mcp-bot) with SimpleMem sections
- Updated `/install` and `/troubleshoot` commands with memory recall/store steps
- Added SimpleMem to MCP reference (community servers, HTTP transport pattern)
- All memory operations use graceful degradation (skip silently when unavailable)

### 3. Session Scout Renovation (commit `082425c`, by user)
- Bundled `Session-Scout.ps1` into `scripts/` (was external at `D:\admin\scripts\`)
- Created cross-platform `session-scout.sh` Bash equivalent
- Updated SKILL.md and README.md for both platforms
- Removed scaffolding leftovers

### 4. Admin Bug Fixes (commit `7ba8f5b`)
Fixed 3 reported issues:
- **ISSUE-0002**: Replaced 25+ hardcoded `~/.claude/skills/admin/scripts/` paths with relative `scripts/` across SKILL.md + 5 reference files
- **ISSUE-0003**: Added PowerShell syntax (`-List`, `-Status`) alongside bash (`--list`, `--status`) in SKILL.md and vault-guide.md
- **ISSUE-0004**: Clarified Log-AdminEvent interface (only `-Message` + `-Level`, no `-Tool`/`-Action`/`-Details`)

## Open Issues (from testing)

### ISSUE-0005: SimpleMem MCP tools not deferred (PRIORITY)
SimpleMem configured in `~/.claude/.mcp.json` with `type: "http"` but its 6 tools don't appear in ToolSearch. May be a Claude Code limitation with HTTP transport MCP servers, or server not responding to discovery handshake. **This blocks native MCP integration.**

### ISSUE-0006: SimpleMem REST API 404
`POST /api/stats` returns 404 on self-hosted instance (`mem.self-host.io`). Self-hosted likely exposes MCP endpoint only (`/mcp`), not REST API (`/api/*`). **Fix**: Update simplemem skill docs to clarify REST is cloud-only.

### Resolved Issues (learnings to capture)
- **ISSUE-0007**: curl JSON escape errors on Windows → use PowerShell script file with ConvertTo-Json
- **ISSUE-0008**: MCP HTTP requires session init before tool calls → document 2-step protocol
- **ISSUE-0009**: Complex PowerShell inline fails in Bash tool → write .ps1 file, run with `pwsh -File`
- **ISSUE-0010**: `del` command not found → use `rm` in Bash tool

## Next Actions

1. **Investigate ISSUE-0005**: Why SimpleMem MCP tools aren't deferred. Check if `type: "http"` MCP servers are supported by Claude Code tool discovery. Test with `curl` to verify server responds to `tools/list` JSON-RPC.

2. **Fix simplemem skill for ISSUE-0006**: Update `references/mcp-setup.md` to clarify that `/api/*` REST endpoints are cloud-service only. Self-hosted uses MCP JSON-RPC exclusively at `/mcp`.

3. **Add learnings as rules**: Capture ISSUE-0007/0008/0009/0010 patterns into admin and simplemem rules.

4. **URL discrepancy**: User said `mem.self-host.ai` but actual config uses `mem.self-host.io`. The `.io` domain is correct (confirmed in working MCP config).

5. **memsearch evaluation**: Decided to keep as separate future skill (complementary to SimpleMem, not replacement). Build when it reaches v0.2+.

---

## Previous Sessions

### Admin Vault Implementation (2026-02-12)
**Status**: COMPLETE | **Checkpoint**: 62b0647
Added age-encrypted vault, secrets CLI, migration scripts, vault-guide.md

### Admin Plugin Fixes + Agent Teams (2026-02-11)
**Status**: COMPLETE | **Checkpoint**: 1a25583

### Community Knowledge Research (2026-01-20)
**Status**: COMPLETE
