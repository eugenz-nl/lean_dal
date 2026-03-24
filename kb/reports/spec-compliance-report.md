---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 6
status: 0 critical, 2 warnings, 1 info
---

# Spec Compliance Report

## Changes since last run

- **New coverage**: `Dal/Serialization.lean` implemented: `Bytes` type, two new
  axioms (`slot_size_eq`, `bytes31_lt_r`), helper definitions `byteChunk` and
  `bytesToFr`, serialization function `serialize`, and proof of
  `serialize_injective` (S1).
- S1 (`serialize_injective`) is now proved without `sorry`; updated in coverage
  matrix.
- `Dal.lean` updated to import `Dal.Serialization`.
- W1 from run 5 (architecture.md naming stale for `shardEval`) remains open; no
  action was taken on it since run 5.

---

## Critical

None.

---

## Warnings

### [W1] Architecture doc names sharding function `shard`; Lean uses `shardEval`

- **KB location**: `kb/architecture.md` § Dal/Sharding.lean responsibility
- **Lean location**: `dal/Dal/Sharding.lean`
- **Issue**: `architecture.md` says the sharding module defines
  `shard : Poly → Fin s → Fin l → 𝔽_r`. The Lean file defines `shardEval`
  instead. `kb/spec.md` § Sharding and `kb/glossary.md` both use `shardEval`
  — the Lean identifier is correct with respect to the authoritative spec.
  `architecture.md` is stale.
- **Action required**: Update `kb/architecture.md` § Dal/Sharding.lean to
  replace `shard` with `shardEval`. (Carried over from run 5.)

### [W2] Two new axioms in `Dal/Serialization.lean` not documented in `kb/spec.md`

- **KB location**: `kb/spec.md` § Parameters (absent)
- **Lean location**: `dal/Dal/Serialization.lean` lines 50–54
- **Issue**: `slot_size_eq` (`slot_size = k * 31`) and `bytes31_lt_r`
  (`256^31 < r`) are declared as Lean `axiom` in `Dal/Serialization.lean`.
  Neither is listed in `kb/spec.md` § Parameters, which only records the
  symbolic constraint `k ≈ slot_size / 31` informally. These are new,
  independently asserted mathematical facts that belong in the KB parameter
  table.
  - `slot_size_eq` formalizes the informal `k ≈ slot_size / 31` into an exact
    equality: `slot_size = k * 31`. This is a strengthening of the spec's
    informal description and should be recorded as a parameter constraint.
  - `bytes31_lt_r` (`256^31 < r`) is a numerical fact about BLS12-381 that is
    not mentioned anywhere in the KB. It is true (BLS12-381 has `r ≈ 2^255 >
    2^248 = 256^31`), used to ensure no wrap-around in the `Nat → Fr` cast, and
    is a legitimate axiom for this deployment. It should be added to the KB.
- **Severity**: Warning — the axioms are mathematically sound and consistent
  with the protocol, but they represent KB coverage gaps. The spec.md parameter
  table and/or a `decisions/` file should document them so that future agents
  know these are intentional constraints, not oversights.
- **Action required**:
  1. Add `slot_size_eq` as a formal parameter constraint to `kb/spec.md`
     § Parameters: "`slot_size = k * 31` (exact equality, not just
     approximation)".
  2. Add `bytes31_lt_r` to `kb/spec.md` § Parameters or a note in
     `kb/architecture.md` § Dal/Serialization.lean: "`256^31 < r` (holds for
     BLS12-381 since `r ≈ 2^255`)".

---

## Info

### [I1] P1, P2, S4 still `not started`; S1 now resolved

- **KB location**: `kb/properties.md`
- **Lean location**: missing (`Dal/Protocol.lean` not yet written)
- **Issue**: Expected at this stage. P1, P2, and S4 require `Dal/Protocol.lean`
  which has not been written. S1 (`serialize_injective`) is now resolved as of
  this run.

---

## Serialization Module Compliance (Dal/Serialization.lean) — Detailed

This section provides the focused comparison requested for the newly implemented
serialization module.

### `Bytes` type

- **Spec** (`kb/architecture.md` § Dal/Serialization.lean): "Defines the
  bijection between `Bytes slot_size` and `Fin k → 𝔽_r`."
- **Spec** (`kb/spec.md` data flow): "RAW BYTES (slot_size bytes) → serialize:
  31 bytes → 1 scalar".
- **Lean** (`Dal.Serialization.Bytes`): `abbrev Bytes := Fin slot_size → Fin 256`.
- **Verdict**: Correct. `Fin slot_size → Fin 256` represents a sequence of
  `slot_size` bytes (each byte valued 0–255 = `Fin 256`). This matches the
  protocol's byte array model. The glossary entry for "Slot" says "a raw byte
  sequence of fixed size `slot_size`"; this type captures that exactly.

### `slot_size_eq` axiom

- **Spec** (`kb/spec.md` § Parameters): "`k ≈ slot_size / 31`" (informal).
- **Lean** (`Dal.Serialization.slot_size_eq`): `axiom slot_size_eq : slot_size = k * 31`.
- **Verdict**: Consistent with spec intent. The informal approximation is
  formalized as an exact equality. The spec's `≈` is a prose shorthand for the
  deployed configuration; `slot_size = k * 31` is the correct mathematical
  constraint. **Flag**: Not yet in `kb/spec.md` as a formal constraint — see
  W2 above.

### `bytes31_lt_r` axiom

- **Spec**: Not mentioned in any KB file.
- **Lean** (`Dal.Serialization.bytes31_lt_r`): `axiom bytes31_lt_r : 256^31 < r`.
- **Verdict**: Mathematically necessary for the injectivity proof. The axiom
  ensures that a 31-byte integer never exceeds the field modulus, so the
  `Nat → Fr = ZMod r` cast is injective on the relevant range. True for
  BLS12-381 (`r ≈ 2^255`, `256^31 = 2^248`). **Flag**: Undocumented in KB —
  see W2 above.

### `serialize` function

- **Spec** (`kb/spec.md` § Data flow): "serialize: 31 bytes → 1 scalar; pad to
  k scalars".
- **Spec** (`kb/spec.md` § Functions): Implied by the data flow; not given an
  explicit function entry.
- **Lean** (`Dal.Serialization.serialize`):
  `noncomputable def serialize (b : Bytes) : Fin k → Fr := fun i => bytesToFr (byteChunk b i)`.
- **Verdict**: Matches spec intent. The function splits `slot_size = k * 31`
  bytes into `k` consecutive 31-byte chunks (`byteChunk`) and encodes each
  chunk as a field element (`bytesToFr`). The encoding uses `Fintype.equivFin`
  to obtain a canonical bijection from `(Fin 31 → Fin 256)` to `Fin (256^31)`,
  then casts the natural number index to `Fr`. This is mathematically equivalent
  to little-endian base-256 encoding; the OCaml reference implementation's index
  permutation (`elt * pages_per_slot + page`) is a bijection on indices that
  does not affect injectivity. The module header documents this design choice
  explicitly.

### `serialize_injective` (S1)

- **Spec** (`kb/properties.md` S1): `serialize b₁ = serialize b₂ → b₁ = b₂`.
- **Lean target** (`kb/properties.md`): `Dal.Serialization.serialize_injective`.
- **Lean statement**: `theorem serialize_injective : Function.Injective serialize`.
- **Lean proof**: Complete (no `sorry`). Proof proceeds via:
  1. `bytesToFr_injective` reduces the goal to chunk equality;
  2. `reindex` lemma uses Euclidean division (`31 * (m/31) + m%31 = m`) to map
     every byte position back to its chunk, completing the proof by `ext`.
- **Verdict**: Exact statement match to `kb/properties.md` S1. Proof strategy
  (injectivity through chunk encoding, then byte reindexing) is sound. Status
  updated to **proved**.

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
