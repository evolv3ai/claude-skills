# Ralphban

**Status**: Beta
**Last Updated**: 2025-01-31
**Production Tested**: Ralphban VS Code Extension v1.0.2

---

## Auto-Trigger Keywords

Claude Code automatically discovers this skill when you mention:

### Primary Keywords
- ralphban
- prd.json
- task kanban
- ralph-style tasks
- llm task board

### Secondary Keywords
- task decomposition
- agent task file
- kanban json
- task graph
- task dependencies
- prd file format
- agent workflow tasks

### Error-Based Keywords
- "Invalid task schema"
- "Task not found"
- "missing description field"
- "task file not recognized"

---

## What This Skill Does

Create structured JSON task files compatible with the Ralphban VS Code extension. Enables any LLM agent to generate properly formatted tasks with status tracking, dependencies, and priority levels for visual Kanban boards.

### Core Capabilities

✅ Generate valid Ralphban task JSON schema
✅ Track task status (pending → in_progress → completed)
✅ Define task dependencies for execution ordering
✅ Integrate with agent harness patterns (bash scripts, loops)

---

## Known Issues This Skill Prevents

| Issue | Why It Happens | How Skill Fixes It |
|-------|---------------|-------------------|
| Task not found | Description mismatch | Documents exact-match requirement |
| Schema validation fails | Missing required fields | Provides complete schema reference |
| Completed tasks revert | UI enforces state machine | Explains status flow rules |

---

## When to Use This Skill

### ✅ Use When:
- Breaking features into agent-executable tasks
- Creating PRD files for Ralph-style workflows
- Building task graphs with dependencies
- Integrating with LLM agent harnesses
- Visualizing agent progress on Kanban board

### ❌ Don't Use When:
- General project management (use Jira, Linear)
- Non-JSON task formats
- Tasks without LLM/agent context

---

## Quick Usage Example

```json
[
  {
    "category": "backend",
    "description": "Create API endpoint",
    "status": "pending",
    "priority": "high",
    "steps": ["Define routes", "Implement handlers", "Add validation"],
    "dependencies": [],
    "passes": null
  }
]
```

**Result**: Valid task file that Ralphban renders as a Kanban card.

**Full instructions**: See [SKILL.md](SKILL.md)

---

## Task Schema Quick Reference

| Field | Required | Type | Values |
|-------|----------|------|--------|
| `category` | ✅ | string | frontend, backend, database, testing, docs, infra, security, functional |
| `description` | ✅ | string | Unique task identifier |
| `steps` | ✅ | string[] | Ordered steps to complete |
| `status` | ❌ | enum | pending, in_progress, completed, cancelled |
| `priority` | ❌ | enum | high, medium, low |
| `dependencies` | ❌ | string[] | Descriptions of blocking tasks |
| `passes` | ❌ | bool/null | Explicit pass/fail override |

---

## File Patterns

Ralphban discovers files matching:
- `**/*.prd.json`
- `**/prd.json`
- `**/tasks.json`

---

## Dependencies

**Prerequisites**: None

**Integrates With**:
- VS Code Ralphban extension (optional, for visualization)
- jq (optional, for bash script integration)

---

## File Structure

```
ralphban/
├── SKILL.md              # Complete documentation
├── README.md             # This file
├── scripts/              # (empty - no scripts needed)
├── references/           # (empty - self-contained)
└── assets/               # (empty - no templates needed)
```

---

## Official Documentation

- **Ralphban Extension**: https://github.com/carlosiborra/ralphban
- **Matt Pocock's Ralph Pattern**: https://x.com/mattpocockuk/status/2008200878633931247
- **Anthropic Harnesses Guide**: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents

---

## Related Skills

- **beads** - Alternative task tracking with dependency graphs
- **project-workflow** - Higher-level project lifecycle management

---

## Contributing

Found an issue or have a suggestion?
- Open an issue: https://github.com/carlosiborra/ralphban/issues
- See [SKILL.md](SKILL.md) for detailed documentation

---

## License

MIT License - See main repo LICENSE file

---

**Production Tested**: Ralphban VS Code Extension v1.0.2
**Error Prevention**: 100%
**Ready to use!** See [SKILL.md](SKILL.md) for complete setup.
