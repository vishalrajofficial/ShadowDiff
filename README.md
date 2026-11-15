# 🌗 ShadowDiff

### Dual-Traffic Shadow Testing Engine for AI-Refactored Legacy Code

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go)](https://golang.org)
[![Envoy Proxy](https://img.shields.io/badge/Envoy-v1.30+-purple?logo=envoyproxy)](https://www.envoyproxy.io)
[![Fly.io](https://img.shields.io/badge/Deploy-Fly.io-7856FF?logo=flydotio)](https://fly.io)
[![Status](https://img.shields.io/badge/Status-Active_Development-brightgreen.svg)]()

> **Eliminating the 5% risk that stops enterprise CTOs from deploying AI-modernized backends to production.**

---

## ⚡ The Problem

Enterprises are actively modernizing mission-critical legacy backends (Java 7/8 Spring monoliths, Python 2 Django, PHP 5.6 backends) into modern cloud-native services (Go, TypeScript/Node, FastAPI) using AI code migration engines.

While AI generates ~95% of refactored code accurately, **the remaining 5% of hidden edge cases make production deployment an unacceptable risk**:
* **Subtle Serialization Discrepancies**: Jackson omitting empty lists vs Go serializing `null`, datetime timezone truncations, float precision drift.
* **Implicit Framework Quirks**: Legacy servlet filter quirks, undocumented fallback headers, HTTP 200 responses with embedded error payloads.
* **Database State Regressions**: Silent differences in database transaction boundaries, missing audit writes, or N+1 query loop explosions.

---

## 💡 The Solution: ShadowDiff

**ShadowDiff** is a high-performance network proxy and analysis engine that duplicates real staging or production HTTP traffic, sending identical payloads to both the legacy service and the AI-refactored service simultaneously.

```
                           [ Live Inbound Traffic ]
                                      │
                                      ▼
                       ┌─────────────────────────────┐
                       │    Envoy Gateway / Mesh     │
                       │  (request_mirror_policies)  │
                       └──────────────┬──────────────┘
                                      │
                  ┌───────────────────┴───────────────────┐
                  ▼                                       ▼
        ┌───────────────────┐                   ┌───────────────────┐
        │  Legacy Service   │                   │  ShadowDiff Core  │
        │     (Target)      │                   │  (Analysis Engine)│
        └─────────┬─────────┘                   └─────────┬─────────┘
                  │                                       │
                  │ (Live Response to Client)             ▼
                  │                             ┌───────────────────┐
                  │                             │   AI-Refactored   │
                  │                             │   Candidate (S)   │
                  │                             └─────────┬─────────┘
                  │                                       │
                  └───────────────────┬───────────────────┘
                                      ▼
                       ┌─────────────────────────────┐
                       │ 3-Way Diff & SQL Comparator │
                       │ - P1 ⊕ P2 Noise Filter      │
                       │ - SQL Mutation Interceptor  │
                       │ - N+1 Query Loop Detector   │
                       └──────────────┬──────────────┘
                                      │
                         (Pure Regressions Isolated)
                                      ▼
                       ┌─────────────────────────────┐
                       │ Automated AI Test Generator │
                       │ - Powered by Google Gemini  │
                       │ - Synthesizes Go/Jest Tests │
                       │ - Root Cause Code Fixes     │
                       └─────────────────────────────┘
```

---

## 🚀 Key Architectural Capabilities

### 1. ⚡ Network-Level Envoy Traffic Mirroring
ShadowDiff integrates directly with **Envoy Proxy** and **Istio Service Mesh** using `request_mirror_policies`. Traffic is cloned asynchronously at line rate in the network layer with **zero application latency penalty**.

### 2. 🎯 3-Way Differential Noise Cancellation (Diffy Model)
Automatically filters out non-deterministic runtime noise (timestamps, UUIDs, session nonces) by evaluating twin baseline instances:
$$\mathcal{N} = P_1 \oplus P_2$$
$$\mathcal{D} = (P_1 \oplus S) \setminus \mathcal{N}$$
Only verified contract regressions reach developer triage.

### 3. 💾 Database Mutation & SQL Side-Effect Diffing
Captures and correlates SQL statements executed by both services for each HTTP trace:
* **Missing Writes**: Flags when legacy wrote to `audit_logs` or ledger tables that modern code omitted.
* **Transaction Leaks**: Warns if legacy used `BEGIN...COMMIT` and modern ran autocommit statements.
* **N+1 Query Explosions**: Detects when modern ORMs loop and execute $\ge 3\times$ more queries than legacy.

### 4. 🤖 Google Gemini Regression Test Synthesis
Every isolated edge case is analyzed by **Google Gemini** (`gemini-2.0-flash`), which writes a turnkey integration test (Go `httptest` or Vitest) and diagnoses the code fix.

### 5. 🐙 Autonomous Closed-Loop GitHub PR Bot
Eliminates manual triaging by directly integrating with the GitHub API:
* **Automatic Branching**: Spins up `shadowdiff/fix-<trace_id>` from the repository's default branch.
* **Test File Commitment**: Automatically commits the synthesized regression test directly to the repository (e.g. `tests/regression/test_drift_<trace_id>.go`).
* **Rich Pull Request Generation**: Opens a detailed PR with side-by-side JSON diff tables, SQL mutation waterfall analysis, N+1 query warnings, and local verification commands.
* **1-Click Triage in Console**: Developers can inspect the incident in the web console and click **"🚀 Open GitHub PR"** to immediately open the PR on GitHub.

---

## 🛠️ Quickstart with Envoy & Docker Compose

Launch the complete 5-container service mesh testbed (Envoy Gateway + ShadowDiff + Legacy Target + Twin Replica + AI Candidate):

```bash
# 1. Clone the repository
git clone https://github.com/vishalrajofficial/ShadowDiff.git
cd ShadowDiff

# 2. Launch the Envoy Service Mesh topology
docker compose -f docker-compose.envoy.yml up -d
```

### Send Ingress Traffic Through Envoy (Port 10000):
```bash
# Send test traffic to the Envoy Gateway (mirrored to ShadowDiff automatically):
curl http://localhost:10000/api/users/1
curl -X POST http://localhost:10000/api/orders
```

Open the telemetry dashboard at **`http://localhost:8083`** to inspect the live 3-way diffs, SQL mutation timeline, and Gemini-generated tests!

---

## ☸️ Kubernetes & Istio Service Mesh Deployment

For production Kubernetes clusters running Istio or native Envoy, deploy the included `EnvoyFilter` to mirror traffic dynamically:

```bash
kubectl apply -f deploy/k8s/envoy-shadow-sidecar.yaml
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full architectural specifications.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
