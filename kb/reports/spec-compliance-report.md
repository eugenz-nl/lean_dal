---
auditor: spec-compliance-auditor
date: 2026-03-25
run: 14
status: clean
---

# Spec Compliance Report

## Changes since last run

Since run 13, G13 was resolved: `deserialize`, `deserialize_left_inverse`, `d_succ_eq_k`,
`round_trip`, and `g13_round_trip` added. Coverage matrix updated.

Since run 12, G12 was also resolved: `verifyEval_complete` (A1c), `proveDegree_complete`
(A3c), and `verifyShardEval_complete` (A7c) added as axioms in `Dal/KZG.lean` and
re-exported from `Dal/Properties.lean`. Coverage matrix updated.

Since run 11, the following gaps were also resolved (carried forward):

- **G8 resolved** — `shardRemainder`, `proveShardEval`, `verifyShardEval` declared as
  axioms in `Dal/KZG.lean`. Coverage matrix updated.
- **G9 resolved** — `verifyShardEval_soundness` (A7) declared as axiom in `Dal/KZG.lean`.
  Coverage matrix updated.
- **G10 resolved** — `shard_verification_recovery` (P3) proved in `Dal/Protocol.lean`;
  re-exported as `p3_shard_verification_recovery` in `Dal/Properties.lean`.
- **G11 resolved** — `Dal/Serialization.lean` rewritten with interleaved page layout.
  `slot_size_le` is now a derived lemma (not an axiom). Page structure axioms added.
  Coverage matrix updated.

All previous warnings (W1–W7) remain resolved from run 11.

---

## Statement Compliance Review

### P3: `p3_shard_verification_recovery`

- **Spec** (`properties.md` §P3):
  ```
  verifyDegree c d π_deg = true
  → (∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true)
  → ∃! p, commit p = c
         ∧ (∀ i ∈ I, proveShardEval p i = πs i)
         ∧ (∀ i ∈ I, ∀ j, shardEval p i j = vs i j)
         ∧ interpolate (cosetPoints I hI) (shardVals I hI vs) = p
  ```
- **Lean** (`Dal/Properties.lean`): delegates to `Dal.Protocol.shard_verification_recovery`
  with matching signature.
- **Verdict**: Conformant.

### S1: `s1_serialize_injective` (updated for interleaved layout)

- **Spec** (`properties.md` §S1): `Function.Injective serialize`
- **Lean**: `Dal.Serialization.serialize_injective`; `serialize` now uses the
  interleaved page layout. S1 holds for the interleaved layout.
- **Verdict**: Conformant.

### A7: `verifyShardEval_soundness`

- **Spec** (`properties.md` §A7):
  `verifyShardEval c i vs π = true → ∃ p, commit p = c ∧ proveShardEval p i = π ∧ ∀ j, shardEval p i j = vs j`
- **Lean** (`Dal/KZG.lean`): declared as `axiom` with matching statement.
- **Verdict**: Conformant. No degree bound in A7 (review finding F4 — degree comes
  from an explicit `verifyDegree` hypothesis in P3, mirroring P1).

---

## Warnings

None.

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
| `shardRemainder` function | spec.md § Sharding | `Dal.KZG.shardRemainder` | axiom |
| `proveShardEval` function | spec.md § Sharding | `Dal.KZG.proveShardEval` | axiom |
| `verifyShardEval` function | spec.md § Sharding | `Dal.KZG.verifyShardEval` | axiom |
| A1: Eval soundness | properties.md | `Dal.KZG.verifyEval_soundness` | axiom |
| A2: Eval completeness | properties.md | `Dal.KZG.proveEval_complete` | axiom |
| A3: Degree soundness | properties.md | `Dal.KZG.verifyDegree_soundness` | axiom |
| A6: Commitment binding | properties.md | `Dal.KZG.commit_binding` | axiom |
| A1c: Eval completeness (verifier) | properties.md | `Dal.KZG.verifyEval_complete` | axiom |
| A3c: Degree completeness | properties.md | `Dal.KZG.proveDegree_complete` | axiom |
| A7: Shard eval soundness | properties.md | `Dal.KZG.verifyShardEval_soundness` | axiom |
| A7c: Shard eval completeness | properties.md | `Dal.KZG.verifyShardEval_complete` | axiom |
| `cosetPoint` function | spec.md § Sharding | `Dal.Sharding.cosetPoint` | proved |
| `Ω` (coset finset) | spec.md § Sharding | `Dal.Sharding.Ω` | proved |
| `Z` (vanishing polynomial) | spec.md § Sharding | `Dal.Sharding.Z` | proved |
| `shardEval` function | spec.md § Sharding | `Dal.Sharding.shardEval` | proved |
| S2: Coset partition (union) | properties.md | `Dal.Sharding.coset_partition` | proved |
| S2: Coset partition (disjoint) | properties.md | `Dal.Sharding.cosets_disjoint` | proved |
| S3: Vanishing polynomial roots | properties.md | `Dal.Sharding.vanishing_poly_roots` | proved |
| `Bytes` type | architecture.md § Serialization | `Dal.Serialization.Bytes` | proved |
| Page structure axioms | spec.md § Parameters | `Dal.Serialization.pages_per_slot` etc. | axiom |
| `256^31 < r` constraint | spec.md § Parameters | `Dal.Serialization.bytes31_lt_r` | axiom |
| `slot_size ≤ k * 31` | spec.md § Parameters | `Dal.Serialization.slot_size_le` | proved (derived) |
| `serialize` function | spec.md § Data flow | `Dal.Serialization.serialize` | proved |
| S1: Serialization injectivity | properties.md | `Dal.Serialization.serialize_injective` | proved |
| `rsEncode` function | spec.md § Reed-Solomon | `Dal.ReedSolomon.rsEncode` | proved |
| `cosetPoints` helper | spec.md § S4 helpers | `Dal.ReedSolomon.cosetPoints` | proved |
| `shardVals` helper | spec.md § S4 helpers | `Dal.ReedSolomon.shardVals` | proved |
| S4: Shard recovery (MDS) | properties.md | `Dal.ReedSolomon.shard_recovery` | proved |
| P2: Page verification uniqueness | properties.md | `Dal.Protocol.page_verification_unique` | proved |
| P1: RS decoding succeeds | properties.md | `Dal.Protocol.rs_decoding_succeeds` | proved |
| P3: Shard verification implies recovery | properties.md | `Dal.Protocol.shard_verification_recovery` | proved |
| S1 re-export | properties.md | `Dal.Properties.s1_serialize_injective` | proved |
| S2 re-export (union) | properties.md | `Dal.Properties.s2_coset_partition` | proved |
| S2 re-export (disjoint) | properties.md | `Dal.Properties.s2_cosets_disjoint` | proved |
| S3 re-export | properties.md | `Dal.Properties.s3_vanishing_poly_roots` | proved |
| S4 re-export | properties.md | `Dal.Properties.s4_shard_recovery` | proved |
| P2 re-export | properties.md | `Dal.Properties.p2_page_verification_unique` | proved |
| P1 re-export | properties.md | `Dal.Properties.p1_rs_decoding_succeeds` | proved |
| P3 re-export | properties.md | `Dal.Properties.p3_shard_verification_recovery` | proved |
| A1c re-export | properties.md | `Dal.Properties.a1c_verifyEval_complete` | axiom |
| A3c re-export | properties.md | `Dal.Properties.a3c_proveDegree_complete` | axiom |
| A7c re-export | properties.md | `Dal.Properties.a7c_verifyShardEval_complete` | axiom |
| `deserialize` function | gaps.md § G13 | `Dal.Serialization.deserialize` | proved |
| `deserialize_left_inverse` | gaps.md § G13 | `Dal.Serialization.deserialize_left_inverse` | proved |
| `d_succ_eq_k` | gaps.md § G13 | `Dal.Field.d_succ_eq_k` | proved |
| G13: End-to-end round-trip | gaps.md § G13 | `Dal.Protocol.round_trip` | proved |
| G13 re-export | gaps.md § G13 | `Dal.Properties.g13_round_trip` | proved |
| `rsDecode` function | spec.md § Reed-Solomon | — | not started (alias for `interpolate`; lower priority) |
