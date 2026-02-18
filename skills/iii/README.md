# iii

Cross-language backend engine for service orchestration via WebSocket.

## Keywords

iii, iii-sdk, iii engine, iii-dev, cross-language rpc, service orchestration, function registry, websocket engine, microservice coordinator, cross-process function calls, polyglot backend, backend engine, kv server, bridge client, exec module, iii console, queue trigger, log trigger, @iii-dev/sdk, docker iiidev, prometheus metrics, stream triggers

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
- "type_not_found"
- "iii kv server"
- "iii queue trigger"
- "iii log trigger"
- "iii console"
- "iii docker"
- "iii bridge client"
- "iii exec module"
- "@iii-dev/sdk"
- "iii prometheus metrics"
- "iii stream join leave"

## Quick Start

```bash
# Install engine
curl -fsSL https://install.iii.dev/iii/main/install.sh | sh

# Start engine
iii -c iii-config.yaml

# Install Node SDK
npm install iii-sdk
```

## Key Features

- Register functions callable from any connected service
- Cross-language calls (TypeScript, Python, Rust)
- HTTP, cron, queue, and log triggers via engine modules
- Shared key-value state across services
- KV Server with file-based and in-memory backends
- Real-time durable streams with join/leave triggers
- Bridge Client for engine-to-engine mesh networking
- Full OpenTelemetry integration (traces, metrics, logs)
- Prometheus metrics endpoint (port 9464)
- iii Console web UI for engine inspection
- Docker deployment with iiidev/iii:latest
- Automatic reconnection with exponential backoff
- Docker Compose deployment pattern (dev + production)

## When to Use

- Building polyglot backends with services in multiple languages
- Orchestrating cross-service function calls
- Setting up iii engine with modules (API, state, streams, cron, queue, logging)
- Integrating iii-sdk into TypeScript/Python/Rust services
- Using iii Console to inspect engine state and connected workers
- Setting up KV Server, queue triggers, or log triggers
- Connecting multiple iii engines via Bridge Client mesh

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

**Errors prevented**: 7-field cron format, ESM module type, trigger field names (type vs trigger_type), engine path separators (:: vs dots), state call patterns, Docker networking, shutdown cleanup, KV Server index vs scope params, @iii-dev/sdk npm 404, module class path singular/plural ambiguity, queue/log trigger config
