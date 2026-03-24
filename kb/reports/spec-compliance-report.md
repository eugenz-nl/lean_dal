---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 11
status: clean (1 info)
---

# Spec Compliance Report

## Changes since last run

All seven warnings from run 10 (W1–W7) are now resolved:

- **W1 resolved** — `kb/properties.md` S4 entry now has Lean target
  `Dal.ReedSolomon.shard_recovery` and status `proved`.
- **W2 resolved** — `kb/architecture.md` "Current state" now lists
  `Dal/ReedSolomon.lean` as implemented.
- **W3 resolved** — `kb/spec.md` S4 helper functions section now uses `Fin (d+1)`.
- **W4 resolved** — `kb/properties.md` P2 status is now `proved`.
- **W5 resolved** — `kb/properties.md` P1 status is now `proved`; formal statement
  block includes `hxs : Function.Injective xs` and uses `= some (πs i)` form.
- **W6 resolved** — `kb/architecture.md` "Current state" now lists
  `Dal/Protocol.lean` as implemented, including the `Dal/Properties.lean` stub note.
- **W7 resolved** — `kb/gaps.md` G1 "Remaining" now correctly points to
  `Dal/Properties.lean` as the sole unfinished item.

New file `Dal/Properties.lean` added. This run audits its compliance.

The info item [I1] from run 10 (Lean statements are strictly stronger than spec
prose in two ways) is **resolved**: `kb/properties.md` P1 and P2 statement blocks
now match the Lean statements exactly.

---

## Statement Compliance Review

### Dal/Properties.lean — Structure

`Dal/Properties.lean` imports `Dal.Protocol` (which transitively imports all
other modules) and opens `Dal.Field`, `Dal.Poly`, `Dal.KZG`, `Dal.Serialization`,
`Dal.Sharding`, `Dal.ReedSolomon`, and `Dal.Protocol`. This gives access to all
definitions and theorems needed for the re-export statements.

Architecture spec (§Dal/Properties.lean): "Contains only the formal statements of
P1, P2, S1–S4 (and their proofs, once complete). Importing this file gives the
full correctness guarantee. All theorems here must be proved without `sorry`."

**Verdict**: Compliant. The file contains exactly the required theorem
re-exports (8 theorems covering S1, S2×2, S3, S4, P1, P2), all proved without
`sorry` by delegation to the underlying modules.

### S1: `s1_serialize_injective`

- **Spec** (`properties.md` §S1): `Function.Injective serialize`
- **Lean**: `theorem s1_serialize_injective : Function.Injective serialize :=`
  `Dal.Serialization.serialize_injective`
- **Verdict**: Conformant. Exact match.

### S2: `s2_coset_partition` and `s2_cosets_disjoint`

- **Spec** (`properties.md` §S2): coset union and disjointness
- **Lean (union)**: `Finset.image (fun m : Fin n => ω ^ m.val) Finset.univ =`
  `(Finset.univ : Finset (Fin s)).biUnion Ω`
- **Lean (disjoint)**: `s2_cosets_disjoint (i j : Fin s) (h : i ≠ j) : Disjoint (Ω i) (Ω j)`
- **Verdict**: Conformant. Both aspects of S2 are covered.

### S3: `s3_vanishing_poly_roots`

- **Spec** (`properties.md` §S3): `∀ x, Z i x = 0 ↔ x ∈ Ω i`
- **Lean**: `(i : Fin s) (x : Fr) : Polynomial.eval x (Z i) = 0 ↔ x ∈ Ω i`
- **Verdict**: Conformant. `Polynomial.eval x (Z i)` is the correct Lean form of
  `Z i x` (since `Z i : Poly` uses Mathlib's `Polynomial.eval`).

### S4: `s4_shard_recovery`

- **Spec** (`properties.md` §S4): Any `k/l` cosets suffice to recover the polynomial.
- **Lean**: `(I : Finset (Fin s)) (hI : I.card = k / l) (p : Poly)`
  `(hp : p.natDegree ≤ d) (vs : Fin s → Fin l → Fr)`
  `(heval : ∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j) :`
  `p = Dal.Poly.interpolate (cosetPoints I hI) (shardVals I hI vs)`
- **Verdict**: Conformant. Matches the updated properties.md S4 statement
  (which uses `Fin (d+1)` domain, with `cosetPoints` and `shardVals` helpers).

### P2: `p2_page_verification_unique`

- **Spec** (`properties.md` §P2):
  `(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)`
  `→ ∃! p, commit p = c ∧ (∀ i, proveEval p (xs i) (ys i) = some (πs i))`
- **Lean**: `(hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true) :`
  `∃! p : Poly, commit p = c ∧ ∀ i, proveEval p (xs i) (ys i) = some (πs i)`
- **Verdict**: Conformant. Exact match with updated properties.md P2.

### P1: `p1_rs_decoding_succeeds`

- **Spec** (`properties.md` §P1):
  `hxs : Function.Injective xs`
  `(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)`
  `→ verifyDegree c d π_deg = true`
  `→ ∃! p, commit p = c`
  `     ∧ (∀ i, proveEval p (xs i) (ys i) = some (πs i))`
  `     ∧ interpolate xs ys = p`
- **Lean**: matches exactly (with `hxs : Function.Injective xs`, `hverify`, `hdeg`
  as explicit hypotheses and `= some (πs i)` form).
- **Verdict**: Conformant. Exact match with updated properties.md P1.

---

## Warnings

None.

---

## Info

### [I1] `Dal/Properties.lean` import chain: single `import Dal.Protocol`

`Dal/Properties.lean` imports only `Dal.Protocol`, which transitively imports all
other modules. This is correct and sufficient. The `open` statement on line 27
opens all six namespaces needed for the re-export statements.

The architecture §Dal/Properties.lean description says "importing this file gives
the full correctness guarantee" — this is satisfied: `import Dal.Properties`
transitively brings in all nine project files and exposes all proved theorems.

No action required.

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
| `slot_size ≤ k * 31` constraint | spec.md § Parameters | `Dal.Serialization.slot_size_le` | axiom |
| `256^31 < r` constraint | spec.md § Parameters | `Dal.Serialization.bytes31_lt_r` | axiom |
| `serialize` function | spec.md § Data flow | `Dal.Serialization.serialize` | proved |
| S1: Serialization injectivity | properties.md | `Dal.Serialization.serialize_injective` | proved |
| `rsEncode` function | spec.md § Reed-Solomon | `Dal.ReedSolomon.rsEncode` | proved |
| `cosetPoints` helper | spec.md § S4 helpers | `Dal.ReedSolomon.cosetPoints` | proved |
| `shardVals` helper | spec.md § S4 helpers | `Dal.ReedSolomon.shardVals` | proved |
| S4: Shard recovery (MDS) | properties.md | `Dal.ReedSolomon.shard_recovery` | proved |
| P2: Page verification uniqueness | properties.md | `Dal.Protocol.page_verification_unique` | proved |
| P1: RS decoding succeeds | properties.md | `Dal.Protocol.rs_decoding_succeeds` | proved |
| S1 re-export | properties.md | `Dal.Properties.s1_serialize_injective` | proved |
| S2 re-export (union) | properties.md | `Dal.Properties.s2_coset_partition` | proved |
| S2 re-export (disjoint) | properties.md | `Dal.Properties.s2_cosets_disjoint` | proved |
| S3 re-export | properties.md | `Dal.Properties.s3_vanishing_poly_roots` | proved |
| S4 re-export | properties.md | `Dal.Properties.s4_shard_recovery` | proved |
| P2 re-export | properties.md | `Dal.Properties.p2_page_verification_unique` | proved |
| P1 re-export | properties.md | `Dal.Properties.p1_rs_decoding_succeeds` | proved |
| `shardRemainder` function | spec.md § Sharding | missing | not started |
| `proveShardEval` function | spec.md § Sharding | missing | not started |
| `verifyShardEval` function | spec.md § Sharding | missing | not started |
| `rsDecode` function | spec.md § Reed-Solomon | missing | not started |
