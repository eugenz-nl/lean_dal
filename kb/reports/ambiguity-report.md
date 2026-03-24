---
auditor: ambiguity-auditor
date: 2026-03-24
run: 13
status: clean (1 info)
---

# Ambiguity Audit Report

## Changes since last run

All warnings from run 12 (W1–W3) are now resolved:

- **W1 resolved** — `kb/properties.md` S4 entry now has Lean target
  `Dal.ReedSolomon.shard_recovery` and status `proved`. No stale namespace.
- **W2 resolved** — `kb/properties.md` P1 formal statement now matches the Lean
  statement: uses `proveEval p (xs i) (ys i) = some (πs i)` and includes
  `hxs : Function.Injective xs`; status updated to `proved`.
- **W3 resolved** — `kb/properties.md` P2 formal statement now uses
  `proveEval p (xs i) (ys i) = some (πs i)`; status updated to `proved`.

Info items from run 12:

- **I1 resolved** — `kb/glossary.md` now contains entries for `Bytes`, `serialize`,
  `slot_size_le`, and `bytes31_lt_r`; the `k` row reads `slot_size ≤ k * 31`.
- **I2 carried forward** — Multi-reveal proof computation and `shardRemainder`
  verification details remain unformalized; still tracked in `kb/gaps.md`
  § "Areas not yet analyzed". No action needed for current scope.
- **I3 resolved** — `kb/gaps.md` G1 "Next task" pointer is no longer stale for
  `Dal/ReedSolomon.lean`.
- **I4 resolved** — `kb/gaps.md` G1 "Remaining" bullet now points to
  `Dal/Properties.lean` (stub), which is the actual remaining item.

New file `Dal/Properties.lean` added. This run audits KB consistency in light of
that addition. No new warnings found. One info item updated to reflect Properties
status.

---

## Warnings

None.

---

## Info

### [I1] `kb/gaps.md` G1 "Remaining" item: Properties.lean is no longer a stub

- **KB location**: `kb/gaps.md` § G1, "Remaining" bullet:
  "Dal/Properties.lean (stub) — not yet implemented. All invariants are already
  proved in their respective modules; this module would re-export them."
- **Reality**: `Dal/Properties.lean` now exists and is fully implemented.
  It re-exports all 8 theorems (S1, S2×2, S3, S4, P1, P2) without `sorry`.
  `Dal.lean` imports it on line 8.
- **Impact**: Low. The KB G1 "Remaining" bullet describes the stub state that no
  longer exists. An agent reading gaps.md G1 would think Properties.lean is still
  unimplemented, but this is now resolved.
- **Action required**: Update `kb/gaps.md` G1:
  - Move Properties.lean from "Remaining" to "Completed".
  - Add note: "All invariants S1–S4, P1, P2 re-exported from `Dal.Properties`
    without `sorry`."
  - Update or remove the "Remaining" paragraph (no further implementation work
    is required for the core formalization).

### [I2] Multi-reveal proof computation and `shardRemainder` verification

*(Carried forward from run 12.)*

- **Location**: `kb/gaps.md` § "TODO: Areas not yet analyzed"
- **Status**: Still open. No blocker for current work. The formalization of the
  core properties (S1–S4, P1, P2) is now complete. Multi-reveal formalization
  would be a separate effort if desired.

---

## Consistency checks

### KB internal cross-references

- [x] All files linked in `kb/index.md` exist on disk
- [x] `kb/properties.md` P1 formal statement matches `Dal.Protocol.rs_decoding_succeeds`
  (with `hxs`, `= some (πs i)` form)
- [x] `kb/properties.md` P2 formal statement matches `Dal.Protocol.page_verification_unique`
- [x] `kb/properties.md` S4 Lean target is `Dal.ReedSolomon.shard_recovery` (correct namespace)
- [x] `kb/architecture.md` "Current state" lists all implemented modules including
  `Dal/Protocol.lean`; notes `Dal/Properties.lean` is now complete
- [x] `kb/gaps.md` G1 completed bullets include `Dal/Protocol.lean` with P1 and P2
- [x] `kb/glossary.md` has entries for `Bytes`, `serialize`, `slot_size_le`, `bytes31_lt_r`
- [x] `kb/glossary.md` `k` row reads `slot_size ≤ k * 31`
- [x] `kb/spec.md` S4 helper functions section uses `Fin (d+1)` domain
- [x] All axiom declarations (A1, A2, A3, A6) consistent across spec.md, properties.md,
  architecture.md, and decisions/001-kzg-axioms.md
- [x] decisions/001-kzg-axioms.md §Consequences correctly states "four `axiom`
  declarations: A1, A2, A3, A6" and notes the A2 oversight correction
- [x] `kb/properties.md` S4 statement uses `Fin (d+1)` domain with note on equivalence
  to `Fin (k/l*l)`
- [x] `kb/architecture.md` dependency graph now shows `Protocol → Properties`
- [x] `Dal.lean` imports match the dependency graph: Field, Poly, KZG, Sharding,
  Serialization, ReedSolomon, Protocol, Properties (all present)

### Term consistency

- [x] `shardEval` used consistently (not `shard`) in glossary, spec, architecture, Lean
- [x] `proveEval` returns `Option G1` — noted in architecture.md §KZG, properties.md
  P1/P2 statements, and correctly used in Properties.lean
- [x] `Function.Injective xs` precondition in P1 consistently documented in
  properties.md, architecture.md §Protocol, and Properties.lean

### Stale content check

- [x] No KB file claims a module is "unstarted" that is in fact implemented
- [x] No KB file claims a theorem is `not started` that is in fact proved
- [x] `kb/architecture.md` "Current state" accurately reflects the project state:
  all seven `Dal/` modules implemented; `Dal/Properties.lean` now complete
- [ ] **[I1]** `kb/gaps.md` G1 "Remaining" still describes `Dal/Properties.lean`
  as a stub — now outdated (see I1 above)
