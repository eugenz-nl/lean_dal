---
auditor: ambiguity-auditor
date: 2026-03-24
run: 11
status: 1 warning, 3 info
---

# Ambiguity Audit Report

## Changes since last run

No issues were resolved between run 10 and run 11. The W1 warning from run 10
(`decisions/001-kzg-axioms.md` §"What NOT to do" omits A2) remains open. The
two info items from run 10 (I1 — missing glossary entries; I2 — multi-reveal gap)
are carried forward.

One new info item added (I3) due to `Dal/ReedSolomon.lean`: `kb/properties.md`
S4 entry lists status `not started` and Lean target `Dal.Protocol.shard_recovery`,
both of which are now stale.

---

## Warnings

### [W1] `decisions/001-kzg-axioms.md` §"What NOT to do" still omits A2

- **KB location**: `kb/decisions/001-kzg-axioms.md` § "What NOT to do":
  "Do not assert additional axioms beyond A1, A2, A3, A6 without explicit human
  approval."
- **Reality**: The §Consequences section of the same file states: "The
  `Dal/KZG.lean` module contains four `axiom` declarations: A1, A2, A3, A6."
  A2 (`proveEval_complete`) is axiomatized and documented as deliberate. The
  "What NOT to do" bullet was previously updated (the text now reads "beyond
  A1, A2, A3, A6") — this warning should be **verified on re-read**.

  Re-reading the file: `kb/decisions/001-kzg-axioms.md` line 53 reads:
  "Do not assert additional axioms beyond A1, A2, A3, A6 without explicit human
  approval." This is now **correct**. W1 is resolved.

  Correcting the report: W1 from run 10 is **resolved**. No warnings remain from
  the decisions files.

---

## Warnings (revised after re-read)

No warnings remain from KB decisions files.

### [W1] `kb/properties.md` S4 entry is stale (namespace and status wrong)

- **KB location**: `kb/properties.md` § S4: Shard recovery (MDS property):
  - Lean target: `Dal.Protocol.shard_recovery`
  - Status: `not started`
- **Reality**: `Dal/ReedSolomon.lean` contains `theorem shard_recovery` in
  namespace `Dal.ReedSolomon`, proved without `sorry`.
- **Ambiguity created**: The stale KB entry would lead an agent to believe S4
  is unimplemented and to attempt writing it again in `Dal/Protocol.lean`.
  The wrong namespace (`Dal.Protocol` instead of `Dal.ReedSolomon`) is a
  navigational contradiction.
- **Action required**: Update `kb/properties.md` S4:
  - Lean target → `Dal.ReedSolomon.shard_recovery`
  - Status → `proved`

---

## Info

### [I1] `glossary.md` missing entries for serialization terms; `k` description stale

- **Location**: `kb/glossary.md`
- **Missing entries**:
  - `Bytes` — the Lean type `Fin slot_size → Fin 256`
  - `slot_size_le` — the axiom `slot_size ≤ k * 31` (covering constraint)
  - `bytes31_lt_r` — the axiom `256^31 < r`; ensures 31-byte encoding does not
    wrap in `Fr`
  - `serialize` — the function `Bytes → (Fin k → Fr)` splitting a slot into `k`
    field elements
- **Stale description**: The `k` row in § Deployment parameters still reads
  `k ≈ slot_size / 31`. This should be updated to note that `slot_size ≤ k * 31`
  (with the last chunk zero-padded when `slot_size < k * 31`).
- **Action**: Add the four missing entries to `kb/glossary.md` and update the `k`
  row on the next KB update pass.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details

- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Status**: Still open. No blocker for current work.

### [I3] `kb/gaps.md` G1 "Next task" pointer is stale after `Dal/ReedSolomon.lean` completion

- **KB location**: `kb/gaps.md` § G1: Entire formalization is unstarted, "Next task"
  bullet: "Next task: Implement `Dal/ReedSolomon.lean`…"
- **Reality**: `Dal/ReedSolomon.lean` is now complete. The next task is
  `Dal/Protocol.lean` (P1, P2).
- **Ambiguity created**: An agent reading `gaps.md` G1 would begin implementing
  `Dal/ReedSolomon.lean` a second time, not knowing it is already done.
- **Action required**: Update `kb/gaps.md` G1:
  - Add a "Completed" bullet for `Dal/ReedSolomon.lean` listing `rsEncode`,
    `cosetPoints`, `shardVals`, `cosetPoint_mem_Ω`, `cosetPoints_injective`,
    and `shard_recovery` (S4). All proved without `sorry`.
  - Update "Next task" to `Dal/Protocol.lean` (P1 and P2).
