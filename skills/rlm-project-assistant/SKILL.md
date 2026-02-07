---
name: rlm-project-assistant
description: |
  Set up and operate the RLM (Recursive Language Models) Orchestrator for processing arbitrarily large contexts. Handles Rust builds, Ollama/LiteLLM provider configuration, WASM compilation targets, and query workflows.

  Use when: setting up RLM project, configuring LLM providers for RLM, running queries against large files (10MB+), troubleshooting WASM compilation errors, or analyzing conversation exports.
source: plugin
---

# RLM Project Assistant

**Status**: Beta
**Last Updated**: 2026-01-25
**Dependencies**: Rust (via rustup), MSVC Build Tools (Windows), Ollama or DeepSeek API
**Latest Versions**: rlm-orchestrator@0.2.0, rustup@1.28.2, wasmtime@27.0.0

---

## Quick Start (15 Minutes)

### 1. Clone and Navigate

```bash
git clone https://github.com/softwarewrighter/rlm-project.git D:/rlm-project
cd D:/rlm-project/rlm-orchestrator
```

**Why this matters:**
- RLM processes contexts 100x larger than typical LLM context windows
- Uses iterative JSON commands to analyze large files

### 2. Install Rust with WASM Support

```powershell
# Install rustup (NOT scoop rust - need rustup for targets)
winget install Rustlang.Rustup --silent --accept-package-agreements

# Refresh PATH (or restart terminal)
$env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"

# Add WASM target
rustup target add wasm32-unknown-unknown

# Verify
rustc --version
rustup target list --installed | Select-String wasm
```

**CRITICAL:**
- Do NOT use `scoop install rust` - it lacks rustup for managing targets
- WASM target is required for `rust_wasm_mapreduce` commands
- Windows requires MSVC Build Tools (see Step 3)

### 3. Install MSVC Build Tools (Windows Only)

```powershell
# Download and install with C++ workload
winget install Microsoft.VisualStudio.2022.BuildTools

# Then run installer with required components
C:\temp\vs_buildtools.exe --add Microsoft.VisualStudio.Workload.VCTools `
  --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
  --add Microsoft.VisualStudio.Component.Windows11SDK.22621 `
  --quiet --wait
```

**Why this matters:**
- Rust on Windows uses MSVC linker by default
- Without it, you'll see `link.exe failed` errors
- Git's `link.exe` is NOT the same as MSVC's

### 4. Build RLM

```powershell
cd D:\rlm-project\rlm-orchestrator
cargo build --release
```

Build takes ~2-3 minutes first time. Outputs:
- `target/release/rlm-server.exe` - HTTP server with visualizer
- `target/release/rlm.exe` - CLI tool

### 5. Configure LLM Provider

Create `config-local.toml` for your Ollama setup:

```toml
max_iterations = 20
max_sub_calls = 50
output_limit = 10000

bypass_enabled = true
bypass_threshold = 4000

level_priority = ["dsl", "wasm"]

[dsl]
enabled = true
max_regex_matches = 10000

[wasm]
enabled = true
rust_wasm_enabled = true
fuel_limit = 1000000
memory_limit = 67108864

# Code generation via Ollama
codegen_provider = "ollama"
codegen_url = "http://192.168.1.120:11434"
codegen_model = "qwen2.5:14b-instruct-q4_K_M"

# Root LLM (needs 32B+ for reliable JSON)
[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen2.5:14b-instruct-q4_K_M"
role = "root"
weight = 1

# Sub LLM (can be smaller, handles simple tasks)
[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen3:1.7b-q4_K_M"
role = "sub"
weight = 1
```

### 6. Run and Test

```powershell
# Start server
.\target\release\rlm-server.exe config-local.toml

# In another terminal, test health
curl http://localhost:4539/health

# Open visualizer
start http://localhost:4539/visualize
```

---

## The 6-Step Setup Process

### Step 1: Environment Detection

RLM runs on Windows, WSL, Linux, and macOS. Detect your environment:

```bash
if [[ "$OS" == "Windows_NT" || -n "$MSYSTEM" ]]; then
    echo "Windows (Git Bash)"
    CARGO_PATH="$HOME/.cargo/bin"
elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL"
    CARGO_PATH="$HOME/.cargo/bin"
else
    echo "Linux/macOS"
    CARGO_PATH="$HOME/.cargo/bin"
fi
```

### Step 2: Rust Toolchain

| Platform | Installation Method | Notes |
|----------|-------------------|-------|
| Windows | `winget install Rustlang.Rustup` | Requires MSVC Build Tools |
| WSL/Linux | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` | Standard |
| macOS | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` | Xcode CLT required |

### Step 3: WASM Target

```bash
rustup target add wasm32-unknown-unknown
```

Enables:
- `rust_wasm_intent` - LLM generates Rust code compiled to WASM
- `rust_wasm_mapreduce` - Parallel processing of large contexts

### Step 4: LLM Provider Selection

See `references/LOCAL_LLM_GUIDE.md` for detailed model recommendations.

| Provider | JSON Reliability | Best For | Cost |
|----------|-----------------|----------|------|
| **OpenAI GPT-4o** | ✅ Excellent | Production, large files | ~$0.01/query |
| **OpenRouter** | ✅ Excellent | Multi-model access | Varies |
| **DeepSeek API** | ✅ Excellent | Cheap + reliable | ~$0.001/query |
| Ollama 70B+ | ⚠️ Good | Privacy, air-gapped | Electricity |
| Ollama 24B-32B | ❌ Unreliable | Sub-calls only | Electricity |
| Ollama 14B | ❌ Very Unreliable | Not recommended for root | Electricity |

**Key insight:** Local models (14B-24B) struggle with RLM's JSON protocol. Use API providers for root LLM.

### Step 5: Configuration

Key config sections:

```toml
# Limits
max_iterations = 20      # Max RLM loop iterations
max_sub_calls = 50       # Max llm_query sub-calls
output_limit = 10000     # Max chars in command output

# Smart bypass (skip RLM for small contexts)
bypass_enabled = true
bypass_threshold = 4000  # chars (~1000 tokens)

# Feature levels
level_priority = ["dsl", "wasm", "cli", "llm_delegation"]
```

### Step 6: Verification

```bash
# Health check
curl http://localhost:4539/health
# Expected: {"status":"healthy","version":"0.2.0","wasm_enabled":true,"rust_wasm_enabled":true}

# Simple query
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{"query": "How many lines?", "context": "Line 1\nLine 2\nLine 3"}'
```

---

## Critical Rules

### Always Do

- Use `rustup` (not scoop/brew rust) for target management
- Add `wasm32-unknown-unknown` target before building
- Use 32B+ models for root LLM (JSON reliability)
- Test with `/health` endpoint before running queries
- Check `references/LOCAL_LLM_GUIDE.md` for model recommendations

### Never Do

- Use scoop/brew Rust on Windows (lacks rustup)
- Use 7B-14B models as root LLM (unreliable JSON)
- Skip MSVC Build Tools on Windows
- Ignore WASM compilation errors (install target first)
- Run without testing health endpoint

---

## Known Issues Prevention

This skill prevents **6** documented issues:

### Issue #1: link.exe Failed (Windows)
**Error**: `linking with link.exe failed: exit code: 1`
**Source**: Rust on Windows requires MSVC linker
**Why It Happens**: Git's `link.exe` found instead of MSVC's
**Prevention**: Install VS Build Tools with VCTools workload

### Issue #2: WASM Target Missing
**Error**: `error[E0463]: can't find crate for std` with note about `wasm32-unknown-unknown`
**Source**: WASM compilation requires explicit target
**Why It Happens**: rustup doesn't include WASM target by default
**Prevention**: Run `rustup target add wasm32-unknown-unknown`

### Issue #3: JSON Parse Errors from LLM
**Error**: `Failed to parse JSON command` or malformed output
**Source**: Model too small for RLM protocol
**Why It Happens**: 7B-14B models can't follow JSON protocol reliably
**Prevention**: Use 32B+ model for root LLM (or DeepSeek API)

### Issue #4: Server Binding Error
**Error**: `Address already in use` on port 4539/8080
**Source**: Previous server still running
**Why It Happens**: Didn't stop previous instance
**Prevention**: `pkill -f rlm-server` or check `netstat -an | grep 4539`

### Issue #5: Scoop Rust Missing Targets
**Error**: `rustup: command not found` after installing via scoop
**Source**: Scoop rust package doesn't include rustup
**Why It Happens**: Scoop provides standalone rustc, not full toolchain
**Prevention**: Use `winget install Rustlang.Rustup` instead

### Issue #6: WASM Crashes on Large Files (70MB+)
**Error**: `thread 'tokio-runtime-worker' panicked... panic in a function that cannot unwind`
**Source**: WASM runtime memory limits exceeded during execution
**Why It Happens**: WASM fuel/memory limits aren't sufficient for iterating over 70MB+ files
**Prevention**: Disable WASM for large files (`enabled = false`), use hybrid Python+RLM workflow

---

## Configuration Files Reference

### config-lan-ollama.toml (Full Example)

```toml
# RLM Orchestrator Configuration - LAN Ollama
max_iterations = 20
max_sub_calls = 50
output_limit = 10000

# Smart bypass for small contexts
bypass_enabled = true
bypass_threshold = 4000

# Feature levels
level_priority = ["dsl", "wasm"]

# DSL Configuration
[dsl]
enabled = true
max_regex_matches = 10000
max_slice_size = 1048576
max_variables = 100

# WASM Configuration
[wasm]
enabled = true
rust_wasm_enabled = true
fuel_limit = 1000000
memory_limit = 67108864
cache_size = 100

codegen_provider = "ollama"
codegen_url = "http://192.168.1.120:11434"
codegen_model = "qwen2.5:14b-instruct-q4_K_M"

# Root LLM - handles RLM orchestration
[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen2.5:14b-instruct-q4_K_M"
role = "root"
weight = 1

# Sub LLM - handles llm_query calls
[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen3:1.7b-q4_K_M"
role = "sub"
weight = 1
```

**Why these settings:**
- `bypass_threshold = 4000` - Skip RLM overhead for small contexts
- `fuel_limit = 1000000` - Prevent infinite loops in WASM
- Separate root/sub models - Root needs capability, sub needs speed

---

## Common Patterns

### Pattern 1: Query Large Log File

```bash
# Load file content and query
CONTEXT=$(cat /path/to/large.log)
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"Count ERROR lines\", \"context\": $(echo "$CONTEXT" | jq -Rs .)}"
```

**When to use**: Log analysis, error counting, pattern finding

### Pattern 2: Debug Mode for Iteration Details

```bash
curl -X POST http://localhost:4539/debug \
  -H "Content-Type: application/json" \
  -d '{"query": "...", "context": "..."}'
```

**When to use**: Understanding RLM's reasoning, troubleshooting queries

### Pattern 3: OpenAI API (Recommended for Production)

```toml
# config-openai.toml
# Set LITELLM_API_KEY=your-openai-key

[[providers]]
provider_type = "litellm"
base_url = "https://api.openai.com/v1"
model = "gpt-4o"
role = "root"
weight = 1

[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen3:1.7b-q4_K_M"
role = "sub"
weight = 1
```

**When to use**: Production workloads, large files, best JSON reliability

### Pattern 4: OpenRouter (Multi-Model Access)

```toml
# config-openrouter.toml
# Set LITELLM_API_KEY=your-openrouter-key

[[providers]]
provider_type = "litellm"
base_url = "https://openrouter.ai/api/v1"
model = "deepseek/deepseek-chat"
role = "root"
weight = 1

[[providers]]
provider_type = "ollama"
base_url = "http://192.168.1.120:11434"
model = "qwen3:1.7b-q4_K_M"
role = "sub"
weight = 1
```

**When to use**: Access to multiple models via single API, cost optimization

### Pattern 5: DeepSeek API Direct

```toml
# Set DEEPSEEK_API_KEY env var

[[providers]]
provider_type = "deepseek"
model = "deepseek-chat"
role = "root"

[[providers]]
provider_type = "ollama"
base_url = "http://localhost:11434"
model = "qwen2.5-coder:14b"
role = "sub"
```

**When to use**: Cheapest reliable option (~$0.001/query)

---

## Using Bundled Resources

### References (references/)

- `LOCAL_LLM_GUIDE.md` - Comprehensive guide for model selection, hardware configs, performance expectations
- `LOCAL_OLLAMA_INSTALLED_MODELS.md` - Current installed models on LAN Ollama server

**When Claude should load these**:
- When selecting models for root vs sub LLM
- When troubleshooting model capability issues
- When optimizing for hardware constraints

---

## Advanced Topics

### Processing Very Large Files (64MB+)

**⚠️ KNOWN ISSUE**: WASM crashes on files >70MB due to memory limits during execution.

For files like Claude conversation exports (72MB+), use the **hybrid approach**:

#### Recommended: Hybrid Workflow

1. **Python/jq for metadata extraction** (fast, reliable):
```python
import json
with open('conversations.json') as f:
    data = json.load(f)
print(f"Total: {len(data)} conversations")
print(f"Date range: {min(c['created_at'][:10] for c in data)} to {max(c['created_at'][:10] for c in data)}")
```

2. **RLM for content analysis** on specific extracted segments:
```bash
# Extract one conversation, then analyze with RLM
curl -X POST http://localhost:4539/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Summarize the key decisions", "context": "..."}'
```

#### If Using RLM Directly on Large Files

1. **Disable WASM** (prevents crashes):
```toml
[wasm]
enabled = false
rust_wasm_enabled = false
```

2. **Increase limits**:
```toml
max_iterations = 50
max_sub_calls = 100
output_limit = 50000

[dsl]
max_slice_size = 10485760      # 10MB
max_variable_size = 10485760   # 10MB
```

3. **Use API provider** (OpenAI/OpenRouter) for reliable JSON

4. **Use DSL-only queries**:
- Slicing: "Slice the first 5000 characters and describe the structure"
- Simple counts work but complex regex may timeout

### LiteLLM Gateway Integration

For usage tracking and multi-provider fallback:

```toml
[[providers]]
provider_type = "litellm"
base_url = "http://localhost:4000"
model = "deepseek/deepseek-chat"
role = "root"
```

Set `LITELLM_MASTER_KEY` environment variable for authentication.

---

## Dependencies

**Required**:
- Rust 1.70+ via rustup - Build and WASM compilation
- MSVC Build Tools (Windows) - Native linking
- Ollama or DeepSeek API - LLM provider

**Optional**:
- LiteLLM - Proxy for usage tracking
- jq - JSON processing in scripts

---

## Official Documentation

- **RLM Project**: https://github.com/softwarewrighter/rlm-project
- **RLM Paper**: https://arxiv.org/html/2512.24601v1
- **Ollama**: https://ollama.ai
- **DeepSeek API**: https://platform.deepseek.com
- **Rustup**: https://rustup.rs

---

## Package Versions (Verified 2026-01-25)

```json
{
  "rust": "1.93.0",
  "rustup": "1.28.2",
  "wasmtime": "27.0.0",
  "rlm-orchestrator": "0.2.0",
  "dependencies": {
    "axum": "0.7.9",
    "tokio": "1.x",
    "reqwest": "0.12.x"
  }
}
```

---

## Production Example

This skill is based on actual RLM setup on Windows 11:

### Setup Details
- **Server**: 192.168.1.120 running Ollama with Qwen models
- **Build Time**: ~2 minutes (first build)
- **Query Time**: 2-30 seconds depending on provider and context size

### Testing Results (72MB Claude Export)

| Provider | JSON Reliability | Query Success |
|----------|-----------------|---------------|
| Qwen 14B (Ollama) | ❌ Frequent parse errors | Partial |
| Mistral 24B (Ollama) | ❌ Parse errors | Partial |
| GPT-4o (OpenAI) | ✅ Excellent | Yes |

### Key Findings
- **Local models (14B-24B)**: Unreliable JSON output, frequent parse errors
- **GPT-4o via litellm**: Works perfectly, ~2-3 second responses
- **WASM on 72MB**: Crashes during execution (memory limits)
- **Hybrid approach**: Python for metadata + RLM for analysis = best results

### Actual Test Results (72MB file)
```
Total conversations: 1,375
Date range: 2023-08-10 to 2025-09-09
HIGH VALUE (50+ msgs): 1
MEDIUM (11-50 msgs): 183
LOW (1-10 msgs): 1,158
Processing: Python instant, RLM+GPT-4o ~3 seconds per query
```

---

## Troubleshooting

### Problem: Cargo build fails with link.exe error
**Solution**: Install VS Build Tools with VCTools workload. Ensure MSVC link.exe is in PATH before Git's.

### Problem: WASM commands fail with "can't find crate for std"
**Solution**: Run `rustup target add wasm32-unknown-unknown`

### Problem: LLM outputs prose instead of JSON
**Solution**: Use larger model (32B+) or switch to DeepSeek API for root LLM

### Problem: Server won't start (port in use)
**Solution**: Kill existing process: `pkill -f rlm-server` or use different port in config

### Problem: Queries time out
**Solution**: Check Ollama server connectivity. Increase timeout in config. Use smaller model for faster responses.

---

## Complete Setup Checklist

Use this checklist to verify your setup:

- [ ] Rust installed via rustup (not scoop/brew)
- [ ] WASM target added: `rustup target list --installed | grep wasm`
- [ ] MSVC Build Tools installed (Windows)
- [ ] RLM built successfully: `cargo build --release`
- [ ] Config file created with your Ollama server
- [ ] Server starts without errors
- [ ] Health check returns `healthy`
- [ ] Simple query returns expected result
- [ ] WASM enabled in health response

---

**Questions? Issues?**

1. Check `references/LOCAL_LLM_GUIDE.md` for model selection
2. Verify all steps in setup checklist
3. Check official docs: https://github.com/softwarewrighter/rlm-project
4. Ensure Ollama server is running and accessible
