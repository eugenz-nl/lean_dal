---
auditor: sorry-auditor
date: 2026-03-25
run: 12
status: clean
---

# Sorry Audit Report

## Changes since last run

`Dal/KZG.lean` gained three completeness axioms (G12 resolved): `verifyEval_complete`
(A1c), `proveDegree_complete` (A3c), `verifyShardEval_complete` (A7c). These are
declared as `axiom`; no `sorry` introduced. `Dal/Properties.lean` re-exports them
as `a1c_verifyEval_complete`, `a3c_proveDegree_complete`, `a7c_verifyShardEval_complete`.

KB obligation cross-check updated to include G12 entries.

## Summary

| File | Untracked | Tracked | Structural |
|------|-----------|---------|------------|
| `dal/Dal/Field.lean` | 0 | 0 | 0 |
| `dal/Dal/Poly.lean` | 0 | 0 | 0 |
| `dal/Dal/KZG.lean` | 0 | 0 | 0 |
| `dal/Dal/Sharding.lean` | 0 | 0 | 0 |
| `dal/Dal/Serialization.lean` | 0 | 0 | 0 |
| `dal/Dal/ReedSolomon.lean` | 0 | 0 | 0 |
| `dal/Dal/Protocol.lean` | 0 | 0 | 0 |
| `dal/Dal/Properties.lean` | 0 | 0 | 0 |
| `dal/Dal.lean` | 0 | 0 | 0 |
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

## Open KB obligations with no Lean counterpart

G13 (end-to-end round-trip theorem) remains unstarted. Tracked in `kb/gaps.md`.

## Verdict

All clear. The formalization is sorry-free across all nine project files. All main
theorems S1–S4, P1–P3 and completeness axioms A1c, A3c, A7c are exported from
`Dal.Properties`. No open sorry obligations remain. Only G13 (round-trip) is
unstarted.
