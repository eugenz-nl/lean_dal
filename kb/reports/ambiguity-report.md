---
auditor: ambiguity-auditor
date: 2026-03-24
run: 7
status: 0 critical, 3 warnings, 2 info
---

# Ambiguity Audit Report

## Changes since last run

- `Dal/Sharding.lean` has been implemented since run 6. It provides `cosetPoint`,
  `Ω`, `Z`, `shardEval`, `s_mul_l_eq_n`, `ωs_isPrimitiveRoot`, and proves S2
  (`coset_partition`, `cosets_disjoint`) and S3 (`vanishing_poly_roots`) without
  `sorry`. All zero-sorry.
- Three new warnings raised: architecture.md "current state" section is stale
  (still says Sharding is unstarted); gaps.md G1 "Next task" pointer is stale;
  properties.md S2/S3 status fields still read `not started` instead of `proved`.
- Info item I1 (enumeration order of `cosetPoints`/`shardVals`) still open —
  Sharding.lean does not define these helpers; they belong in a future module.
- Info item I2 carries forward unchanged.

---

## Critical

None.

---

## Warnings

### [W1] `architecture.md` "Current state" section names Sharding as unstarted

- **KB location**: `kb/architecture.md` § "Current state" (line 19)
- **Actual text**: "Dal/Field.lean, Dal/Poly.lean, and Dal/KZG.lean are implemented
  and build clean. All other modules are unstarted."
- **Reality**: `Dal/Sharding.lean` is fully implemented with S2 and S3 proved.
- **Action required**: Update the sentence to include `Dal/Sharding.lean` in the
  list of implemented modules.

### [W2] `architecture.md` Dal/Sharding.lean responsibility lists `shard` instead of `shardEval`

- **KB location**: `kb/architecture.md` § Dal/Sharding.lean (module responsibility
  bullet: "Defines `shard : Poly → Fin s → Fin l → 𝔽_r` as `eval p (coset_point i j)`.")
- **Authoritative source**: `kb/spec.md` § Sharding and `kb/glossary.md` both call
  this function `shardEval`. The Lean implementation uses `shardEval` correctly.
- **Ambiguity risk**: A future reader of `architecture.md` could introduce a
  duplicate definition under the wrong name `shard`.
- **Action required**: Replace `shard` with `shardEval` and `coset_point` with
  `cosetPoint` in the `Dal/Sharding.lean` responsibility paragraph in
  `architecture.md`. (Also flagged as W1 in spec-compliance-report.md run 5.)

### [W3] `properties.md` S2 and S3 status fields not updated after Sharding implementation

- **KB location**: `kb/properties.md` §S2 and §S3
- **Actual text**: both read `**Status**: \`not started\``
- **Reality**: `Dal.Sharding.coset_partition`, `Dal.Sharding.cosets_disjoint` (S2),
  and `Dal.Sharding.vanishing_poly_roots` (S3) are all proved without `sorry`.
- **Action required**: Update S2 status to `proved` (two theorems:
  `Dal.Sharding.coset_partition` and `Dal.Sharding.cosets_disjoint`) and S3 status
  to `proved` (`Dal.Sharding.vanishing_poly_roots`). Also update the Lean target
  fields for S2 to name both theorems.

---

## Info

### [I1] Enumeration order of `cosetPoints` / `shardVals` deferred to implementation

- **Location**: `kb/spec.md` § S4 helper functions
- **Status**: Still open. `Dal/Sharding.lean` does not define `cosetPoints` or
  `shardVals`; those belong to a future `Dal/Protocol.lean` or
  `Dal/ReedSolomon.lean`. The spec defers the enumeration order to implementation.
- **Action**: Pin the order in `kb/spec.md` when that module is implemented.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details

- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Issue**: Already tracked. No blocker for current work.
