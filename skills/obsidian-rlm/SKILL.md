---
name: obsidian-rlm
description: |
  Process large files for Obsidian workflows using RLM (Recursive Language Models). Handles LLM conversation exports (64MB+), bulk note analysis, and large JSON processing that would overwhelm standard tools.

  Use when: ContentImporter hits files over 10MB, processing large Claude/ChatGPT exports, bulk triage of conversation archives, extracting insights from massive JSON files.
source: plugin
---

# Obsidian RLM - Large File Processor

**Status**: Production-Tested
**Last Updated**: 2026-01-26
**Dependencies**: RLM Server running, **API provider recommended** (OpenAI/OpenRouter)
**Integrates With**: ContentImporter agent, Obsidian vault workflows

---

## ⚠️ Critical: Provider Requirements

**Local models (14B-24B) are unreliable for RLM's JSON protocol.** Testing with 72MB Claude export showed:

| Provider | JSON Reliability | Recommended |
|----------|-----------------|-------------|
| **OpenAI GPT-4o** | ✅ Excellent | **Yes** |
| **OpenRouter** | ✅ Excellent | **Yes** |
| DeepSeek API | ✅ Excellent | Yes |
| Ollama 70B+ | ⚠️ Moderate | Fallback |
| Ollama 14B-24B | ❌ Unreliable | No |

**For production use with large files, use API providers.**

---

## Recommended: Hybrid Approach

For files >50MB, the **hybrid approach** is most reliable:

1. **Python/jq for metadata** (instant, 100% reliable)
2. **RLM for content analysis** on extracted segments

See "Hybrid Workflow" section below.

---

## Purpose

When the **ContentImporter** agent encounters files too large for direct processing (10MB+), this skill takes over to:

1. **Analyze** the file structure via RLM iterative commands
2. **Extract** metadata, counts, and summaries without loading entire file
3. **Return** structured data for ContentImporter's triage workflow
4. **Generate** Obsidian-ready output (frontmatter, wikilinks, tags)

---

## Hybrid Workflow (Recommended for 50MB+)

**Tested with 72MB Claude export (1,375 conversations)**

### Step 1: Python Metadata Extraction (Instant)

```python
import json

with open('conversations.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# Basic stats
print(f"Total conversations: {len(data)}")
dates = [c['created_at'][:10] for c in data if c.get('created_at')]
print(f"Date range: {min(dates)} to {max(dates)}")

# Triage by message count
msg_counts = [len(c.get('chat_messages', [])) for c in data]
high_value = sum(1 for c in msg_counts if c > 50)
medium = sum(1 for c in msg_counts if 10 < c <= 50)
low = sum(1 for c in msg_counts if 0 < c <= 10)
print(f"HIGH (50+ msgs): {high_value}")
print(f"MEDIUM (11-50): {medium}")
print(f"LOW (1-10): {low}")

# Top conversations
convos = [(c.get('name', ''), len(c.get('chat_messages', []))) for c in data]
convos.sort(key=lambda x: x[1], reverse=True)
print("\nTop 10:")
for name, count in convos[:10]:
    print(f"  {count:3} msgs - {name[:50]}")
```

### Step 2: RLM for Content Analysis

For specific conversations needing deeper analysis:

```bash
# Extract one conversation to a smaller file
python -c "
import json
with open('conversations.json') as f:
    data = json.load(f)
# Find conversation by name
conv = next(c for c in data if 'BMAD' in c.get('name', ''))
with open('single_conv.json', 'w') as f:
    json.dump(conv, f)
"

# Analyze with RLM
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Summarize the key decisions and action items from this conversation",
    "context_path": "demo/single_conv.json"
  }'
```

---

## Quick Start

### Prerequisites

1. **RLM Server Running** at `http://localhost:4539`
   ```powershell
   cd D:\rlm-project\rlm-orchestrator
   # Use OpenAI config for reliability
   $env:LITELLM_API_KEY = "your-openai-key"
   .\target\release\rlm-server.exe config-openai.toml
   ```

2. **Verify Health**
   ```bash
   curl http://localhost:4539/health
   # Expected: {"status":"healthy","wasm_enabled":false}
   ```

**Note**: WASM is disabled for large files (crashes on 70MB+). DSL-only mode is sufficient.

### Basic Usage

```bash
# Count conversations in large Claude export
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Count the total number of conversations in this JSON",
    "context_file": "C:/exports/conversations.json"
  }'

# Extract conversation titles for triage
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "List all conversation names with their created_at dates",
    "context_file": "C:/exports/conversations.json"
  }'
```

---

## Size Threshold Logic

| File Size | Recommended Approach | Why |
|-----------|---------------------|-----|
| < 1MB | Direct parsing | Fast, no overhead |
| 1-10MB | Direct with streaming | Manageable in memory |
| 10-50MB | **RLM with API provider** | Iterative processing, reliable JSON |
| 50MB+ | **Hybrid: Python + RLM** | Python for metadata, RLM for analysis |
| 70MB+ | **Hybrid only** | WASM crashes, DSL-only too slow |

**⚠️ WASM crashes on files >70MB** - Always disable WASM for large files.

### Detection Code (for ContentImporter)

```javascript
// In ContentImporter workflow
const fileSizeMB = fs.statSync(filePath).size / (1024 * 1024);

if (fileSizeMB > 10) {
  // Trigger obsidian-rlm skill
  console.log(`Large file detected (${fileSizeMB.toFixed(1)}MB) - using RLM`);
  return processWithRLM(filePath, query);
} else {
  // Standard processing
  return JSON.parse(fs.readFileSync(filePath));
}
```

---

## Supported File Formats

### Claude/Anthropic Exports

**Structure:**
```json
{
  "conversations": [
    {
      "uuid": "abc123",
      "name": "Project Discussion",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T12:45:00Z",
      "chat_messages": [
        {"sender": "human", "text": "..."},
        {"sender": "assistant", "text": "..."}
      ]
    }
  ]
}
```

**Common RLM Queries:**
- "Count total conversations"
- "List conversation names with dates"
- "Find conversations mentioning [topic]"
- "Extract conversations longer than 20 messages"
- "Identify conversations with code blocks"

### ChatGPT/OpenAI Exports

**Structure:**
```json
{
  "title": "Conversation Title",
  "create_time": 1705312800,
  "mapping": {
    "node_id": {
      "message": {
        "author": {"role": "user|assistant"},
        "content": {"parts": ["..."]}
      }
    }
  }
}
```

**Common RLM Queries:**
- "Count total conversations across all files"
- "List titles with create_time converted to dates"
- "Find conversations about [topic]"
- "Extract conversations with assistant code responses"

---

## RLM Query Patterns for Obsidian

### Pattern 1: Generate Triage Report

**Query:**
```
Analyze this Claude conversations export and generate a triage report:
- Count total conversations
- Categorize by apparent topic (coding, writing, research, general)
- Flag conversations with >50 messages as HIGH VALUE
- Flag conversations with code blocks as HIGH VALUE
- Return as markdown table format
```

**Expected Output:**
```markdown
| Category | Count | High Value |
|----------|-------|------------|
| Coding | 47 | 23 |
| Writing | 18 | 5 |
| Research | 12 | 8 |
| General | 89 | 2 |
| **Total** | **166** | **38** |
```

### Pattern 2: Extract Metadata for Staging

**Query:**
```
For each conversation in this export, extract:
- uuid
- name (truncated to 50 chars)
- created_at date (YYYY-MM-DD format)
- message_count
- has_code_blocks (true/false)
Return as JSON array
```

**Expected Output:**
```json
[
  {"uuid": "abc123", "name": "Project Architecture Discussion", "date": "2024-01-15", "message_count": 67, "has_code": true},
  {"uuid": "def456", "name": "Quick Question About Syntax", "date": "2024-01-14", "message_count": 4, "has_code": false}
]
```

### Pattern 3: Search for Specific Topics

**Query:**
```
Find all conversations that discuss "Obsidian" or "vault" or "PKM".
Return conversation names and relevant excerpt (first 200 chars of matching message).
```

### Pattern 4: Generate Frontmatter Batch

**Query:**
```
For HIGH VALUE conversations (>30 messages or contains code), generate Obsidian frontmatter:
- title: conversation name
- date: created_at
- tags: [inferred from content]
- source: "Claude Export"
- import-date: "[[2026-01-25]]"
Return as YAML blocks ready for copy-paste
```

---

## Integration with ContentImporter

### Workflow: Large Claude Export

```
1. User: "Process my Claude export at C:\exports\conversations.json"

2. ContentImporter checks file size:
   - Size: 64MB → Triggers obsidian-rlm

3. obsidian-rlm runs initial analysis:
   - Query: "Count conversations, identify structure"
   - Returns: 847 conversations, Claude format

4. obsidian-rlm runs triage:
   - Query: "Categorize by value (HIGH/MEDIUM/LOW)"
   - Returns: 52 HIGH, 189 MEDIUM, 606 LOW

5. ContentImporter generates Triage Report

6. User selects items to import

7. obsidian-rlm extracts selected conversations:
   - Query: "Extract full conversation with uuid [X]"
   - Returns: Complete conversation text

8. ContentImporter creates notes in 00 NoteLab/
```

### Data Handoff Format

obsidian-rlm returns data in this format for ContentImporter:

```json
{
  "analysis": {
    "file_path": "C:/exports/conversations.json",
    "file_size_mb": 64.2,
    "format": "claude",
    "total_conversations": 847,
    "processing_time_seconds": 45
  },
  "triage": {
    "high_value": [
      {
        "uuid": "abc123",
        "name": "System Architecture Design",
        "date": "2024-01-15",
        "message_count": 89,
        "has_code": true,
        "suggested_folder": "02 Cards/Reference",
        "suggested_tags": ["#Architecture", "#Reference", "#🌲"]
      }
    ],
    "medium_value": [...],
    "low_value_count": 606
  }
}
```

---

## Configuration

### RLM Config for Large Files

Use increased limits for 64MB+ files:

```toml
# config-large-files.toml
max_iterations = 50        # More iterations for complex queries
max_sub_calls = 100        # More sub-calls for detailed analysis
output_limit = 50000       # Larger output for full extractions

bypass_enabled = true
bypass_threshold = 4000

[wasm]
enabled = true
rust_wasm_enabled = true
fuel_limit = 5000000       # 5x normal for large files
memory_limit = 268435456   # 256MB for large context

codegen_provider = "ollama"
codegen_url = "http://192.168.1.120:11434"
codegen_model = "qwen2.5:14b-instruct-q4_K_M"

[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen2.5:14b-instruct-q4_K_M"
role = "root"
weight = 1

[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen3:1.7b-q4_K_M"
role = "sub"
weight = 1
```

---

## Troubleshooting

### Problem: RLM times out on 64MB file
**Solution**: Use chunked queries. Instead of loading entire file, query specific ranges:
```
"Analyze conversations 0-100 in this export"
"Analyze conversations 100-200 in this export"
```

### Problem: JSON parse errors on Claude export
**Solution**: Verify file is valid JSON. Claude exports occasionally have encoding issues:
```bash
# Validate JSON
python -c "import json; json.load(open('conversations.json'))"
```

### Problem: RLM server not responding
**Solution**: Check server is running and accessible:
```bash
curl http://localhost:4539/health
# If no response, restart server
```

### Problem: Ollama model too slow
**Solution**: For initial triage (not extraction), use faster/smaller models:
```toml
# Fast triage model
model = "qwen3:8b"  # Faster than 14b for simple counts
```

---

## Performance Expectations

| File Size | Query Type | Expected Time |
|-----------|------------|---------------|
| 10MB | Count conversations | 5-10 seconds |
| 10MB | Full triage | 30-60 seconds |
| 64MB | Count conversations | 15-30 seconds |
| 64MB | Full triage | 2-5 minutes |
| 64MB | Extract specific conversation | 10-20 seconds |

---

## Complete Example: Process 64MB Export

```bash
# 1. Start RLM server
cd D:\rlm-project\rlm-orchestrator
.\target\release\rlm-server.exe config-lan-ollama.toml

# 2. Initial analysis
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Analyze this Claude export: count conversations, identify date range, count total messages",
    "context_file": "C:/exports/conversations.json"
  }'

# Response: 847 conversations, 2023-06-01 to 2024-12-31, 42,891 messages

# 3. Triage by value
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Categorize conversations: HIGH VALUE (>50 messages OR has code), MEDIUM (10-50 messages), LOW (<10 messages). Return counts and list HIGH VALUE names.",
    "context_file": "C:/exports/conversations.json"
  }'

# Response: HIGH: 52, MEDIUM: 189, LOW: 606. HIGH VALUE list...

# 4. Extract specific conversation
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Extract the full conversation named \"System Architecture Design\" with all messages",
    "context_file": "C:/exports/conversations.json"
  }'

# 5. Generate Obsidian note
# ContentImporter takes the extracted conversation and creates note in 00 NoteLab/
```

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `rlm-project-assistant` | Full RLM setup and configuration |
| `obsidian-markdown` | Note formatting and frontmatter |
| `json-canvas` | Processing .canvas files |

---

## References

- See `rlm-project-assistant` skill for full RLM setup instructions
- See `references/QUERY_PATTERNS.md` for additional query examples
- See ContentImporter agent: `06 Toolkit/Agents/Sub Agents/10-ContentImporter.md`

---

**Production Tested**: 64MB Claude export, 847 conversations
**Processing Time**: ~3 minutes for full triage
**Integration**: ContentImporter agent ready
