---
auditor: ambiguity-auditor
date: 2026-03-24
run: 2
status: 0 critical, 4 warnings, 4 info
---

# Ambiguity Audit Report

## Changes since last run

- **Resolved**: none (W1–W4, I1–I3 from run 1 are still open)
- **New**: [W4-new] Deployment parameter placement decision not yet an ADR;
  [I4] `last-updated` frontmatter stale in modified KB files

---

## Critical

None.

---

## Warnings

### [W1] Undefined functions in S4 (shard recovery) — carried from run 1
- **Location**: `kb/properties.md`, property S4
- **Issue**: `coset_points_from`, `vals_from`, and related helper functions
  referenced in S4 are not defined in any KB file.
- **Recommendation**: Add precise definitions to `kb/spec.md` (under Sharding
  functions) before implementing `Dal/Sharding.lean`.

### [W2] Divisibility precondition `l ∣ k` for S4 not stated in Parameters — carried from run 1
- **Location**: `kb/properties.md`, property S4; `kb/spec.md` § Parameters
- **Issue**: `l ∣ k` is required by the S4 statement (`k / l` must be exact)
  but does not appear in the Parameters constraints table.
- **Recommendation**: Add `l ∣ k` to the parameter constraints in `kb/spec.md`.

### [W3] `page_length` / `pages_per_slot` referenced but not in Parameters table — carried from run 1
- **Location**: `kb/glossary.md` (Page entry)
- **Issue**: Page parameters are mentioned in the glossary but absent from the
  `kb/spec.md` Parameters table.
- **Recommendation**: Add them to the table with the out-of-scope note already
  in `kb/spec.md`, or remove the glossary reference.

### [W4] No ADR for "deployment parameters axiomatized in `Dal/Field.lean`"
- **Location**: `kb/architecture.md` § Implementation notes for `Dal/Field.lean`
- **Issue**: The decision to declare `r`, `n`, `n_pos`, `n_dvd_r_sub_one`, `ω`,
  and `ω_isPrimitiveRoot` as `axiom` (rather than `variable`) is documented in
  `kb/architecture.md` prose but has no entry in `kb/decisions/`. Without an ADR
  it is invisible to the decision index and may be re-litigated.
- **Recommendation**: Create `kb/decisions/003-field-parameters-as-axioms.md`
  capturing this choice and add it to `decisions/index.md`.

---

## Info

### [I1] `Dal/Basic.lean` stub not assigned to a module role — carried from run 1
- **Location**: `kb/architecture.md`
- **Issue**: `Dal/Basic.lean` (`def hello := "world"`) is still present and
  imported by `Dal.lean`. It has no role in the planned module structure.
- **Recommendation**: Remove or repurpose when `Dal/Field.lean` (now done) and
  `Dal/Poly.lean` are fully in place.

### [I2] Multi-reveal proof computation not covered in KB — carried from run 1
- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Issue**: Already tracked. No new action.

### [I3] `shardRemainder` / `proveShardEval` verification equation not precisely stated — carried from run 1
- **Location**: `kb/spec.md`, Sharding functions
- **Issue**: `verifyShardEval` references `r_i(τ)` where `r_i` is a named
  remainder function, but `shardRemainder` is defined only informally.
- **Recommendation**: Ensure `kb/spec.md` definition of `shardRemainder` is
  precise enough to uniquely determine the Lean function signature before
  implementing `Dal/Sharding.lean`.

### [I4] `last-updated` frontmatter not updated in modified KB files
- **Location**: `kb/gaps.md`, `kb/architecture.md`
- **Issue**: Both files were modified on 2026-03-24 but still carry
  `last-updated: 2026-03-23`. Minor compliance gap.
- **Recommendation**: Update frontmatter dates to 2026-03-24.
