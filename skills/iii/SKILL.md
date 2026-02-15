---
name: iii
license: Apache-2.0
description: |
  Build cross-language backends with the iii engine. Register functions in TypeScript,
  Python, or Rust callable from any connected service via WebSocket. Covers iii-sdk,
  state, streams, triggers (HTTP/cron), OpenTelemetry, and Docker Compose patterns.

  Use when: setting up iii engine, cross-language function calls, iii-sdk integration,
  registerTrigger configuration, or debugging "ECONNREFUSED 49134", "trigger_type_not_found".
---

# iii - Cross-Language Backend Engine

Script paths are relative to this skill's base directory.

**Status**: Alpha (active development)
**SDK**: `iii-sdk@0.1.0` (npm) | Python `iii` | Rust `iii_sdk`
**License**: Apache-2.0
**Docs**: https://iii.dev/docs
**Last Verified**: 2026-02-14

---

## Core Concepts

iii has two fundamental primitives:

1. **Register** - Make a function callable by the engine
2. **Call** - Invoke any registered function regardless of language or process

Services connect to the iii engine over WebSocket. The engine handles routing, retries, observability, state, streams, cron, and HTTP API exposure.

---

## Quick Start

### 1. Install the Engine

```bash
curl -fsSL https://install.iii.dev/latest.sh | sh
iii --version
```

### 2. Create Engine Config (`iii-config.yaml`)

```yaml
modules:
  - class: modules::stream::StreamModule
    config:
      port: ${STREAMS_PORT:3112}
      host: 127.0.0.1
      adapter:
        class: modules::stream::adapters::KvStore
        config:
          store_method: file_based
          file_path: ./data/streams_store

  - class: modules::state::StateModule
    config:
      adapter:
        class: modules::state::adapters::KvStore
        config:
          store_method: file_based
          file_path: ./data/state_store.db

  - class: modules::api::RestApiModule
    config:
      port: 3111
      host: 127.0.0.1
      default_timeout: 30000
      concurrency_request_limit: 1024
      cors:
        allowed_origins: ["*"]
        allowed_methods: [GET, POST, PUT, DELETE, OPTIONS]

  - class: modules::observability::OtelModule
    config:
      enabled: true
      service_name: iii-engine
      exporter: memory
      sampling_ratio: 1.0
      metrics_enabled: true
      logs_enabled: true

  - class: modules::queue::QueueModule
    config:
      adapter:
        class: modules::queue::BuiltinQueueAdapter

  - class: modules::pubsub::PubSubModule
    config:
      adapter:
        class: modules::pubsub::LocalAdapter

  - class: modules::cron::CronModule
    config:
      adapter:
        class: modules::cron::KvCronAdapter
```

### 3. Start the Engine

```bash
iii -c iii-config.yaml
```

### 4. Create a TypeScript Service

```bash
mkdir my-service && cd my-service
npm init -y
npm install iii-sdk
```

Set `"type": "module"` in `package.json`.

```typescript
// src/worker.ts
import { init, getContext } from "iii-sdk";

const { registerFunction, registerTrigger, call, callVoid } = init(
  process.env.III_BRIDGE_URL ?? "ws://localhost:49134"
);

// Register a function callable by any connected service
const health = registerFunction({ id: "my-service::health" }, async () => {
  const { logger } = getContext();
  logger.info("Health check OK");
  return { status: 200, body: { healthy: true, timestamp: Date.now() } };
});

// Expose as HTTP endpoint via the engine's REST API module
registerTrigger({
  trigger_type: "http",
  function_id: health.id,
  config: { api_path: "health", http_method: "GET" },
});

console.log("Service started - listening for calls");
```

Run with: `npx tsx src/worker.ts`

Test: `curl http://localhost:3111/health`

---

## Critical Rules

### Always Do

- Use `service-name::function-name` convention for function IDs (e.g., `"client::health"`, `"data-service::transform"`)
- Set `"type": "module"` in `package.json` (SDK uses ESM)
- Use `process.env.III_BRIDGE_URL ?? "ws://localhost:49134"` for the engine address
- Start the iii engine **before** starting services
- Use `getContext()` for logging inside function handlers (provides structured OTEL logging)
- Use `Promise.allSettled()` when calling multiple remote functions in parallel (graceful partial failure)

### Never Do

- Never hardcode `ws://localhost:49134` without env var fallback
- Never use `process.env` in function IDs (they must be static strings)
- Never assume all services are available - handle missing services gracefully
- Never use 6-field cron expressions - iii supports **7 fields** (seconds included): `"*/30 * * * * * *"`
- Never call `registerTrigger` with `type` - the correct field is `trigger_type`
- Never import from `iii-sdk/state` or `iii-sdk/stream` for basic state operations - use `sdk.call("state::set", ...)` instead

---

## SDK Entry Points

| Import | Purpose |
|--------|---------|
| `iii-sdk` | Core: `init`, `getContext`, `withContext`, `Logger` (+ types). `init()` returns `ISdk` with `registerFunction`, `registerTrigger`, `call`, `callVoid` methods |
| `iii-sdk/state` | Advanced: Direct `IState` interface (get/set/delete/list/update) |
| `iii-sdk/stream` | Advanced: Direct `IStream` interface with groups |
| `iii-sdk/telemetry` | OpenTelemetry: `initOtel`, `withSpan`, `getTracer`, `getMeter` |

For most use cases, use the core SDK and `call("state::set", ...)` / `call("state::get", ...)` for state.

---

## Function Registration

```typescript
const fn = registerFunction(
  {
    id: "service::action",           // Required: unique function ID
    description: "What it does",     // Optional: for discovery
    request_format: { /* schema */ },  // Optional: input schema
    response_format: { /* schema */ }, // Optional: output schema
    metadata: { version: "1.0" },    // Optional: custom metadata
  },
  async (payload) => {
    const { logger } = getContext();
    logger.info("Processing", { payload });
    return { result: "done" };       // Return value sent back to caller
  }
);

// fn.id = "service::action"
// fn.unregister() - removes the function
```

---

## Calling Functions

```typescript
// Awaitable call (returns result)
const result = await call<InputType, OutputType>("other-service::action", { data: "hello" });

// Fire-and-forget (no return value)
callVoid("log-service::audit", { event: "user_login" });

// Parallel calls with graceful failure
const [a, b] = await Promise.allSettled([
  call("service-a::process", payload),
  call("service-b::process", payload),
]);
```

### Built-in Functions

```typescript
// State management
await call("state::set", { scope: "shared", key: "VERSION", value: 1 });
const val = await call("state::get", { scope: "shared", key: "VERSION" });

// Engine introspection
const functions = await call("engine.functions.list", {});
const workers = await call("engine.workers.list", {});
```

---

## Triggers

### HTTP Trigger

Exposes a function as an HTTP endpoint on the engine's REST API (default port 3111).

```typescript
registerTrigger({
  trigger_type: "http",
  function_id: "service::handler",
  config: {
    api_path: "users/:id",           // Path params supported
    http_method: "POST",             // GET, POST, PUT, DELETE, OPTIONS
  },
});
// Accessible at: http://localhost:3111/users/123
```

The handler receives an `ApiRequest` object:

```typescript
registerFunction({ id: "service::handler" }, async (req: ApiRequest) => {
  const { path_params, query_params, body, headers, method } = req;
  return {
    status_code: 200,
    headers: { "Content-Type": "application/json" },
    body: { id: path_params.id, data: body },
  };
});
```

### Cron Trigger

Supports **7-field cron expressions** (seconds granularity):

```typescript
registerTrigger({
  trigger_type: "cron",
  function_id: "service::cleanup",
  config: { expression: "*/30 * * * * * *" },  // Every 30 seconds
});
// Fields: seconds minutes hours day-of-month month day-of-week year
```

---

## Cross-Language Calls

Functions registered in any language are callable from any other language.

### TypeScript calls Python

```typescript
// TypeScript service
const result = await call("data-service::transform", { data: myData });
```

### Python service

```python
from iii import III, InitOptions, get_context

iii = III("ws://localhost:49134", InitOptions(worker_name="data-service"))

async def transform_handler(payload: dict) -> dict:
    ctx = get_context()
    ctx.logger.info("Processing...")
    return {"transformed": payload, "source": "data-service"}

iii.register_function("data-service::transform", transform_handler)

async def main():
    await iii.connect()
    await asyncio.Future()  # Keep running
```

### Rust service

```rust
use iii_sdk::{III, Value};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("III_BRIDGE_URL")
        .unwrap_or_else(|_| "ws://localhost:49134".into());
    let iii = III::new(&url);
    iii.connect().await?;

    iii.register_function("compute-service::compute", |input: Value| async move {
        let n = input.get("n").and_then(|v| v.as_u64()).unwrap_or(10);
        Ok(serde_json::json!({ "result": n * 2, "source": "compute-service" }))
    });

    tokio::signal::ctrl_c().await?;
    Ok(())
}
```

---

## State Management

Shared key-value state accessible across all connected services.

### Via `call()` (recommended for most cases)

```typescript
// Set
await call("state::set", { scope: "shared", key: "VERSION", value: 1 });

// Get
const val = await call("state::get", { scope: "shared", key: "VERSION" });

// Works from any language - Python example:
result = await iii.call("state::get", {"scope": "shared", "key": "VERSION"})
```

### Via Direct State API (advanced)

See `references/api-reference.md` for the full `IState` interface with `get`, `set`, `delete`, `list`, and `update` operations including atomic update ops (`set`, `increment`, `decrement`, `remove`, `merge`).

---

## Streams

Real-time durable streams organized by stream name, group, and item. See `references/api-reference.md` for the full `IStream` interface.

---

## OpenTelemetry Integration

```typescript
import { initOtel, withSpan, getTracer, getMeter } from "iii-sdk/telemetry";

// Initialize (usually called once at startup)
initOtel({
  serviceName: "my-service",
  metricsEnabled: true,
});

// Create traced spans
const result = await withSpan("process-order", { kind: SpanKind.INTERNAL }, async (span) => {
  span.setAttribute("order.id", orderId);
  return await processOrder(orderId);
});

// Custom metrics
const meter = getMeter();
if (meter) {
  const counter = meter.createCounter("orders_processed");
  counter.add(1, { status: "success" });
}
```

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `III_BRIDGE_URL` | `ws://localhost:49134` | Engine WebSocket address |
| `OTEL_ENABLED` | `true` | Enable OpenTelemetry |
| `OTEL_SERVICE_NAME` | `iii-node` | Service name for telemetry |
| `SERVICE_VERSION` | `unknown` | Service version |
| `OTEL_METRICS_ENABLED` | - | Enable metrics export |
| `OTEL_EXPORTER_TYPE` | `memory` | Exporter type (`memory` or `otlp`) |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4317` | OTLP endpoint |

---

## Docker Compose Pattern

```yaml
services:
  my-service:
    build: ./services/my-service
    environment:
      III_BRIDGE_URL: ws://host.docker.internal:49134
    extra_hosts:
      - "host.docker.internal:host-gateway"  # Required on Linux
    restart: unless-stopped
```

Run the iii engine on the **host**, not inside Docker. Services connect via `host.docker.internal`.

---

## Project Structure

```
my-iii-project/
├── iii-config.yaml          # Engine configuration
├── docker-compose.yaml      # Optional: containerized services
├── services/
│   ├── client/              # TypeScript orchestrator
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── src/worker.ts
│   ├── data-service/        # Python service
│   │   ├── requirements.txt
│   │   └── data_service.py
│   └── compute-service/     # Rust service
│       ├── Cargo.toml
│       └── src/main.rs
└── data/                    # Engine data (gitignored)
    ├── state_store.db
    └── streams_store/
```

---

## Known Issues

- **Alpha software**: API may change between releases
- **Port 49134 conflicts**: The engine's WebSocket port is fixed at 49134; ensure nothing else uses it
- **Docker networking**: On Linux Docker <20.10, `host.docker.internal` requires explicit `extra_hosts` mapping
- **Reconnection**: SDK auto-reconnects with exponential backoff (1s initial, 30s max, infinite retries by default)

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `ECONNREFUSED 127.0.0.1:49134` | Engine not running | Start with `iii -c iii-config.yaml` |
| Function call times out (30s) | Target service not connected | Start the service; check `engine.workers.list` |
| `Cannot find module 'iii-sdk'` | SDK not installed | `npm install iii-sdk` |
| HTTP endpoint returns 404 | Trigger not registered or wrong path | Verify `registerTrigger` config matches URL |
| Cron not firing | Wrong expression format | Use 7-field format: `sec min hour dom mon dow year` |
| State returns null | Wrong scope or key | Check scope/key strings match exactly |
| `trigger_type_not_found` | Used `type` instead of `trigger_type` | Change field to `trigger_type` in `registerTrigger` |
