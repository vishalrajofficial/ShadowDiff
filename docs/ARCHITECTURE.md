# ShadowDiff: System Architecture Specification

## 1. Overview
ShadowDiff is a 3-way differential shadow testing proxy and automated regression synthesis engine designed for safe enterprise legacy migration verification.

---

## 2. The 3-Way Differential Architecture (Diffy Model)

To eliminate false positives caused by non-deterministic fields (timestamps, ephemeral tokens, dynamic UUIDs) without requiring brittle manual regex rules, ShadowDiff implements mathematical 3-way differential analysis:

```
                          [ Live Inbound Traffic ]
                                     │
                                     ▼
                      ┌─────────────────────────────┐
                      │    ShadowDiff Proxy Core    │
                      └───────┬──────┬──────┬───────┘
                              │      │      │
            ┌─────────────────┘      │      └─────────────────┐
            ▼                        ▼                        ▼
 ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
 │ Primary Instance A  │  │ Primary Instance B  │  │ Candidate Instance  │
 │  (Target Baseline)  │  │   (Twin Baseline)   │  │   (AI-Refactored)   │
 └──────────┬──────────┘  └──────────┬──────────┘  └──────────┬──────────┘
            │                        │                        │
            │   Primary Response     │    Twin Response       │    Shadow Response
            │         (P1)           │        (P2)            │         (S)
            └───────────┬────────────┴──────────┬─────────────┘
                        │                       │
                        ▼                       ▼
            ┌──────────────────────┐┌──────────────────────┐
            │   Noise Evaluator    ││   Candidate Diff     │
            │     N = P1 ⊕ P2      ││     R = P1 ⊕ S       │
            └───────────┬──────────┘└───────────┬──────────┘
                        │                       │
                        └───────────┬───────────┘
                                    ▼
                      ┌───────────────────────────┐
                      │    Noise Cancellation     │
                      │       D = R \ N           │
                      │  (Pure Semantic Drifts)   │
                      └─────────────┬─────────────┘
                                    │
                         (Pure Regressions Only)
                                    ▼
                      ┌───────────────────────────┐
                      │ Google Gemini Synthesizer │
                      │ - Root Cause Diagnosis    │
                      │ - Regression Test (Go/JS) │
                      │ - Code Fix Recommendation │
                      └───────────────────────────┘
```

### Mathematical Formulation
1. **Inherent Baseline Noise**:
   $$\mathcal{N} = P_1 \oplus P_2$$
   Any field diverging between identical twin baseline instances is guaranteed to be non-deterministic runtime noise.

2. **Raw Candidate Divergence**:
   $$\mathcal{R} = P_1 \oplus S$$

3. **Pure Semantic Regression**:
   $$\mathcal{D} = \mathcal{R} \setminus \mathcal{N}$$
   By subtracting the noise set $\mathcal{N}$ from candidate drifts $\mathcal{R}$, ShadowDiff guarantees zero false alarms. Only genuine contract regressions reach the AI test synthesizer.

---

## 3. Component Pipeline

### 3.1 Ingress Reverse Proxy
- Synchronous path: streams payload to Primary ($P_1$) and pipes response to client with zero added latency.
- Asynchronous path: clones request buffer and delivers concurrently to Primary Twin ($P_2$) and Shadow Candidate ($S$).
- Trace propagation: attaches `X-ShadowDiff-Trace-ID` for end-to-end telemetry correlation.

### 3.2 3-Way Differential Engine & Volatility Tracker
- AST-level JSON comparison for deep structure and key presence.
- Path volatility index ($0.0 \le V_p \le 1.0$) learning the dynamic entropy rate of endpoints over time.
- Status code, critical header, and latency percentile diffing (P50, P95, P99).

### 3.3 Autonomous Regression Test Synthesizer
- Triggered strictly when pure regressions ($\mathcal{D} > 0$) are isolated.
- Prompts Google Gemini (`gemini-2.0-flash`) to emit:
  - Unit/integration test scripts (Go `httptest`, Vitest/Jest).
  - Diagnostic breakdown explaining the runtime variance.
  - Recommended patch for the refactored codebase.

### 3.4 Developer UI & Telemetry
- Real-time side-by-side comparison across $P_1$, $P_2$, and $S$.
- Live metric counters for Noise Filtered vs Pure Regressions.
- One-click regression test copy and export.
