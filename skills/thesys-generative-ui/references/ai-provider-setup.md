# AI Provider Setup Guide

Step-by-step setup for each AI provider with TheSys C1.

---

## OpenAI

```typescript
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "https://api.thesys.dev/v1/embed",
  apiKey: process.env.THESYS_API_KEY,
});

// Models
const models = [
  "c1/openai/gpt-4",
  "c1/openai/gpt-4o",
  "c1/openai/gpt-5",
  "c1/openai/gpt-5-mini"
];
```

---

## Anthropic (Claude)

```typescript
// Same client! TheSys handles the conversion
const client = new OpenAI({
  baseURL: "https://api.thesys.dev/v1/embed",
  apiKey: process.env.THESYS_API_KEY,
});

// Models
const models = [
  "c1/anthropic/claude-sonnet-4/v-20250617",
  "c1/anthropic/claude-sonnet-3-5",
  "c1/anthropic/claude-haiku-4-5"
];
```

---

## Cloudflare Workers AI

```typescript
// Option 1: Use Workers AI directly (cheaper)
const aiResponse = await env.AI.run('@cf/meta/llama-3-8b-instruct', {
  messages: [...]
});

// Option 2: Hybrid - Workers AI + C1 for UI
const c1Response = await fetch("https://api.thesys.dev/v1/embed/chat/completions", {
  method: "POST",
  headers: { "Authorization": `Bearer ${env.THESYS_API_KEY}` },
  body: JSON.stringify({
    model: "c1/openai/gpt-4",
    messages: [{ role: "user", content: aiResponse.response }]
  })
});
```

---

For complete integration examples, see SKILL.md.
