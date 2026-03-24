---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 2
status: 0 critical, 0 warnings, 2 info
---

# Spec Compliance Report

## Changes since last run

- **Resolved W1**: `k`, `s`, `l`, `α`, `slot_size`, `d` and all parameter
  constraints (`s_dvd_n`, `alpha_eq`, `d_eq`, `l_eq`, `alpha_ge_two`, `d_ge_2l`,
  `l_dvd_k`, `k_pos`, `s_pos`, `l_pos`) added to `Dal/Field.lean`.
- **Resolved W2**: constraint `d ≥ 2l` axiomatized as `Dal.Field.d_ge_2l`.
- **New I1**: `cosetPoints` / `shardVals` now defined in `kb/spec.md`; no Lean
  counterpart yet (expected — `Dal/Sharding.lean` is unstarted).

## Critical

None.

## Warnings

None.

## Info

### [I1] S4 helper functions defined in KB but not yet in Lean
- **KB location**: `kb/spec.md` § S4 helper functions
- **Lean location**: missing
- **Issue**: `cosetPoints` and `shardVals` are now precisely defined in
  `kb/spec.md`. No Lean implementation exists yet; `Dal/Sharding.lean` is
  unstarted. This is expected and tracked in `kb/gaps.md` G1.

### [I2] All protocol properties A1–A6, P1–P2, S1–S4 still `not started`
- **KB location**: `kb/properties.md`
- **Lean location**: missing
- **Issue**: Expected at this stage. Field.lean provides the foundation;
  subsequent modules will address these properties.

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem | Status |
|--------------------------|----------|--------------|--------|
| Field `𝔽_r` type | spec.md § Types | `Dal.Field.Fr` | proved |
| Parameter `r` (prime) | spec.md § Parameters | `Dal.Field.r`, `Dal.Field.r_prime` | axiom |
| Parameter `k` | spec.md § Parameters | `Dal.Field.k`, `Dal.Field.k_pos` | axiom |
| Parameter `n` | spec.md § Parameters | `Dal.Field.n`, `Dal.Field.n_pos` | axiom |
| Parameter `s` | spec.md § Parameters | `Dal.Field.s`, `Dal.Field.s_pos` | axiom |
| Parameter `l` | spec.md § Parameters | `Dal.Field.l`, `Dal.Field.l_pos` | axiom |
| Parameter `α` | spec.md § Parameters | `Dal.Field.α`, `Dal.Field.alpha_ge_two` | axiom |
| Parameter `slot_size` | spec.md § Parameters | `Dal.Field.slot_size` | axiom |
| Parameter `d` | spec.md § Parameters | `Dal.Field.d` | axiom |
| Constraint `n ∣ r-1` | spec.md § Parameters | `Dal.Field.n_dvd_r_sub_one` | axiom |
| Constraint `s ∣ n` | spec.md § Parameters | `Dal.Field.s_dvd_n` | axiom |
| Constraint `α = n/k` | spec.md § Parameters | `Dal.Field.alpha_eq` | axiom |
| Constraint `d = k-1` | spec.md § Parameters | `Dal.Field.d_eq` | axiom |
| Constraint `l = n/s` | spec.md § Parameters | `Dal.Field.l_eq` | axiom |
| Constraint `α ≥ 2` | spec.md § Parameters | `Dal.Field.alpha_ge_two` | axiom |
| Constraint `d ≥ 2l` | spec.md § Parameters | `Dal.Field.d_ge_2l` | axiom |
| Constraint `l ∣ k` | spec.md § Parameters | `Dal.Field.l_dvd_k` | axiom |
| `ω` primitive root | spec.md § Parameters | `Dal.Field.ω`, `Dal.Field.ω_isPrimitiveRoot` | axiom |
| `ω^n = 1` | spec.md § Parameters | `Dal.Field.ω_pow_n` | proved |
| `cosetPoints`, `shardVals` | spec.md § S4 helpers | missing | not started |
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
