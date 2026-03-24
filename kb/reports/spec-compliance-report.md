---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 4
status: 0 critical, 0 warnings, 2 info
---

# Spec Compliance Report

## Changes since last run

- **Resolved**: A1–A3, A6 now declared as axioms in `Dal/KZG.lean`.
- **New coverage**: `G1`, `G2`, `GT`, `Commitment`, `KZGProof`, `commit`,
  `proveEval`, `verifyEval`, `proveDegree`, `verifyDegree` all added.
- `kb/properties.md` updated: A1–A3, A6 → `axiom (declared)`.

## Critical

None.

## Warnings

None.

## Info

### [I1] P1, P2, and S1–S4 still `not started`
- **KB location**: `kb/properties.md`
- **Lean location**: missing
- **Issue**: Expected. P1/P2 require `Dal/Protocol.lean`; S1–S4 require
  `Dal/Sharding.lean`, `Dal/Serialization.lean`, and `Dal/ReedSolomon.lean`.

### [I2] `cosetPoints` / `shardVals` and sharding functions not yet in Lean
- **KB location**: `kb/spec.md` § Sharding / § S4 helper functions
- **Issue**: Expected. Next module is `Dal/Sharding.lean`.

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem | Status |
|--------------------------|----------|--------------|--------|
| Field `𝔽_r` type | spec.md § Types | `Dal.Field.Fr` | proved |
| All deployment parameters & constraints | spec.md § Parameters | `Dal.Field.*` | axiom |
| `ω` primitive root | spec.md § Parameters | `Dal.Field.ω`, `ω_isPrimitiveRoot` | axiom |
| `Poly` type | spec.md § Types | `Dal.Poly.Poly` | proved |
| `interpolate` function | spec.md § Functions | `Dal.Poly.interpolate` | proved |
| A4: Interpolation correctness | properties.md | `Dal.Poly.interpolate_eval`, `interpolate_natDegree` | proved |
| A5: Polynomial uniqueness | properties.md | `Dal.Poly.poly_unique_of_eval` | proved |
| `G1`, `G2`, `GT` types | spec.md § Types | `Dal.KZG.G1/G2/GT` | axiom |
| `commit` function | spec.md § Functions | `Dal.KZG.commit` | axiom |
| `proveEval` function | spec.md § Functions | `Dal.KZG.proveEval` | axiom |
| `verifyEval` function | spec.md § Functions | `Dal.KZG.verifyEval` | axiom |
| `proveDegree` function | spec.md § Functions | `Dal.KZG.proveDegree` | axiom |
| `verifyDegree` function | spec.md § Functions | `Dal.KZG.verifyDegree` | axiom |
| A1: Eval soundness | properties.md | `Dal.KZG.verifyEval_soundness` | axiom |
| A2: Eval completeness | properties.md | `Dal.KZG.proveEval_complete` | axiom |
| A3: Degree soundness | properties.md | `Dal.KZG.verifyDegree_soundness` | axiom |
| A6: Commitment binding | properties.md | `Dal.KZG.commit_binding` | axiom |
| P1: RS decoding succeeds | properties.md | missing | not started |
| P2: Page verification uniqueness | properties.md | missing | not started |
| S1: Serialization injectivity | properties.md | missing | not started |
| S2: Coset partition | properties.md | missing | not started |
| S3: Vanishing polynomial roots | properties.md | missing | not started |
| S4: Shard recovery (MDS) | properties.md | missing | not started |
