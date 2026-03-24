---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 8
status: 1 warning, 1 info
---

# Spec Compliance Report

## Changes since last run

Two issues from run 7 are now resolved:

- **V1 resolved**: `kb/spec.md` § Parameters, Constraints has been updated to
  replace `slot_size = k * 31` with `slot_size ≤ k * 31`, including a prose note
  about the real Tezos deployment values (`slot_size = 380832`, `k = 12285`, last
  chunk is 28 bytes). The spec and `Dal/Serialization.lean` are now in agreement
  on this foundational constraint.
- **W1 resolved**: `kb/architecture.md` § Dal/Sharding.lean now uses `shardEval`
  (not `shard`), matching the Lean identifier `Dal.Sharding.shardEval`. The stale
  `shard : Poly → Fin s → Fin l → 𝔽_r` wording has been removed.

One new warning identified (W1) concerning a stale name in `gaps.md`. One info
item carried forward (I1).

---

## Warnings

### [W1] `gaps.md` G7 note references stale axiom name `slot_size_eq`

- **KB location**: `kb/gaps.md` § G7: Serialization injectivity, Note:
  "Two supporting axioms added: `slot_size_eq : slot_size = k * 31` and
  `bytes31_lt_r : 256^31 < r`."
- **Lean location**: `dal/Dal/Serialization.lean` lines 54–59: the axiom is
  `slot_size_le : slot_size ≤ k * 31`; `slot_size_eq` does not exist.
- **Issue**: The G7 note was not updated when the axiom was renamed and weakened.
  An agent consulting `gaps.md` to understand the serialization axioms would find
  a name (`slot_size_eq`) that does not exist in the codebase and an incorrect
  constraint (equality instead of inequality).
- **Action required**: Update `kb/gaps.md` G7 note to read:
  "Two supporting axioms added: `slot_size_le : slot_size ≤ k * 31` and
  `bytes31_lt_r : 256^31 < r`."

---

## Info

### [I1] P1, P2, S4 still `not started`; all other properties resolved

- **KB location**: `kb/properties.md`
- **Lean location**: missing (`Dal/Protocol.lean` and `Dal/ReedSolomon.lean` not
  yet written)
- **Status**: Expected at this stage. P1, P2, and S4 require modules not yet
  implemented. S1 (`serialize_injective`) and all A-series and S2/S3 properties
  are resolved.

---

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem/Def | Status |
|--------------------------|----------|------------------|--------|
| Field `𝔽_r` type | spec.md § Types | `Dal.Field.Fr` | proved |
| All deployment parameters & constraints | spec.md § Parameters | `Dal.Field.*` | axiom |
| `ω` primitive root | spec.md § Parameters | `Dal.Field.ω`, `ω_isPrimitiveRoot` | axiom |
| `Poly` type | spec.md § Types | `Dal.Poly.Poly` | proved |
| `interpolate` function | spec.md § Functions | `Dal.Poly.interpolate` | proved |
| A4: Interpolation correctness (eval) | properties.md | `Dal.Poly.interpolate_eval` | proved |
| A4: Interpolation correctness (degree) | properties.md | `Dal.Poly.interpolate_natDegree` | proved |
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
| `cosetPoint` function | spec.md § Sharding | `Dal.Sharding.cosetPoint` | proved |
| `Ω` (coset finset) | spec.md § Sharding, glossary.md | `Dal.Sharding.Ω` | proved |
| `Z` (vanishing polynomial) | spec.md § Sharding, glossary.md | `Dal.Sharding.Z` | proved |
| `shardEval` function | spec.md § Sharding | `Dal.Sharding.shardEval` | proved |
| S2: Coset partition (union) | properties.md | `Dal.Sharding.coset_partition` | proved |
| S2: Coset partition (disjoint) | properties.md | `Dal.Sharding.cosets_disjoint` | proved |
| S3: Vanishing polynomial roots | properties.md | `Dal.Sharding.vanishing_poly_roots` | proved |
| `Bytes` type | architecture.md § Serialization | `Dal.Serialization.Bytes` | proved |
| `slot_size ≤ k * 31` constraint | spec.md § Parameters | `Dal.Serialization.slot_size_le` | axiom |
| `256^31 < r` constraint | spec.md § Parameters | `Dal.Serialization.bytes31_lt_r` | axiom |
| `serialize` function | spec.md § Data flow | `Dal.Serialization.serialize` | proved |
| S1: Serialization injectivity | properties.md | `Dal.Serialization.serialize_injective` | proved |
| `shardRemainder` function | spec.md § Sharding | missing | not started |
| `proveShardEval` function | spec.md § Sharding | missing | not started |
| `verifyShardEval` function | spec.md § Sharding | missing | not started |
| `cosetPoints` helper | spec.md § S4 helpers | missing | not started |
| `shardVals` helper | spec.md § S4 helpers | missing | not started |
| `rsEncode` function | spec.md § Reed-Solomon | missing | not started |
| `rsDecode` function | spec.md § Reed-Solomon | missing | not started |
| P1: RS decoding succeeds | properties.md | missing | not started |
| P2: Page verification uniqueness | properties.md | missing | not started |
| S4: Shard recovery (MDS) | properties.md | missing | not started |
