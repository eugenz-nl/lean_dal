---
auditor: ambiguity-auditor
date: 2026-03-24
run: 6
status: 0 critical, 0 warnings, 2 info
---

# Ambiguity Audit Report

## Changes since last run

- Decision 001 inconsistency (A2 missing from "three axioms") resolved: decision
  updated, `properties.md` updated, note added in `architecture.md`.
- No new ambiguities introduced by `Dal/KZG.lean`.
- Info items I1 and I2 carry forward unchanged.

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
- **Action**: Pin the order in `kb/spec.md` when implementing `Dal/Sharding.lean`.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details
- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Issue**: Already tracked. No blocker for current work.
