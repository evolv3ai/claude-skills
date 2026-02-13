# SimpleMem Correction Rules

Rules to correct outdated or incorrect SimpleMem patterns.

## Provider Lock-in

WRONG - Assuming OpenRouter is the only provider:
```python
OPENROUTER_API_KEY = "sk-or-..."  # Only option
```

RIGHT - SimpleMem supports any OpenAI-compatible API:
```python
# Option 1: OpenAI direct
OPENAI_API_KEY = "sk-..."
LLM_MODEL = "gpt-4.1-mini"

# Option 2: OpenRouter (multi-provider gateway)
OPENROUTER_API_KEY = "sk-or-..."
LLM_MODEL = "openai/gpt-4.1-mini"

# Option 3: LiteLLM (multi-provider abstraction)
# Configured via LITELLM_* settings

# Option 4: Azure OpenAI
OPENAI_API_KEY = "your-azure-key"
OPENAI_BASE_URL = "https://your-endpoint.openai.azure.com/"
```

## Model Names

WRONG - Outdated model references:
```python
LLM_MODEL = "anthropic/claude-3.5-sonnet"
LLM_MODEL = "openai/gpt-4o-mini"
EMBEDDING_MODEL = "openai/text-embedding-3-small"
```

RIGHT - Current model names:
```python
LLM_MODEL = "gpt-4.1-mini"                      # Direct OpenAI
LLM_MODEL = "openai/gpt-4.1-mini"               # Via OpenRouter
EMBEDDING_MODEL = "Qwen/Qwen3-Embedding-0.6B"   # State-of-the-art, small
EMBEDDING_MODEL = "qwen/qwen3-embedding-8b"      # Via OpenRouter, larger
```

## Package Installation

WRONG - Using pip with requirements.txt from the skill directory:
```bash
cd ~/.claude/skills/simplemem-skill
pip install -r requirements.txt
```

RIGHT - Install from PyPI:
```bash
pip install simplemem
# or with uv
uv add simplemem
# or with GPU support
pip install simplemem[gpu]
```

## Memory Deletion

WRONG - Assuming memories cannot be deleted individually:
```python
# Only bulk clear available
system.vector_store.clear()
```

RIGHT - Individual deletion by entry_id or ref_id:
```python
system.vector_store.delete_by_id(entry_id="uuid-string")
system.vector_store.delete_by_ref_id(ref_id="application-ref")
```

## Embedding Dimension Mismatch

WRONG - Changing embedding model without updating dimension:
```python
EMBEDDING_MODEL = "qwen/qwen3-embedding-8b"
EMBEDDING_DIMENSION = 1536  # Mismatched!
```

RIGHT - Dimension must match the model, and clear DB after changes:
```python
EMBEDDING_MODEL = "qwen/qwen3-embedding-8b"
EMBEDDING_DIMENSION = 4096  # Matches qwen3-embedding-8b

# After changing embedding model/dimension:
# rm -rf data/lancedb/*
```

## Cross-Session Memory

WRONG - Not knowing SimpleMem-Cross exists:
```python
# Manually re-injecting context each session
system = SimpleMemSystem()
system.add_dialogue("User", previous_context)
```

RIGHT - Use SimpleMem-Cross for automatic cross-session persistence:
```python
from cross.orchestrator import create_orchestrator

orch = create_orchestrator(project="my-project")
result = await orch.start_session(
    content_session_id="session-002",
    user_prompt="Continue the work",
)
# Previous context is injected automatically via token-budgeted retrieval
```

## MCP Configuration

WRONG - Missing auth header or wrong endpoint:
```json
{
  "mcpServers": {
    "simplemem": {
      "url": "https://mcp.simplemem.cloud"
    }
  }
}
```

RIGHT - Include /mcp path and Bearer token:
```json
{
  "mcpServers": {
    "simplemem": {
      "url": "https://mcp.simplemem.cloud/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN"
      }
    }
  }
}
```
