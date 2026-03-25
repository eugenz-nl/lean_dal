---
auditor: sorry-auditor
date: 2026-03-25
run: 13
status: clean
---

# Sorry Audit Report

## Changes since last run

G13 resolved: `deserialize` and `deserialize_left_inverse` added to
`Dal/Serialization.lean`; `d_succ_eq_k` added to `Dal/Field.lean`; `round_trip`
proved in `Dal/Protocol.lean`; re-exported as `g13_round_trip` in
`Dal/Properties.lean`. No `sorry` introduced.

KB obligation cross-check updated to include G13 entries.

## Summary

| File | Untracked | Tracked | Structural |
|------|-----------|---------|------------|
| `lean/Dal/Field.lean` | 0 | 0 | 0 |
| `lean/Dal/Poly.lean` | 0 | 0 | 0 |
| `lean/Dal/KZG.lean` | 0 | 0 | 0 |
| `lean/Dal/Sharding.lean` | 0 | 0 | 0 |
| `lean/Dal/Serialization.lean` | 0 | 0 | 0 |
| `lean/Dal/ReedSolomon.lean` | 0 | 0 | 0 |
| `lean/Dal/Protocol.lean` | 0 | 0 | 0 |
| `lean/Dal/Properties.lean` | 0 | 0 | 0 |
| `lean/Dal.lean` | 0 | 0 | 0 |
| **Total** | **0** | **0** | **0** |

## KB obligation cross-check

| KB entry | Lean target | Status |
|----------|-------------|--------|
| G2 — commit_binding (A6) | `Dal.KZG.commit_binding` | **resolved** (axiom) |
| G3 — verifyEval_soundness (A1) | `Dal.KZG.verifyEval_soundness` | **resolved** (axiom) |
| G4 — verifyDegree_soundness (A3) | `Dal.KZG.verifyDegree_soundness` | **resolved** (axiom) |
| A2 — proveEval_complete | `Dal.KZG.proveEval_complete` | **resolved** (axiom) |
| G5 — interpolate_eval (A4 eval) | `Dal.Poly.interpolate_eval` | **resolved** (proved) |
| G5 — interpolate_natDegree (A4 degree) | `Dal.Poly.interpolate_natDegree` | **resolved** (proved) |
| G6 — poly_unique_of_eval (A5) | `Dal.Poly.poly_unique_of_eval` | **resolved** (proved) |
| S2 — coset_partition (union) | `Dal.Sharding.coset_partition` | **resolved** (proved) |
| S2 — cosets_disjoint | `Dal.Sharding.cosets_disjoint` | **resolved** (proved) |
| S3 — vanishing_poly_roots | `Dal.Sharding.vanishing_poly_roots` | **resolved** (proved) |
| G7/G11 — serialize_injective (S1) | `Dal.Serialization.serialize_injective` | **resolved** (proved) |
| S4 — shard_recovery | `Dal.ReedSolomon.shard_recovery` | **resolved** (proved) |
| P1 — rs_decoding_succeeds | `Dal.Protocol.rs_decoding_succeeds` | **resolved** (proved) |
| P2 — page_verification_unique | `Dal.Protocol.page_verification_unique` | **resolved** (proved) |
| G8 — shardRemainder, proveShardEval, verifyShardEval | `Dal.KZG` | **resolved** (axioms) |
| G9 — verifyShardEval_soundness (A7) | `Dal.KZG.verifyShardEval_soundness` | **resolved** (axiom) |
| G10 — shard_verification_recovery (P3) | `Dal.Protocol.shard_verification_recovery` | **resolved** (proved) |
| S1 re-export | `Dal.Properties.s1_serialize_injective` | **resolved** |
| S2 re-export (union) | `Dal.Properties.s2_coset_partition` | **resolved** |
| S2 re-export (disjoint) | `Dal.Properties.s2_cosets_disjoint` | **resolved** |
| S3 re-export | `Dal.Properties.s3_vanishing_poly_roots` | **resolved** |
| S4 re-export | `Dal.Properties.s4_shard_recovery` | **resolved** |
| P2 re-export | `Dal.Properties.p2_page_verification_unique` | **resolved** |
| P1 re-export | `Dal.Properties.p1_rs_decoding_succeeds` | **resolved** |
| P3 re-export | `Dal.Properties.p3_shard_verification_recovery` | **resolved** |
| G12 — verifyEval_complete (A1c) | `Dal.KZG.verifyEval_complete` | **resolved** (axiom) |
| G12 — proveDegree_complete (A3c) | `Dal.KZG.proveDegree_complete` | **resolved** (axiom) |
| G12 — verifyShardEval_complete (A7c) | `Dal.KZG.verifyShardEval_complete` | **resolved** (axiom) |
| A1c re-export | `Dal.Properties.a1c_verifyEval_complete` | **resolved** |
| A3c re-export | `Dal.Properties.a3c_proveDegree_complete` | **resolved** |
| A7c re-export | `Dal.Properties.a7c_verifyShardEval_complete` | **resolved** |

| G13 — deserialize | `Dal.Serialization.deserialize` | **resolved** (defined) |
| G13 — deserialize_left_inverse | `Dal.Serialization.deserialize_left_inverse` | **resolved** (proved) |
| G13 — d_succ_eq_k | `Dal.Field.d_succ_eq_k` | **resolved** (proved) |
| G13 — round_trip | `Dal.Protocol.round_trip` | **resolved** (proved) |
| G13 — g13_round_trip re-export | `Dal.Properties.g13_round_trip` | **resolved** |

## Open KB obligations with no Lean counterpart

None. All gaps G1–G13 are resolved. The formalization is complete.

## Verdict

All clear. The formalization is sorry-free across all nine project files. All
theorems S1–S4, P1–P3, G13 (round-trip), and completeness axioms A1c, A3c, A7c
are exported from `Dal.Properties`. All gaps G1–G13 are resolved.
