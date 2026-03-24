---
auditor: ambiguity-auditor
date: 2026-03-23
run: 1
status: 0 critical, 4 warnings, 3 info (all resolved in same session)
---

# Ambiguity Audit Report

## Critical

None.

---

## Warnings

### [W1] Undefined functions in S4 (shard recovery)
- **Location**: `kb/properties.md`, property S4
- **Issue**: The statement uses `coset_point i j`, `samples_from_shards`, and
  `shard_val i j` which are not defined in any KB file. An agent cannot write a
  Lean statement for S4 without inventing these definitions.
- **Recommendation**: Add precise definitions to `kb/spec.md` (under Sharding
  functions) or replace the informal expressions with references to `shardEval`
  and `interpolate` which are already defined. The formal statement should read
  something like: "∀ I : Finset (Fin s), |I| = k / l → ∀ p, (∀ i ∈ I, ∀ j,
  shardEval p i j = vs i j) → p = interpolate (coset_points_from I) (vals_from I vs)"
  with `coset_points_from` formally specified.

### [W2] Divisibility precondition for S4 not stated
- **Location**: `kb/properties.md`, property S4
- **Issue**: S4 writes `k / l` without stating that `l | k`. If `l ∤ k`, the
  integer division is lossy and the statement may be false or vacuous.
- **Recommendation**: Add `l ∣ k` to the parameter constraints in `kb/spec.md`
  (Parameters table), or state it explicitly as a precondition of S4.

### [W3] `page_length` and `pages_per_slot` used but not defined as parameters
- **Location**: `kb/glossary.md` (Page entry)
- **Issue**: The Page glossary entry references `page_length` as a parameter, but
  it does not appear in the Parameters table in `kb/spec.md`.
- **Recommendation**: Either (a) add `page_length` and `pages_per_slot` to the
  Parameters table in `kb/spec.md` with the relationship `pages_per_slot = k /
  page_length`, or (b) note that pages are out of scope for the current
  formalization and update the glossary accordingly.

### [W4] Argument order inconsistency in source for `proveEval` / Spec 2
- **Location**: `kb/spec.md`, Spec 2 / `docs/protocol.md`
- **Issue**: In `docs/protocol.md`, the function signature lists `proveEval(P,X,Y)`
  (polynomial first) but Specification 2 writes `proveEval(x,y,p)∈Π` (polynomial
  last). The KB (`spec.md`) resolves this by using polynomial-first throughout, but
  the discrepancy means anyone reading the source doc alongside the KB will be
  confused.
- **Recommendation**: Add a note in `kb/spec.md` under A2 stating: "Note: the
  source document (`docs/protocol.md`, Spec 2) uses argument order `(x, y, p)`;
  this KB standardizes to `(p, x, y)` to match the function signature."

---

## Info

### [I1] `Dal/Basic.lean` stub not assigned to a module role
- **Location**: `kb/architecture.md`
- **Issue**: The file `dal/Dal/Basic.lean` currently exists with `def hello :=
  "world"` and is not mentioned in the module plan. It is imported by `Dal.lean`.
- **Recommendation**: Note in `kb/architecture.md` that `Basic.lean` should be
  removed or repurposed when actual modules are added. Low priority.

### [I2] Multi-reveal proof computation not covered in KB
- **Location**: `docs/protocol.md` §Multiple multi-reveals (lines 442–560)
- **Issue**: The efficient O((n/l) log(n/l)) algorithm for computing all shard
  proofs simultaneously has no KB coverage.
- **Recommendation**: Already noted in `kb/gaps.md` §"Areas not yet analyzed".
  No action needed unless proof generation is in scope.

### [I3] `proveShardEval` multi-reveal verification equation not stated precisely
- **Location**: `kb/spec.md`, Sharding functions
- **Issue**: `verifyShardEval` references `r_i(τ)` where `r_i` is the remainder of
  dividing `p` by `Z_i`. This remainder is not defined as a named function in the
  spec's Functions section.
- **Recommendation**: Add `remainder : P → Fin s → P` defined as `r_i(x) = p(x) -
  Z_i(x) * q_i(x)` (or equivalently: the unique polynomial of degree < l such that
  `p ≡ remainder p i (mod Z_i)`), and reference it in `verifyShardEval`.
