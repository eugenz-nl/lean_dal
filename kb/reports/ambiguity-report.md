---
auditor: ambiguity-auditor
date: 2026-03-25
run: 16
status: clean
---

# Ambiguity Audit Report

## Changes since last run

Since run 15, G13 was resolved: `deserialize`, `deserialize_left_inverse`, `d_succ_eq_k`,
`round_trip`, and `g13_round_trip` proved/defined. All gaps now resolved.

Since run 14, G12 was also resolved: A1c, A3c, A7c completeness axioms added to
`Dal/KZG.lean` and re-exported from `Dal/Properties.lean`. `kb/properties.md`
and `kb/gaps.md` updated accordingly. Consistency checks pass.

Since run 13, the following items were also resolved (carried forward):

- **I1 resolved** — `kb/gaps.md` G1 "Remaining" updated: `Dal/Properties.lean` moved
  from stub to completed, `p3_shard_verification_recovery` added. No stale description.
- **I2 resolved** — `shardRemainder`, `proveShardEval`, `verifyShardEval` are now
  declared as axioms in `Dal/KZG.lean` (gap G8 resolved). Multi-reveal functions
  are formalized.
- **G8/G9/G10/G11 resolved** — all four gaps completed since run 13.
- **architecture.md updated** — `Dal/Serialization.lean` module description now reflects
  the interleaved layout (G11); `Dal/Protocol.lean` now lists P3; `Dal/Properties.lean`
  now lists S1–S4, P1–P3. Implementation notes updated.

---

## Warnings

None.

---

## Info

### [I1] `rsDecode` not declared in Lean

- **Spec**: `spec.md` lists `rsDecode : (Fin (d+1) → X) → (Fin (d+1) → Y) → P` as an
  alias for `interpolate`.
- **Reality**: No `rsDecode` identifier exists in the Lean code. `interpolate` is used
  directly in P1.
- **Impact**: Very low. `rsDecode` is purely an alias; its absence creates no gap in
  correctness. Tracked in spec-compliance-report.md as "not started (alias)".
- **Action required**: None unless a separate `rsDecode` definition is desired for
  documentation clarity.

---

## Consistency checks

### KB internal cross-references

- [x] All files linked in `kb/index.md` exist on disk
- [x] `kb/properties.md` P1 formal statement matches `Dal.Protocol.rs_decoding_succeeds`
- [x] `kb/properties.md` P2 formal statement matches `Dal.Protocol.page_verification_unique`
- [x] `kb/properties.md` P3 formal statement matches `Dal.Protocol.shard_verification_recovery`
- [x] `kb/properties.md` A7 statement matches `Dal.KZG.verifyShardEval_soundness`
  (no degree bound; approved 2026-03-25 per review finding F4)
- [x] `kb/properties.md` S4 Lean target is `Dal.ReedSolomon.shard_recovery`
- [x] `kb/architecture.md` `Dal/Serialization.lean` describes interleaved layout (G11)
- [x] `kb/architecture.md` `Dal/Protocol.lean` lists P1, P2, and P3
- [x] `kb/architecture.md` `Dal/KZG.lean` notes G8/G9 axioms (shardRemainder, A7)
- [x] `kb/architecture.md` `Dal/Properties.lean` lists S1–S4, P1–P3 (7 theorems)
- [x] `kb/gaps.md` G1 completed bullets include all nine modules
- [x] `kb/gaps.md` G8, G9, G10, G11 all marked `resolved`
- [x] `kb/gaps.md` G12 and G13 both marked `resolved` (correct)
- [x] `kb/spec.md` A7 statement updated (no degree bound); P3 includes `verifyDegree` hypothesis
- [x] `kb/decisions/001-kzg-axioms.md` lists A7 as approved axiom
- [x] `slot_size_le` is now a derived lemma in `Dal/Serialization.lean`,
  not an axiom — consistent with architecture.md description

### Term consistency

- [x] `shardEval` used consistently in glossary, spec, architecture, Lean
- [x] `proveEval` returns `Option G1` — noted in architecture.md and used
  with `= some (πs i)` form in all three protocol theorems
- [x] `Function.Injective xs` precondition in P1 consistently documented
- [x] `verifyShardEval_soundness` A7 has no degree bound — consistent across
  properties.md, spec.md, decisions/001, and the Lean axiom declaration

### Stale content check

- [x] No KB file claims a module is "unstarted" that is in fact implemented
- [x] No KB file claims a theorem is `not started` that is in fact proved
- [x] `kb/architecture.md` "Current state" accurately reflects all modules complete
- [x] `kb/gaps.md` G1 completed bullets match the actual module implementations
- [x] `kb/reports/sorry-report.md` (run 11) cross-check table includes G8/G9/G10 entries
- [x] `kb/reports/spec-compliance-report.md` (run 12) coverage matrix is complete
