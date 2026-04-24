---
title: Formalization Architecture
last-updated: 2026-04-24
status: draft
---

# Formalization Architecture

Describes how the Lean formalization is structured: modules, namespaces,
dependencies, and each module's responsibility.

See also: [spec.md](spec.md) for what is being formalized; [glossary.md](glossary.md)
for term definitions.

---

## Current state

All modules — `Dal/Field.lean`, `Dal/Poly.lean`, `Dal/KZG.lean`, `Dal/Sharding.lean`,
`Dal/Serialization.lean`, `Dal/ReedSolomon.lean`, `Dal/Protocol.lean`, and
`Dal/Properties.lean` — are implemented and build clean with zero sorry.
`Dal/Protocol.lean` now contains P1, P2, and P3. `Dal/KZG.lean` now contains
five security axioms (A1–A3, A6, A7). See [gaps.md](gaps.md) for the complete history.

### Implementation notes for `Dal/Serialization.lean`

- **`slot_size_le` is derived, not axiom**: `slot_size ≤ k * 31` follows from
  `slot_size_le_pages` and `page_size_le_chunks` by two applications of
  `Nat.mul_le_mul_left` and `pages_per_slot_mul_page_length`.
- **`byteAt` is `noncomputable`**: it depends on axiom `slot_size`. `byteChunk` and
  `serialize` are `noncomputable` by transitivity.
- **`byteAt_eq` simp lemma**: `byteAt b m = b ⟨m, h⟩` when `h : m < slot_size`;
  proved via `dif_pos h`. Used in `serialize_injective` to bridge padding/non-padding.
- **`serialize_injective` proof structure** (interleaved layout): for `m < slot_size`,
  compute `page = m / page_size`, `elt = (m % page_size) / 31`, `j = (m % page_size) % 31`.
  The scalar index is `elt * pages_per_slot + page`. Three key `have` lemmas recover
  `page` and `elt` from the scalar index via `Nat.add_mul_mod_self_left` and
  `Nat.add_mul_div_left`, and reconstruct `m` from `page * page_size + elt * 31 + j`
  via two applications of `Nat.div_add_mod` + `linarith`.
- **No `let` bindings**: using `let page := ...` causes Lean not to unfold `.val`
  in subsequent goals. Use explicit `Nat` expressions throughout.

### Implementation notes for `Dal/ReedSolomon.lean`

- **`Fin (d+1)` not `Fin (k/l*l)`**: `cosetPoints` and `shardVals` have domain `Fin (d+1)`,
  not `Fin (k/l*l)` as written in `kb/spec.md`. They are equal (via `kl_eq_d_succ`), but
  `Fin (d+1)` matches `Dal.Poly.interpolate`'s argument type directly.
- **Enumeration order**: point `m : Fin (d+1)` maps to coset `I[⌊m/l⌋]` (sorted by
  `Finset.orderIsoOfFin`) at position `m % l`. The bound `m/l < k/l` is proved via
  `Nat.div_lt_iff_lt_mul` since omega cannot handle `a < b*c → a/b < c` directly.
- **`cosetPoints_injective` proof structure**: `by_cases (e ia1).val = (e ia2).val`;
  same-coset branch uses `ω_pow_inj` + `Nat.eq_of_mul_eq_mul_left s_pos` + Euclidean
  division uniqueness via `Nat.div_add_mod` + `linarith`; cross-coset branch uses
  `cosets_disjoint`.
- **`Equiv.injective` for `orderIsoOfFin`**: accessed as `(I.orderIsoOfFin hI).toEquiv.injective`.

### Implementation notes for `Dal/Field.lean`

- **Deployment parameters as axioms**: `r`, `n`, `n_pos`, `n_dvd_r_sub_one` are
  declared as `axiom` (not `variable`) so downstream modules can use bare names
  without threading them through every signature.
- **`ω` axiomatized**: the primitive root of unity is declared as `axiom ω : Fr`
  with `axiom ω_isPrimitiveRoot : IsPrimitiveRoot ω n`. Existence is provable
  (cyclic group argument) but axiomatizing is consistent with the KZG treatment
  and avoids a proof that would require significant Mathlib API work.
- **Mathlib import**: `IsPrimitiveRoot` lives in
  `Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots` (not `.Basic`).

### Implementation notes for `Dal/Poly.lean`

- **Lagrange.interpolate API**: In the `Interpolate` section of
  `Mathlib.LinearAlgebra.Lagrange`, the section variable `(r : ι → F)` (values
  function) is the **first explicit argument** to all theorems, before `hvs`
  (injectivity). Call order: `Lagrange.eval_interpolate_at_node ys hvs hi`.
- **eq_of_degrees_lt_of_eval_index_eq**: lives in `namespace Polynomial` (not
  `Lagrange`), in the `Indexed` section where `s : Finset ι` is explicit (first
  arg). Full name: `Polynomial.eq_of_degrees_lt_of_eval_index_eq`.
- **dupNamespace linter**: `abbrev Poly` in `namespace Dal.Poly` triggers the
  `dupNamespace` linter warning; suppressed with
  `set_option linter.dupNamespace false` at file scope.
- **`show` vs `change`**: Mathlib's `linter.style.show` warns when `show` changes
  the goal rather than just annotating it; use `change` or `simp only [...]` to
  unfold definitions instead.
- **Mathlib import**: `Mathlib.LinearAlgebra.Lagrange`.

### Implementation notes for `Dal/KZG.lean`

- **Four axioms, not three**: `spec.md` and `properties.md` both list A2 as an
  axiom. Decision 001's "exactly three" was an oversight; `Dal/KZG.lean` declares
  A1, A2, A3, A6. Decision 001 has been updated accordingly.
- **A2 statement**: `(∃ π, proveEval p x y = some π) ↔ Polynomial.eval x p = y`
  (existential on the left, since the specific proof value is immaterial).
- **A1 statement**: uses `proveEval p x y = some π` (not `π = proveEval p x y`)
  since `proveEval` returns `Option G1`.
- **No group structure needed**: `G1`, `G2`, `GT` are bare types. Group operations
  are internal to the opaque KZG functions and not needed for the axiom statements.
- **No Mathlib import needed**: `Dal/KZG.lean` imports only `Dal.Field` and
  `Dal.Poly`.

---

## Lake project

```
lean/
  lakefile.toml       # Project config: depends on Mathlib v4.29.0-rc1
  Dal.lean            # Top-level import of all modules
  Dal/
    Basic.lean        # (stub — to be repurposed or removed)
    Field.lean        # Scalar field 𝔽_r and its properties
    Poly.lean         # Polynomials, degree, eval, interpolate
    ReedSolomon.lean  # RS encoding/decoding, MDS property
    KZG.lean          # KZG commitment scheme: types, axioms, functions
    Sharding.lean     # Cosets, vanishing polynomials, shard structure
    Serialization.lean # byte ↔ scalar array conversion
    Protocol.lean     # Top-level assembly: slot → shards → verify
    Properties.lean   # Correctness certificate: S1–S4, P1–P3, G13, A1c/A3c/A7c
```

---

## Module responsibilities

### `Dal/Field.lean`
- Declares `𝔽_r` as `ZMod r` for the BLS12-381 scalar field prime `r`.
- Axiomatizes all deployment parameters (`r`, `k`, `n`, `s`, `l`, `α`, `slot_size`,
  `d`) and their constraints.
- Axiomatizes `ω : Fr` with `ω_isPrimitiveRoot : IsPrimitiveRoot ω n`.
- Proves `ω_pow_n`, `ω_orderOf`, `ω_pow_inj`, and `d_succ_eq_k : d + 1 = k`.
- **Does not** contain elliptic curve definitions.

### `Dal/Poly.lean`
- Type alias: `Poly := Polynomial (ZMod r)`.
- Wraps Mathlib's `Polynomial.eval`.
- Defines `interpolate`: given `d+1` distinct points `xs` and values `ys`, returns
  the unique polynomial of degree `≤ d` with those evaluations. Use Mathlib's
  `Lagrange.interpolate` or `Polynomial.interpolate`.
- Proves A4 (interpolation correctness) and A5 (polynomial uniqueness) from Mathlib.
- **Key invariant**: interpolation is defined only when `xs` are distinct.

### `Dal/ReedSolomon.lean`
- Defines `rsEncode : Poly → Fin n → 𝔽_r` as evaluation at `ω^i`.
- Defines `cosetPoints` and `shardVals` as `Fin (d+1) → 𝔽_r` (using `Finset.orderIsoOfFin`
  to enumerate the index set `I` and Euclidean division to split `m` into coset/position).
- Proves `cosetPoints_injective` (distinctness of the `d+1` evaluation points) and
  `shard_recovery` (S4) via `poly_unique_of_eval` (A5).
- References: `Field.lean`, `Poly.lean`, `Sharding.lean`.

### `Dal/KZG.lean`
- Declares opaque types `G1`, `G2`, `GT` for BLS12-381 groups (bare types only;
  no pairing, no SRS, no group operations — these are internal to the opaque functions).
- Declares `commit`, `proveEval`, `verifyEval`, `proveDegree`, `verifyDegree`,
  `shardRemainder`, `proveShardEval`, `verifyShardEval` as opaque `axiom`s.
- Asserts soundness axioms A1, A2, A3, A6, A7 as `axiom`.
- Asserts completeness axioms A1c, A3c, A7c as `axiom` (gaps G12, resolved).
- **Key design choice**: KZG functions operate on `Poly`, not raw byte arrays. See
  [decisions/002-kzg-over-poly.md](decisions/002-kzg-over-poly.md).
- Imports `Dal.Sharding` for `Fin s`, `Fin l`, `shardEval`.

### `Dal/Sharding.lean`
- Defines `Ω : Fin s → Finset 𝔽_r` (the `s` cosets).
- Defines `Z : Fin s → Poly` (the vanishing polynomials `Z_i(x) = x^l - ω^{il}`).
- Defines `shardEval : Poly → Fin s → Fin l → 𝔽_r` as `eval p (cosetPoint i j)`.
- States and proves S2 (coset partition) and S3 (vanishing polynomial roots).
- References: `Field.lean`, `Poly.lean`.

### `Dal/Serialization.lean`
- Defines `Bytes := Fin slot_size → Fin 256` and `serialize : Bytes → (Fin k → Fr)`.
- Declares page structure axioms: `pages_per_slot`, `page_size`, `page_length`
  (and their positivity axioms), `pages_per_slot_mul_page_length` (`pages_per_slot *
  page_length = k`), `slot_size_le_pages` (`slot_size ≤ pages_per_slot * page_size`),
  `page_size_le_chunks` (`page_size ≤ page_length * 31`).
- Derives `slot_size_le : slot_size ≤ k * 31` as a lemma from the page bounds
  (not an axiom).
- Adds `bytes31_lt_r : 256^31 < r` — holds for BLS12-381 (`r ≈ 2^255 > 2^248`);
  ensures the cast of a 31-byte chunk to `Fr` does not wrap around.
- Defines `byteAt b m` — byte at position `m`, returning 0 for `m ≥ slot_size`.
- Defines `byteChunk b i j` with the **interleaved page layout** (gap G11):
  scalar `i` → page `page = i % pages_per_slot`, element `elt = i / pages_per_slot`,
  byte at `page * page_size + elt * 31 + j`. Matches `res[elt * pages_per_slot + page]`
  in the OCaml implementation.
- Proves S1 (`serialize_injective`) via `Fintype.equivFin` injectivity,
  `ZMod.val_cast_of_lt`, and injectivity of the interleaved address map.
- Defines `deserialize := Function.invFun serialize`; proves
  `deserialize_left_inverse` via `Function.leftInverse_invFun` + S1.

### `Dal/Protocol.lean`
- Proves P1 (`rs_decoding_succeeds`), P2 (`page_verification_unique`), and P3
  (`shard_verification_recovery`) from A1–A7 and S4.
- P1 additionally requires `Function.Injective xs` (distinct evaluation points) for A4/A5.
- P3 uses A7 for per-shard candidates, A3 for the degree bound (via an explicit
  `verifyDegree` hypothesis, mirroring P1's structure), A6 for uniqueness, and S4
  for the interpolant identity.
- `proveEval` returns `Option G1`, so proof conditions use `= some (πs i)`.
- Proves `round_trip` (G13): if `c` commits to the interpolant of `serialize b`
  and shard proofs verify, then deserializing the recovered polynomial's evaluations
  gives back `b`. Uses `d_succ_eq_k` to bridge `Fin (d+1)` and `Fin k`.
- **Planned (gap G14)**: DAL-level security theorems Sec1–Sec7:
  `slot_binding`, `decoder_determinism`, `shard_values_unforgeable`,
  `threshold_robustness`, `page_values_sound`, `commitment_well_formed`,
  and the three proof-non-malleability theorems (`eval_proof_unique`,
  `degree_proof_unique`, `shard_proof_unique`). All are corollaries of the
  existing axioms and main theorems; no new axioms required. See
  [properties.md § Security theorems](properties.md#security-theorems-dal-level-corollaries).
- This module imports all other modules.

### `Dal/Properties.lean`
- Re-exports all proved theorems and axioms: S1–S4, P1–P3, G13 (`g13_round_trip`),
  and completeness axioms A1c, A3c, A7c (eleven entries total).
  Importing this file gives the full correctness guarantee.
- All entries are either proved or declared as `axiom` without `sorry`.
- **Planned (gap G14)**: re-export the DAL-level security theorems
  Sec1–Sec7 as `sec1_slot_binding`, `sec2_decoder_determinism`,
  `sec3_shard_values_unforgeable`, `sec4_threshold_robustness`,
  `sec5_page_values_sound`, `sec6_commitment_well_formed`,
  `sec7_eval_proof_unique`, `sec7_degree_proof_unique`,
  `sec7_shard_proof_unique`.

---

## Dependency graph

```
Field ──────────────────────────────────────────┐
  │                                             │
  ▼                                             │
Poly ──────────────┬──────────────────────────  │
  │                │                            │
  ▼                ▼                            ▼
ReedSolomon    Sharding    Serialization      KZG
      │              │          │         ▲    │
      │              └──────────┼─────────┘    │
      └──────────────┴──────────┴──────────────┘
                                               │
                                               ▼
                                           Protocol
                                               │
                                               ▼
                                          Properties
```

Note: `KZG` now imports `Sharding` (added for `shardRemainder`, `proveShardEval`,
`verifyShardEval`, and `verifyShardEval_soundness` which reference `Fin s`, `Fin l`,
and `shardEval`).

---

## Mathlib dependencies

| Need | Mathlib location |
|------|-----------------|
| Polynomial type and `eval` | `Mathlib.RingTheory.Polynomial.Basic` |
| Lagrange interpolation | `Mathlib.RingTheory.Polynomial.Lagrange` |
| Finite fields | `Mathlib.FieldTheory.Finite.Basic` |
| Roots of unity / `IsPrimitiveRoot` | `Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots` |
| `ZMod` | `Mathlib.Data.ZMod.Basic` |
| Finset tools | `Mathlib.Data.Finset.Basic` |

---

## Lean version and toolchain

- Lean 4 (via Mathlib v4.29.0-rc1)
- `lakefile.toml` option `relaxedAutoImplicit = false` — all implicit arguments
  must be declared. Keep this enabled to prevent silent universe polymorphism bugs.
