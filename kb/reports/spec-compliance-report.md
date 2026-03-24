---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 1
status: 0 critical, 2 warnings, 2 info
---

# Spec Compliance Report

## Changes since last run

First run — no previous baseline. `Dal/Field.lean` is the only substantive Lean
file; all other modules are unstarted.

## Critical

None.

## Warnings

### [W1] Deployment parameters `k`, `s`, `l`, `α`, `slot_size`, `d` not yet axiomatized
- **KB location**: `kb/spec.md` § Parameters
- **Lean location**: missing
- **Issue**: `Dal/Field.lean` axiomatizes `r`, `n`, `n_pos`, `n_dvd_r_sub_one`.
  The remaining deployment parameters (`k`, `s`, `l`, `α`, `slot_size`, `d = k-1`)
  are referenced in `kb/spec.md` but have no Lean home yet. They are not needed by
  `Dal/Field.lean` itself, but they must be in scope before `Dal/Poly.lean`,
  `Dal/Sharding.lean`, and downstream modules can be written.
- **Recommendation**: Decide whether to axiomatize the remaining parameters in
  `Dal/Field.lean` (keeping all global constants in one place) or introduce them in
  the modules that first use them (`k` and `d` in `Dal/Poly.lean`; `s`, `l`, `α`
  in `Dal/Sharding.lean`). Document the choice as an ADR before implementing
  `Dal/Poly.lean`.

### [W2] Constraint `d ≥ 2l` not captured anywhere in Lean
- **KB location**: `kb/spec.md` § Parameters, Constraints
- **Lean location**: missing
- **Issue**: `kb/spec.md` states `d ≥ 2l` is required by the multi-reveal proof
  construction. No Lean axiom or hypothesis captures this constraint. If a theorem
  silently requires it, proofs will break non-obviously.
- **Recommendation**: Add `axiom d_ge_2l : d ≥ 2 * l` when `d` and `l` are
  axiomatized (likely in `Dal/Field.lean` or `Dal/Sharding.lean`).

## Info

### [I1] `Dal/Field.lean` fully complies with its scope
- **Lean location**: `dal/Dal/Field.lean`
- **Issue**: None — informational only.
- **Details**: `Fr` = `ZMod r` matches `kb/glossary.md` ("𝔽_r is modelled as
  `ZMod r`"). `ω` is declared with `IsPrimitiveRoot ω n`, which faithfully captures
  the KB definition ("primitive `n`-th root of unity, order exactly `n`"). The
  three derived theorems (`ω_pow_n`, `ω_orderOf`, `ω_pow_inj`) are correctly
  derived from `IsPrimitiveRoot` without `sorry`.

### [I2] No Lean theorem statements exist for A1–A6, P1–P2, S1–S4
- **KB location**: `kb/properties.md`
- **Lean location**: missing
- **Issue**: All protocol properties are `not started`. This is expected given
  that only `Dal/Field.lean` has been implemented. No action required now.

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem | Status |
|--------------------------|----------|--------------|--------|
| Field `𝔽_r` type | spec.md § Types | `Dal.Field.Fr` | proved |
| Parameter `r` (prime) | spec.md § Parameters | `Dal.Field.r`, `Dal.Field.r_prime` | axiom |
| Parameter `n` | spec.md § Parameters | `Dal.Field.n`, `Dal.Field.n_pos` | axiom |
| Constraint `n ∣ r-1` | spec.md § Parameters | `Dal.Field.n_dvd_r_sub_one` | axiom |
| `ω` primitive root | spec.md § Parameters | `Dal.Field.ω`, `Dal.Field.ω_isPrimitiveRoot` | axiom |
| `ω^n = 1` | spec.md § Parameters | `Dal.Field.ω_pow_n` | proved |
| Parameters `k`, `s`, `l`, `α`, `slot_size`, `d` | spec.md § Parameters | missing | not started |
| Constraint `d ≥ 2l` | spec.md § Parameters | missing | not started |
| A1: Eval soundness | properties.md | missing | not started |
| A2: Eval completeness | properties.md | missing | not started |
| A3: Degree soundness | properties.md | missing | not started |
| A4: Interpolation correctness | properties.md | missing | not started |
| A5: Polynomial uniqueness | properties.md | missing | not started |
| A6: Commitment binding | properties.md | missing | not started |
| P1: RS decoding succeeds | properties.md | missing | not started |
| P2: Page verification uniqueness | properties.md | missing | not started |
| S1: Serialization injectivity | properties.md | missing | not started |
| S2: Coset partition | properties.md | missing | not started |
| S3: Vanishing polynomial roots | properties.md | missing | not started |
| S4: Shard recovery (MDS) | properties.md | missing | not started |
