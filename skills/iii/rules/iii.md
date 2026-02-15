# iii Engine - Correction Rules

## Trigger Registration

The `registerTrigger` field for trigger kind is `trigger_type`, NOT `type`.

```typescript
// CORRECT
registerTrigger({
  trigger_type: "http",
  function_id: "service::handler",
  config: { api_path: "endpoint", http_method: "GET" },
});

// WRONG - will fail with "trigger_type_not_found"
registerTrigger({
  type: "http",  // <-- wrong field name
  function_id: "service::handler",
  config: { api_path: "endpoint", http_method: "GET" },
});
```

## ESM Required

Always set `"type": "module"` in `package.json`. The SDK uses ESM imports.

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
