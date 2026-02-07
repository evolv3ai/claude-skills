# Obsidian RLM - Large File Processor

**Status**: Beta
**Last Updated**: 2026-01-25
**Production Tested**: 64MB Claude export with ContentImporter workflow

---

## Auto-Trigger Keywords

Claude Code automatically discovers this skill when you mention:

### Primary Keywords
- obsidian rlm
- large file processing
- process large export
- 64MB conversations
- huge JSON file

### Integration Keywords
- ContentImporter large file
- conversation export too big
- file over 10MB
- bulk conversation analysis
- massive claude export

### Error-Based Keywords
- "out of memory processing JSON"
- "file too large to parse"
- "context window exceeded"
- "heap out of memory"

---

## What This Skill Does

Processes files too large for direct parsing (10MB+) using RLM iterative commands. Specifically designed for:

- **LLM Conversation Exports**: Claude (64MB+), ChatGPT exports
- **Bulk Note Analysis**: Hundreds of markdown files
- **Large JSON Processing**: Any structured data > 10MB

Returns Obsidian-ready output: triage reports, frontmatter, wikilinks.

---

## When to Use

### Use When:
- ContentImporter hits a file > 10MB
- Processing Claude exports with 500+ conversations
- Need to triage large archives before import
- Want metadata extraction without full file load

### Don't Use When:
- Files < 10MB (direct parsing is faster)
- Simple file operations (copy, move)
- Real-time processing needed (RLM has latency)

---

## Quick Usage

```bash
# 1. Ensure RLM server is running
curl http://localhost:4539/health

# 2. Analyze large export
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Count conversations and categorize by value",
    "context_file": "C:/exports/conversations.json"
  }'
```

**Full documentation**: See [SKILL.md](SKILL.md)

---

## Size Threshold Reference

| File Size | Action |
|-----------|--------|
| < 1MB | Direct parsing |
| 1-10MB | Direct with streaming |
| **10-50MB** | **Use this skill** |
| **50MB+** | **Use this skill with chunked queries** |

---

## Integration with ContentImporter

This skill is called by the ContentImporter agent when:
1. File size exceeds 10MB threshold
2. User requests bulk conversation triage
3. Standard JSON parsing would exceed memory

Returns structured data for ContentImporter's Triage Report format.

---

## Token Efficiency

| Approach | Tokens Used | Memory Risk | Time |
|----------|------------|-------------|------|
| **Direct Parse 64MB** | N/A | OOM Crash | N/A |
| **RLM Iterative** | ~5,000 | None | ~3 min |

---

## Prerequisites

1. RLM server running at `http://localhost:4539`
2. Ollama server with 14B+ model (or DeepSeek API)
3. See `rlm-project-assistant` skill for setup

---

## File Structure

```
obsidian-rlm/
├── SKILL.md                    # Complete documentation
├── README.md                   # This file
├── references/
│   └── QUERY_PATTERNS.md       # Common query examples
├── scripts/                    # (future automation)
└── assets/                     # (future templates)
```

---

## Related Skills

- **rlm-project-assistant** - RLM server setup and configuration
- **obsidian-markdown** - Note formatting
- **json-canvas** - Canvas file processing

---

## Official References

- **RLM Project**: https://github.com/softwarewrighter/rlm-project
- **ContentImporter Agent**: `06 Toolkit/Agents/Sub Agents/10-ContentImporter.md`

---

**Production Tested**: 64MB Claude export
**Processing Time**: ~3 minutes full triage
**Memory Safe**: Iterative processing prevents OOM
