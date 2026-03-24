---
auditor: ambiguity-auditor
date: 2026-03-24
run: 10
status: 1 warning, 2 info
---

# Ambiguity Audit Report

## Changes since last run

Two issues from run 9 are now resolved:

- **C1 resolved**: `kb/spec.md` § Parameters, Constraints now states
  `slot_size ≤ k * 31` (inequality, not equality), with a prose note explaining
  zero-padding and the real Tezos deployment values. The spec and the Lean file
  are now in agreement.
- **W1 resolved**: `kb/architecture.md` § Dal/Serialization.lean now names the
  axiom as `slot_size_le : slot_size ≤ k * 31` and describes it as a covering
  constraint with zero-padding. The `byteAt` and `byteChunk` implementation notes
  have been added and are accurate.

One warning remains (W2 from run 9, renumbered W1 here). Two info items are
carried forward (I1 and I2).

---

## Warnings

### [W1] `decisions/001-kzg-axioms.md` §"What NOT to do" still omits A2

- **KB location**: `kb/decisions/001-kzg-axioms.md` § "What NOT to do":
  "Do not assert additional axioms beyond A1, A3, A6 without explicit human
  approval."
- **Reality**: The §Consequences section of the same file states: "The
  `Dal/KZG.lean` module contains four `axiom` declarations: A1, A2, A3, A6."
  A2 (`proveEval_complete`) is axiomatized and documented as deliberate. The
  "What NOT to do" bullet was not updated to include A2 and now contradicts
  §Consequences.
- **Impact**: A future agent reading only §"What NOT to do" would incorrectly
  infer that A2 was added without approval, or would avoid axiomatizing A2 in a
  reimplementation.
- **Action required**: Update the "What NOT to do" bullet to read: "Do not assert
  additional axioms beyond A1, A2, A3, A6 without explicit human approval."

---

## Info

### [I1] `glossary.md` missing entries for serialization terms; `k` description stale

- **Location**: `kb/glossary.md`
- **Missing entries**:
  - `Bytes` — the Lean type `Fin slot_size → Fin 256`; the formalization's
    representation of a slot as a byte array.
  - `slot_size_le` — the axiom `slot_size ≤ k * 31` (covering constraint).
  - `bytes31_lt_r` — the axiom `256^31 < r`; ensures 31-byte encoding does not
    wrap in `Fr`.
  - `serialize` — the function `Bytes → (Fin k → Fr)` splitting a slot into `k`
    field elements.
- **Stale description**: The `k` row in § Deployment parameters still reads
  `k ≈ slot_size / 31`. This should be updated to note that `slot_size ≤ k * 31`
  (with the last chunk zero-padded when `slot_size < k * 31`).
- **Action**: Add the four missing entries to `kb/glossary.md` and update the `k`
  row on the next KB update pass.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details

- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Status**: Still open. No blocker for current work.
