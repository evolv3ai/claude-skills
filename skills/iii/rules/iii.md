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
