---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 3
status: 0 critical, 0 warnings, 2 info
---

# Spec Compliance Report

## Changes since last run

- **Resolved**: all run-2 warnings resolved.
- **New**: `Dal/Poly.lean` added; A4 and A5 now `proved`.
- `Dal.Poly.interpolate_eval` and `Dal.Poly.interpolate_natDegree` cover A4.
- `Dal.Poly.poly_unique_of_eval` covers A5.

## Critical

None.

## Warnings

None.

## Info

### [I1] All remaining protocol properties A1–A3, A6, P1–P2, S1–S4 still `not started`
- **KB location**: `kb/properties.md`
- **Lean location**: missing
- **Issue**: Expected at this stage. Next module `Dal/KZG.lean` will cover A1–A3, A6.

### [I2] `cosetPoints` and `shardVals` defined in KB but not yet in Lean
- **KB location**: `kb/spec.md` § S4 helper functions
- **Lean location**: missing
- **Issue**: Expected. Will be addressed in `Dal/Sharding.lean`.

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem | Status |
|--------------------------|----------|--------------|--------|
| Field `𝔽_r` type | spec.md § Types | `Dal.Field.Fr` | proved |
| All deployment parameters & constraints | spec.md § Parameters | `Dal.Field.*` | axiom |
| `ω` primitive root | spec.md § Parameters | `Dal.Field.ω`, `Dal.Field.ω_isPrimitiveRoot` | axiom |
| `ω^n = 1` | spec.md § Parameters | `Dal.Field.ω_pow_n` | proved |
| `Poly` type | spec.md § Types | `Dal.Poly.Poly` | proved |
| `interpolate` function | spec.md § Functions | `Dal.Poly.interpolate` | proved |
| A4: Interpolation correctness | properties.md | `Dal.Poly.interpolate_eval`, `Dal.Poly.interpolate_natDegree` | proved |
| A5: Polynomial uniqueness | properties.md | `Dal.Poly.poly_unique_of_eval` | proved |
| A1: Eval soundness | properties.md | missing | not started |
| A2: Eval completeness | properties.md | missing | not started |
| A3: Degree soundness | properties.md | missing | not started |
| A6: Commitment binding | properties.md | missing | not started |
| P1: RS decoding succeeds | properties.md | missing | not started |
| P2: Page verification uniqueness | properties.md | missing | not started |
| S1: Serialization injectivity | properties.md | missing | not started |
| S2: Coset partition | properties.md | missing | not started |
| S3: Vanishing polynomial roots | properties.md | missing | not started |
| S4: Shard recovery (MDS) | properties.md | missing | not started |
