# ShadowDiff: System Architecture Specification

## 1. Overview
ShadowDiff is a dual-traffic shadow testing proxy and automated regression synthesis engine designed for safe legacy migration verification.

## 2. Component Pipeline

### 2.1 Ingress Reverse Proxy
- Intercepts live incoming HTTP requests.
- Synchronous path: streams payload to Primary (legacy backend), returns response to caller without latency delay.
- Asynchronous path: clones request buffer and delivers to Shadow (modern refactored service).
- Trace propagation: attaches `X-ShadowDiff-Trace-ID` to correlate dual-traffic responses.

### 2.2 Response Normalizer & Sanitizer
- Strips non-deterministic fields: dynamic UUIDs, timestamps, session cookies.
- Configurable JSONPath ignore-rules and field masks.

### 2.3 Semantic Comparator
- AST-level JSON comparison for deep structure and key presence.
- Numerical tolerance comparison for floating-point values.
- Header and HTTP status code divergence check.
- Latency profiling: P50, P95, P99 percentile tracking.

### 2.4 Autonomous Regression Test Synthesizer
- Triggers when semantic drift is detected above threshold.
- Packages inbound request, expected legacy response, and modern service response.
- Prompts LLM to produce:
  - Unit/integration test scripts (Jest/Vitest, Go testing, Pytest).
  - Diagnostic breakdown explaining the runtime variance.
  - Recommended patch for the refactored codebase.

### 2.5 Developer UI & Telemetry
- Real-time side-by-side Monaco diff visualizer.
- Traffic throughput and drift rate metrics.
- One-click regression test export.
