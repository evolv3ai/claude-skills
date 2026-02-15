# iii

Cross-language backend engine for service orchestration via WebSocket.

## Keywords

iii, iii-sdk, iii engine, iii-dev, cross-language rpc, service orchestration, function registry, websocket engine, microservice coordinator, cross-process function calls, polyglot backend, backend engine

## Triggers

- "set up iii engine"
- "iii sdk"
- "iii-sdk"
- "cross-language function calls"
- "register function iii"
- "iii service orchestration"
- "iii config yaml"
- "connect to iii engine"
- "iii cron trigger"
- "iii http trigger"
- "iii state management"
- "iii streams"
- "ECONNREFUSED 49134"
- "port 49134"

## Quick Start

```bash
# Install engine
curl -fsSL https://install.iii.dev/latest.sh | sh

# Start engine
iii -c iii-config.yaml

# Install Node SDK
npm install iii-sdk
```

## Key Features

- Register functions callable from any connected service
- Cross-language calls (TypeScript, Python, Rust)
- HTTP and cron triggers via engine modules
- Shared key-value state across services
- Real-time durable streams
- Full OpenTelemetry integration (traces, metrics, logs)
- Automatic reconnection with exponential backoff
- Docker Compose deployment pattern

## When to Use

- Building polyglot backends with services in multiple languages
- Orchestrating cross-service function calls
- Setting up iii engine with modules (API, state, streams, cron)
- Integrating iii-sdk into TypeScript/Python/Rust services

## When NOT to Use

- Building single-language monoliths (no cross-service need)
- Serverless platforms (iii needs a running engine process)
- Simple REST APIs (overkill for single-service apps)

## Token Efficiency

| Scenario | Without Skill | With Skill | Savings |
|----------|---------------|------------|---------|
| Engine + service setup | ~12k tokens | ~4k tokens | ~67% |
| Cross-language integration | ~15k tokens | ~5k tokens | ~67% |
| State + triggers config | ~8k tokens | ~3k tokens | ~63% |

**Errors prevented**: 7-field cron format, ESM module type, trigger field names, state call patterns, Docker networking
