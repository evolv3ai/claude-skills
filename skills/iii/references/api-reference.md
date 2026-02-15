# iii-sdk API Reference

> Full type definitions for `iii-sdk@0.1.0`

## Core SDK (`iii-sdk`)

### init()

```typescript
import { init, getContext } from "iii-sdk";

const sdk = init(address: string, options?: InitOptions);
// Returns: ISdk
```

### InitOptions

```typescript
type InitOptions = {
  workerName?: string;
  enableMetricsReporting?: boolean;
  invocationTimeoutMs?: number; // default: 30000
  reconnectionConfig?: Partial<IIIReconnectionConfig>;
  otel?: Omit<OtelConfig, 'engineWsUrl'>;
};

interface IIIReconnectionConfig {
  initialDelayMs: number;    // default: 1000
  maxDelayMs: number;        // default: 30000
  backoffMultiplier: number; // default: 2
  jitterFactor: number;      // default: 0.3
  maxRetries: number;        // default: -1 (infinite)
}
```

### ISdk Interface

```typescript
interface ISdk {
  registerFunction(func: RegisterFunctionInput, handler: RemoteFunctionHandler): FunctionRef;
  registerTrigger(trigger: RegisterTriggerInput): Trigger;
  registerTriggerType<TConfig>(triggerType: RegisterTriggerTypeInput, handler: TriggerHandler<TConfig>): void;
  unregisterTriggerType(triggerType: RegisterTriggerTypeInput): void;
  call<TInput, TOutput>(function_id: string, data: TInput): Promise<TOutput>;
  callVoid<TInput>(function_id: string, data: TInput): void;
  createStream<TData>(streamName: string, stream: IStream<TData>): void;
  onFunctionsAvailable(callback: FunctionsAvailableCallback): () => void;
  onLog(callback: LogCallback, config?: LogConfig): () => void;
  on(event: string, callback: (arg?: unknown) => void): void;
}
```

### Function Registration Types

```typescript
type RegisterFunctionInput = {
  id: string;
  description?: string;
  request_format?: RegisterFunctionFormat;
  response_format?: RegisterFunctionFormat;
  metadata?: Record<string, unknown>;
};

type RegisterFunctionFormat = {
  name: string;
  description?: string;
  type: 'string' | 'number' | 'boolean' | 'object' | 'array' | 'null' | 'map';
  body?: RegisterFunctionFormat[];
  items?: RegisterFunctionFormat;
  required?: boolean;
};

type FunctionRef = { id: string; unregister: () => void };
type RemoteFunctionHandler<TInput = any, TOutput = any> = (data: TInput) => Promise<TOutput>;
```

### Trigger Types

```typescript
type RegisterTriggerInput = {
  trigger_type: string;  // 'http', 'cron', 'event', or custom
  function_id: string;
  config: any;
};

// HTTP trigger config
{ api_path: string; http_method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'OPTIONS' }

// Cron trigger config (7 fields - seconds included)
{ expression: string }  // e.g. "*/30 * * * * * *"

type Trigger = { unregister(): void };
```

### Custom Trigger Types

```typescript
type RegisterTriggerTypeInput = { id: string; description: string };

type TriggerConfig<TConfig> = {
  id: string;
  function_id: string;
  config: TConfig;
};

type TriggerHandler<TConfig> = {
  registerTrigger(config: TriggerConfig<TConfig>): Promise<void>;
  unregisterTrigger(config: TriggerConfig<TConfig>): Promise<void>;
};
```

### Context & Logger

```typescript
type Context = { logger: Logger; trace?: Span };

declare const getContext: () => Context;
declare const withContext: <T>(fn: (context: Context) => Promise<T>, ctx: Context) => Promise<T>;

declare class Logger {
  info(message: string, data?: any): void;
  warn(message: string, data?: any): void;
  error(message: string, data?: any): void;
  debug(message: string, data?: any): void;
}
```

### API Request/Response

```typescript
type ApiRequest<TBody = unknown> = {
  path_params: Record<string, string>;
  query_params: Record<string, string | string[]>;
  body: TBody;
  headers: Record<string, string | string[]>;
  method: string;
};

type ApiResponse<TStatus extends number = number, TBody = string | Buffer | Record<string, unknown>> = {
  status_code: TStatus;
  headers?: Record<string, string>;
  body: TBody;
};
```

### Event & Worker Types

```typescript
type FunctionInfo = {
  function_id: string;
  description?: string;
  request_format?: RegisterFunctionFormat;
  response_format?: RegisterFunctionFormat;
  metadata?: Record<string, unknown>;
};

type WorkerInfo = {
  id: string;
  name?: string;
  runtime?: string;
  version?: string;
  os?: string;
  ip_address?: string;
  status: WorkerStatus;
  connected_at_ms: number;
  function_count: number;
  functions: string[];
  active_invocations: number;
};

type WorkerStatus = 'connected' | 'available' | 'busy' | 'disconnected';
type IIIConnectionState = 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'failed';
```

### Engine Constants

```typescript
const EngineFunctions = {
  LIST_FUNCTIONS: "engine.functions.list",
  LIST_WORKERS: "engine.workers.list",
  REGISTER_WORKER: "engine.workers.register",
};

const DEFAULT_INVOCATION_TIMEOUT_MS = 30000;
```

---

## State Module (`iii-sdk/state`)

```typescript
interface IState {
  get<TData>(input: { scope: string; key: string }): Promise<TData | null>;
  set<TData>(input: { scope: string; key: string; data: any }): Promise<{ old_value?: TData; new_value: TData } | null>;
  delete(input: { scope: string; key: string }): Promise<{ old_value?: any }>;
  list<TData>(input: { scope: string }): Promise<TData[]>;
  update<TData>(input: { scope: string; key: string; ops: UpdateOp[] }): Promise<{ old_value?: TData; new_value: TData } | null>;
}

declare enum StateEventType {
  Created = "state:created",
  Updated = "state:updated",
  Deleted = "state:deleted",
}
```

---

## Stream Module (`iii-sdk/stream`)

```typescript
interface IStream<TData> {
  get(input: { stream_name: string; group_id: string; item_id: string }): Promise<TData | null>;
  set(input: { stream_name: string; group_id: string; item_id: string; data: any }): Promise<{ old_value?: TData; new_value: TData } | null>;
  delete(input: { stream_name: string; group_id: string; item_id: string }): Promise<{ old_value?: any }>;
  list(input: { stream_name: string; group_id: string }): Promise<TData[]>;
  listGroups(input: { stream_name: string }): Promise<string[]>;
  update(input: { stream_name: string; group_id: string; item_id: string; ops: UpdateOp[] }): Promise<{ old_value?: TData; new_value: TData } | null>;
}
```

### Update Operations (shared by State and Stream)

```typescript
type UpdateOp =
  | { type: 'set'; path: string; value: any }
  | { type: 'increment'; path: string; by: number }
  | { type: 'decrement'; path: string; by: number }
  | { type: 'remove'; path: string }
  | { type: 'merge'; path: string; value: any };
```

### Stream Auth & Join

```typescript
interface StreamAuthInput {
  headers: Record<string, string>;
  path: string;
  query_params: Record<string, string[]>;
  addr: string;
}

interface StreamAuthResult { context?: any }
interface StreamJoinLeaveEvent {
  subscription_id: string;
  stream_name: string;
  group_id: string;
  id?: string;
  context?: any;
}
interface StreamJoinResult { unauthorized: boolean }
```

---

## Telemetry Module (`iii-sdk/telemetry`)

### Init & Shutdown

```typescript
declare function initOtel(config?: OtelConfig): void;
declare function shutdownOtel(): Promise<void>;

interface OtelConfig {
  enabled?: boolean;
  serviceName?: string;
  serviceVersion?: string;
  serviceNamespace?: string;
  serviceInstanceId?: string;
  engineWsUrl?: string;
  instrumentations?: Instrumentation[];
  metricsEnabled?: boolean;
  metricsExportIntervalMs?: number; // default: 60000
  reconnectionConfig?: Partial<ReconnectionConfig>;
}
```

### Tracing

```typescript
declare function getTracer(): Tracer | null;
declare function withSpan<T>(name: string, options: { kind?: SpanKind; traceparent?: string }, fn: (span: Span) => Promise<T>): Promise<T>;
```

### Metrics

```typescript
declare function getMeter(): Meter | null;
declare function registerWorkerGauges(meter: Meter, options: { workerId: string; workerName?: string }): void;
declare function stopWorkerGauges(): void;
```

### W3C Trace Context Propagation

```typescript
declare function injectTraceparent(): string | undefined;
declare function extractTraceparent(traceparent: string): Context;
declare function injectBaggage(): string | undefined;
declare function extractBaggage(baggage: string): Context;
declare function currentTraceId(): string | undefined;
declare function currentSpanId(): string | undefined;
declare function getBaggageEntry(key: string): string | undefined;
declare function setBaggageEntry(key: string, value: string): Context;
```

### Log Events

```typescript
type OtelLogEvent = {
  timestamp_unix_nano: number;
  observed_timestamp_unix_nano: number;
  severity_number: number;
  severity_text: string;
  body: string;
  attributes: Record<string, unknown>;
  trace_id?: string;
  span_id?: string;
  resource: Record<string, string>;
  service_name: string;
};

type LogSeverityLevel = 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal' | 'all';
type LogConfig = { level?: LogSeverityLevel };
```

### Worker Metrics Collector

```typescript
declare class WorkerMetricsCollector {
  constructor(options?: { eventLoopResolutionMs?: number });
  collect(): WorkerMetrics;
  stopMonitoring(): void;
}

type WorkerMetrics = {
  memory_heap_used?: number;
  memory_heap_total?: number;
  memory_rss?: number;
  memory_external?: number;
  cpu_user_micros?: number;
  cpu_system_micros?: number;
  cpu_percent?: number;
  event_loop_lag_ms?: number;
  uptime_seconds?: number;
  timestamp_ms: number;
  runtime: string;
};
```
