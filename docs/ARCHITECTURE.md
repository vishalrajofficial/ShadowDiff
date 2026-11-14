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
                        └───────────┬──────────┘
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

## 3. SQL Mutation & Database Side-Effect Diffing Engine

In enterprise monolith modernizations, an AI-refactored service may return an identical `200 OK` JSON response while introducing catastrophic silent database corruption. 

ShadowDiff implements a dedicated **SQL Mutation Interceptor & Comparator**:

```
 ┌─────────────────────────────────┐       ┌─────────────────────────────────┐
 │ Legacy Monolith (e.g. Java/PHP) │       │ AI-Refactored Service (Go/Node) │
 └────────────────┬────────────────┘       └────────────────┬────────────────┘
                  │ [SQL Executions]                        │ [SQL Executions]
                  ▼                                         ▼
      ┌───────────────────────┐                 ┌───────────────────────┐
      │  Legacy SQL Trace     │                 │   Shadow SQL Trace    │
      │  - BEGIN TRANSACTION  │                 │  - UPDATE inventory   │
      │  - UPDATE inventory   │                 │  - SELECT disc (x4)   │
      │  - INSERT audit_logs  │                 │    (Missing BEGIN!)   │
      │  - COMMIT             │                 │    (Missing Audit!)   │
      └───────────┬───────────┘                 └───────────┬───────────┘
                  │                                         │
                  └───────────────────┬─────────────────────┘
                                      ▼
                      ┌───────────────────────────────┐
                      │  SQL Mutation Diff Engine     │
                      │  - Missing Table Writes       │
                      │  - N+1 Query Explosion        │
                      │  - Transaction Boundary Check │
                      │  - Parameter Value Drift      │
                      └───────────────┬───────────────┘
                                      │
                           (Database Discrepancy)
                                      ▼
                      ┌───────────────────────────────┐
                      │  Google Gemini ORM Diagnosis  │
                      │  - Generates DB rollback test │
                      │  - Suggests @Transactional    │
                      │  - Emits eager loading patch  │
                      └───────────────────────────────┘
```

### Key Detection Capabilities
* **Missing Database Mutations (`MISSING_DB_MUTATION`)**: Flags when legacy writes to tables (e.g. `audit_logs`, `ledger_entries`) that the modern code forgot to mutate.
* **Transaction Boundary Leaks (`MISSING_TRANSACTION_BOUNDARY`)**: Detects when legacy code operated inside atomic `BEGIN...COMMIT` blocks, but refactored ORM code ran autocommit statements vulnerable to partial failures.
* **N+1 Query Explosion (`N_PLUS_ONE_QUERY_EXPLOSION`)**: Detects when refactored ORMs query relational tables in loops ($K \ge 3$ queries) instead of single joined batch queries.
* **Parameter Value Drift (`DB_PARAM_VALUE_DRIFT`)**: Compares bound SQL parameter values across matching statements.

---

## 4. Developer UI & Telemetry
- Real-time side-by-side comparison across $P_1$, $P_2$, and $S$.
- Visual SQL execution timeline with color-coded operation tags (`[INSERT]`, `[UPDATE]`, `[BEGIN]`).
- Automatic alerts for N+1 query patterns and missing mutations.
- One-click regression test copy and export.
