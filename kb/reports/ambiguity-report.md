---
auditor: ambiguity-auditor
date: 2026-03-24
run: 4
status: 0 critical, 0 warnings, 2 info
---

# Ambiguity Audit Report

## Changes since last run

- **Resolved W1** (enumeration order): downgraded to info — the spec correctly
  defers the canonical order to implementation time and instructs that it be
  pinned when `Dal/Sharding.lean` is written. No blocker for current work.
- **Resolved I1**: `Dal/Basic.lean` deleted.
- Remaining info items: I2 (multi-reveal, tracked in gaps.md) and I3
  (shardRemainder / verifyShardEval — not a blocker until Sharding.lean).

---

## Critical

None.

---

## Warnings

None.

---

## Info

### [I1] Enumeration order of `cosetPoints` / `shardVals` deferred to implementation
- **Location**: `kb/spec.md` § S4 helper functions
- **Issue**: The canonical enumeration order is intentionally left as an
  implementation choice, to be fixed when `Dal/Sharding.lean` is started.
- **Action**: When implementing `Dal/Sharding.lean`, pin the order in `kb/spec.md`
  and re-run this auditor.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details
- **Location**: `kb/gaps.md` § "Areas not yet analyzed"; `kb/spec.md` § Sharding
- **Issue**: Both items already tracked. No blocker for current work
  (`Dal/Field.lean` and `Dal/Poly.lean` don't depend on them).
