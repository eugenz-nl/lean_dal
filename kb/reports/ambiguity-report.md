---
auditor: ambiguity-auditor
date: 2026-03-24
run: 12
status: 3 warnings, 2 info
---

# Ambiguity Audit Report

## Changes since last run

The W1 warning from run 11 (`kb/properties.md` S4 entry stale) is carried
forward — it was not resolved between run 11 and run 12. Info items I1
(glossary missing entries) and I2 (multi-reveal gap) are also carried forward.
Info item I3 (gaps.md G1 "Next task" stale for ReedSolomon) is still open.

Three new issues are raised due to the addition of `Dal/Protocol.lean`:

- **[W2] NEW** — `kb/properties.md` P1 status is `not started` but the theorem
  is proved; the formal statement in the spec block also omits two precisions
  present in the Lean statement.
- **[W3] NEW** — `kb/properties.md` P2 status is `not started` but the theorem
  is proved; same `proveEval` notation gap as P1.
- **[I4] NEW** — `kb/gaps.md` G1 "Next task" still reads "Implement
  `Dal/Protocol.lean`" but that module is now complete.

---

## Warnings

### [W1] `kb/properties.md` S4 entry is stale (namespace and status wrong)

*(Carried forward from run 11.)*

- **KB location**: `kb/properties.md` § S4: Shard recovery (MDS property):
  - Lean target: `Dal.Protocol.shard_recovery`
  - Status: `not started`
- **Reality**: `Dal/ReedSolomon.lean` contains `theorem shard_recovery` in
  namespace `Dal.ReedSolomon`, proved without `sorry`.
- **Ambiguity created**: The stale KB entry leads an agent to believe S4 is
  unimplemented and to attempt writing it again in `Dal/Protocol.lean`. The
  wrong namespace is a navigational contradiction.
- **Action required**: Update `kb/properties.md` S4:
  - Lean target → `Dal.ReedSolomon.shard_recovery`
  - Status → `proved`

### [W2] `kb/properties.md` P1 formal statement is imprecise and status is wrong

- **KB location**: `kb/properties.md` § P1: RS decoding succeeds
  - Status: `not started`
  - Statement block: uses `πs i = proveEval p (xs i) (ys i)` (implies `proveEval`
    returns `G1`); does not include `hxs : Function.Injective xs`
- **Reality**: `Dal/Protocol.lean` `theorem rs_decoding_succeeds` is proved without
  `sorry`. It uses `proveEval p (xs i) (ys i) = some (πs i)` (correct `Option G1`
  form) and explicitly requires `hxs : Function.Injective xs`.
- **Ambiguity created**: An agent generating a Lean statement from the spec block
  would produce a type error (`proveEval` returns `Option G1`, not `G1`) and would
  omit a required hypothesis (injectivity). The stale status `not started` compounds
  the confusion.
- **Action required**: Update `kb/properties.md` P1:
  - Status → `proved`
  - Statement block: replace `πs i = proveEval p (xs i) (ys i)` with
    `proveEval p (xs i) (ys i) = some (πs i)`; add `hxs : Function.Injective xs`
    as a precondition

### [W3] `kb/properties.md` P2 formal statement is imprecise and status is wrong

- **KB location**: `kb/properties.md` § P2: Page verification uniqueness
  - Status: `not started`
  - Statement block: uses `πs i = proveEval p (xs i) (ys i)`
- **Reality**: `Dal/Protocol.lean` `theorem page_verification_unique` is proved without
  `sorry`. It uses `proveEval p (xs i) (ys i) = some (πs i)`.
- **Ambiguity created**: Same `Option G1` type confusion as P1. Stale status `not started`
  is additionally misleading.
- **Action required**: Update `kb/properties.md` P2:
  - Status → `proved`
  - Statement block: replace `πs i = proveEval p (xs i) (ys i)` with
    `proveEval p (xs i) (ys i) = some (πs i)`

---

## Info

### [I1] `glossary.md` missing entries for serialization terms; `k` description stale

*(Carried forward from run 11.)*

- **Location**: `kb/glossary.md`
- **Missing entries**: `Bytes`, `slot_size_le`, `bytes31_lt_r`, `serialize`
- **Stale description**: The `k` row still reads `k ≈ slot_size / 31`; should note
  `slot_size ≤ k * 31`.
- **Action**: Add four missing entries and update `k` row on next KB update pass.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details

*(Carried forward from run 11.)*

- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Status**: Still open. No blocker for current work.

### [I3] `kb/gaps.md` G1 "Next task" pointer stale after `Dal/ReedSolomon.lean` completion

*(Carried forward from run 11.)*

- **KB location**: `kb/gaps.md` § G1, "Next task" bullet: "Implement
  `Dal/ReedSolomon.lean`…"
- **Reality**: `Dal/ReedSolomon.lean` is complete; the G1 completed bullet for it
  is already present in gaps.md. The "Next task" bullet now reads "Implement
  `Dal/Protocol.lean`…"
- **Revised status**: This item is partially resolved — the "Implement
  `Dal/ReedSolomon.lean`" text is gone. The current "Next task" reads
  "Implement `Dal/Protocol.lean`" (see I4).

### [I4] `kb/gaps.md` G1 "Next task" pointer is stale after `Dal/Protocol.lean` completion

- **KB location**: `kb/gaps.md` § G1, "Next task" bullet:
  "Next task: Implement `Dal/Protocol.lean` — assemble P1 (RS decoding succeeds)
  and P2 (page verification uniqueness) from the existing axioms A1–A6."
- **Reality**: `Dal/Protocol.lean` is now complete with P1 and P2 both proved
  without `sorry`.
- **Ambiguity created**: An agent reading gaps.md G1 would begin implementing
  `Dal/Protocol.lean`, not knowing it is already done.
- **Action required**: Update `kb/gaps.md` G1:
  - Add "Completed" bullet for `Dal/Protocol.lean` listing `page_verification_unique`
    (P2) and `rs_decoding_succeeds` (P1). Both proved without `sorry`.
  - Update "Next task" to reflect remaining open work (KB metadata updates;
    `Dal/Properties.lean` if the stub file approach is pursued; or declare
    formalization of P1/P2/S1–S4 complete).
