# iii Engine - Correction Rules

## Trigger Registration (changed in 0.2.0)

The `registerTrigger` field for trigger kind is `type`, NOT `trigger_type`.

```typescript
// CORRECT (iii-sdk@0.2.0)
registerTrigger({
  type: "http",
  function_id: "service::handler",
  config: { api_path: "endpoint", http_method: "GET" },
});

// WRONG - will fail with "type_not_found"
registerTrigger({
  trigger_type: "http",  // <-- wrong field name in 0.2.0
  function_id: "service::handler",
  config: { api_path: "endpoint", http_method: "GET" },
});
```

> **Note**: In 0.1.0 the field was `trigger_type`. It changed to `type` in 0.2.0. The 0.3.0-alpha suggests it may revert to `trigger_type` again in a future release.

## Engine Function Paths (changed in 0.2.0)

Engine built-in functions use `::` separator, not dots.

```typescript
// CORRECT (0.2.0)
await call("engine::functions::list", {});
await call("engine::workers::list", {});

// WRONG - old 0.1.0 dot syntax
await call("engine.functions.list", {});  // <-- won't resolve in 0.2.0
```

## ESM Required

Always set `"type": "module"` in `package.json`. The SDK uses ESM imports. CJS is also supported in 0.2.0 via `require()`.

## Cron Expressions

iii uses **7-field** cron expressions (seconds granularity):
`seconds minutes hours day-of-month month day-of-week year`

```typescript
// CORRECT - 7 fields
{ expression: "*/30 * * * * * *" }

// WRONG - 5 fields (standard cron)
{ expression: "*/30 * * * *" }
```

## SDK Imports

`registerFunction`, `registerTrigger`, `call`, `callVoid` are methods on the `ISdk` object returned by `init()`, NOT direct imports from `iii-sdk`.

```typescript
// CORRECT
import { init, getContext } from "iii-sdk";
const { registerFunction, registerTrigger, call, callVoid } = init(url);

// WRONG
import { registerFunction, call } from "iii-sdk";  // these don't exist as exports
```

## Function ID Convention

Use `service-name::function-name` format. IDs must be static strings, never dynamic.

## Graceful Shutdown (new in 0.2.0)

Always call `shutdown()` during graceful process termination to close WebSocket connections cleanly.

```typescript
const sdk = init(url);
// ... register functions, do work ...
await sdk.shutdown();  // Clean up before exit
```

## SDK Namespace Confusion (`iii-sdk` vs `@iii-dev/sdk`)

The iii.dev docs reference `@iii-dev/sdk` with a `Bridge` class — this package does **not exist on npm** (404). Always use `iii-sdk` (no scope).

```typescript
// CORRECT — published on npm
import { init } from "iii-sdk";
const sdk = init("ws://localhost:49134");

// WRONG — does not exist on npm (returns 404)
import { Bridge } from "@iii-dev/sdk";  // <-- npm install will fail
```

The docs SDK (`@iii-dev/sdk`) uses different API conventions:
- `function_path` with dot separators (`"svc.fn"`) instead of `id`/`function_id` with `::` (`"svc::fn"`)
- `trigger_type` instead of `type`
- `invokeFunction()` instead of `call()`
- `Bridge` class instead of `init()` factory

If you see docs examples using `bridge.registerFunction({ function_path: ... })`, translate to the `iii-sdk` equivalent: `registerFunction({ id: "svc::fn" }, handler)`.

## KV Server vs State Module Parameters

KV Server uses `index` + `key`, State Module uses `scope` + `key`. Do not mix them.

```typescript
// CORRECT — KV Server functions use 'index'
await call("kv_server::set", { index: "default", key: "user:123", value: data });
await call("kv_server::get", { index: "default", key: "user:123" });

// CORRECT — State module uses 'scope'
await call("state::set", { scope: "shared", key: "VERSION", value: 1 });
await call("state::get", { scope: "shared", key: "VERSION" });

// WRONG — mixing parameters
await call("kv_server::set", { scope: "default", key: "user:123", value: data });  // <-- 'scope' is wrong for kv_server
await call("state::set", { index: "shared", key: "VERSION", value: 1 });           // <-- 'index' is wrong for state
```

## Module Class Path Ambiguity (`stream` vs `streams`)

The iii.dev docs use `modules::streams::StreamModule` (plural). The `iii-sdk@0.2.0` engine uses `modules::stream::StreamModule` (singular). Both may work depending on engine version.

```yaml
# Working with iii-sdk@0.2.0 engine (confirmed)
- class: modules::stream::StreamModule
- class: modules::stream::adapters::KvStore

# In iii.dev docs (may reflect newer engine)
- class: modules::streams::StreamModule
- class: modules::streams::adapters::RedisAdapter
```

If you get `module class not found`, try switching between singular and plural forms. The same applies to adapter paths.

Similarly, `modules::observability::OtelModule` (confirmed in 0.2.0) and `modules::observability::LoggingModule` (in docs) are **different modules** — OtelModule provides OpenTelemetry tracing/metrics, LoggingModule provides structured log capture with file/Redis backends.

## Queue and Log Trigger Types

Queue and log triggers were added by the QueueModule and LoggingModule respectively.

```typescript
// CORRECT — Queue trigger (iii-sdk@0.2.0)
registerTrigger({
  type: "queue",
  function_id: "events::on-user-created",
  config: { topic: "user.created" },
});

// CORRECT — Log trigger (iii-sdk@0.2.0)
registerTrigger({
  type: "log",
  function_id: "monitoring::on-error",
  config: { level: "error" },  // optional: info, warn, error, debug
});

// CORRECT — Enqueue a message
await call("enqueue", { topic: "user.created", data: { id: "123" } });
```

> **Note**: The docs use `trigger_type` and `function_path` for these triggers. With `iii-sdk@0.2.0`, use `type` and `function_id` instead (see Rule 1 and Rule 7).
