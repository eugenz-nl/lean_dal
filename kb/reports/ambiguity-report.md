---
auditor: ambiguity-auditor
date: 2026-03-24
run: 8
status: 0 critical, 4 warnings, 2 info
---

# Ambiguity Audit Report

## Changes since last run

- `Dal/Serialization.lean` has been implemented since run 7. It provides `Bytes`,
  `slot_size_eq` (new axiom), `bytes31_lt_r` (new axiom), `byteChunk`, `bytesToFr`,
  `serialize`, and proves S1 (`serialize_injective`) without `sorry`. Zero sorries.
- Three warnings from run 7 (W1–W3) are carried forward: they are stale KB content
  that predates the Serialization implementation and remain unresolved.
- One new warning raised (W4): `architecture.md` "Current state" section still
  omits `Dal/Serialization.lean`; `properties.md` S1 status still reads
  `not started`; `gaps.md` G1 "Next task" pointer still says "Implement
  `Dal/Serialization.lean`" — all three are now stale.
- Four new missing glossary entries identified (I1 updated): `Bytes`,
  `slot_size_eq`, `bytes31_lt_r`, and `serialize` are used in the Lean
  implementation and the spec prose but are not defined in `kb/glossary.md`.
- Two new axioms (`slot_size_eq`, `bytes31_lt_r`) are not listed in `kb/spec.md`
  Parameters section or any axiom registry — raised as W5.
- Info item I2 (multi-reveal / `shardRemainder`) carries forward unchanged.

---

## Critical

None.

---

## Warnings

### [W1] `architecture.md` "Current state" section names Sharding as unstarted

- **KB location**: `kb/architecture.md` § "Current state" (line 19)
- **Actual text**: "Dal/Field.lean, Dal/Poly.lean, Dal/KZG.lean, and
  Dal/Sharding.lean are implemented and build clean. All other modules are
  unstarted."
- **Reality**: `Dal/Serialization.lean` is now also fully implemented with S1
  proved. The "Current state" sentence must be extended to include it.
- **Action required**: Update the sentence to include `Dal/Serialization.lean`.

### [W2] `architecture.md` Dal/Sharding.lean responsibility uses stale identifier `shard`

- **KB location**: `kb/architecture.md` § Dal/Sharding.lean (module responsibility
  bullet: "Defines `shard : Poly → Fin s → Fin l → 𝔽_r` as `eval p (coset_point i j)`.")
- **Reality**: the implemented and spec-correct name is `shardEval`; the helper
  is `cosetPoint`. This mismatch has been present since run 7 (originally W2).
- **Action required**: Replace `shard` with `shardEval` and `coset_point` with
  `cosetPoint` in the `Dal/Sharding.lean` responsibility paragraph.

### [W3] `properties.md` S2 and S3 status fields not updated after Sharding implementation

- **KB location**: `kb/properties.md` §S2 and §S3
- **Actual text**: both still read `**Status**: \`not started\``
- **Reality**: `Dal.Sharding.coset_partition`, `Dal.Sharding.cosets_disjoint` (S2),
  and `Dal.Sharding.vanishing_poly_roots` (S3) are all proved without `sorry`.
- **Action required**: Update S2 and S3 statuses to `proved`; name both S2
  theorems in the Lean target field.

### [W4] `properties.md` S1 status and `gaps.md` G1 "Next task" are stale after Serialization implementation

- **KB locations**:
  - `kb/properties.md` § S1 (Serialization injectivity): `**Status**: \`not started\``
  - `kb/gaps.md` § G1 "Next task": "Implement `Dal/Serialization.lean` — byte-to-scalar
    serialization bijection and proof of S1 (injectivity)."
  - `kb/gaps.md` § G7 (Serialization injectivity): `**Status**: \`unstarted\``
- **Reality**: `Dal/Serialization.lean` is implemented; `serialize_injective`
  (S1) is proved without `sorry`.
- **Action required**:
  - Update `kb/properties.md` S1 status to `proved`; update Lean target to
    `Dal.Serialization.serialize_injective`.
  - Update `kb/gaps.md` G1 "Next task" to reflect Serialization completion and
    name the next module (`Dal/Protocol.lean` or `Dal/ReedSolomon.lean`).
  - Update `kb/gaps.md` G7 status to `resolved`.

### [W5] Two new axioms not registered in `kb/spec.md` or `kb/architecture.md`

- **KB locations**:
  - `kb/spec.md` § Parameters: `slot_size` is listed with the comment
    "`k ≈ slot_size / 31`" but the exact equality `slot_size = k * 31` is not
    stated as a formal constraint.
  - `kb/architecture.md` § Dal/Serialization.lean: describes the module but does
    not mention the two axioms it introduces.
  - Neither `kb/spec.md` nor `kb/architecture.md` lists `bytes31_lt_r`
    (`256^31 < r`) anywhere.
- **Reality**: `Dal/Serialization.lean` declares:
  - `axiom slot_size_eq : slot_size = k * 31`
  - `axiom bytes31_lt_r : 256^31 < r`
- **Risk**: An agent reading `kb/spec.md` will not know these constraints exist.
  A future agent might restate them incorrectly or add a duplicate axiom.
- **Action required**:
  - Add `slot_size = k * 31` as a formal constraint in `kb/spec.md` § Parameters
    (replacing or sharpening the current approximation `k ≈ slot_size / 31`).
  - Add `256^31 < r` as a parameter constraint in `kb/spec.md` § Parameters or
    as a note under the `r` row.
  - Add a note in `kb/architecture.md` § Dal/Serialization.lean naming both axioms.

---

## Info

### [I1] Four new terms from `Dal/Serialization.lean` missing from `kb/glossary.md`

- **Location**: `kb/glossary.md`
- **Missing entries**:
  - `Bytes` — the Lean type `Fin slot_size → Fin 256`; the formalization's
    representation of a slot as a byte array.
  - `slot_size_eq` — the axiom `slot_size = k * 31` (makes the approximation
    in spec.md exact).
  - `bytes31_lt_r` — the axiom `256^31 < r` (ensures the 31-byte encoding does
    not wrap around in `Fr`).
  - `serialize` — the function `Bytes → (Fin k → Fr)` splitting a slot into
    `k` field elements; the formal counterpart of the OCaml reference function.
- **Action**: Add these four entries to `kb/glossary.md` § Protocol-level terms
  (or a new "Serialization" subsection) on the next KB update pass.

### [I2] Multi-reveal proof computation and `shardRemainder` verification details

- **Location**: `kb/gaps.md` § "Areas not yet analyzed"
- **Status**: Still open. No blocker for current work.
