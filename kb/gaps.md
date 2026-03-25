---
title: Open Proof Obligations and Gaps
last-updated: 2026-03-24
status: draft
---

# Open Proof Obligations (Gaps)

This file tracks every open obligation in the formalization: `sorry`-tagged
theorems, missing definitions, and areas not yet analyzed.

See also: [properties.md](properties.md) for the full invariant list;
[architecture.md](architecture.md) for module locations.

---

## Status key

| Symbol | Meaning |
|--------|---------|
| `unstarted` | No Lean file or theorem statement exists |
| `in-progress` | Lean statement exists; proof is `sorry` |
| `blocked` | Waiting on a dependency (note which) |
| `resolved` | Proof complete |

---

## Infrastructure gaps (no Lean code yet)

These are areas where no Lean code exists and no `sorry` placeholders exist yet.
They must be addressed before the formalization is useful.

### G1: Entire formalization is unstarted

- **Scope**: All modules in `Dal/` (`Field`, `Poly`, `KZG`, `Sharding`,
  `Serialization`, `ReedSolomon`, `Protocol`, `Properties`)
- **Status**: `resolved`
- **Completed**: `Dal/Field.lean` — `Fr`, all deployment parameters and
  constraints, `ω`, `ω_isPrimitiveRoot`, and three derived theorems.
- **Completed**: `Dal/Poly.lean` — `Poly` type alias, `interpolate` (wrapping
  `Lagrange.interpolate`), `interpolate_eval` (A4 eval), `interpolate_natDegree`
  (A4 degree), `poly_unique_of_eval` (A5). All proved without `sorry`.
- **Completed**: `Dal/KZG.lean` — `G1`, `G2`, `GT` opaque types; `commit`,
  `proveEval`, `verifyEval`, `proveDegree`, `verifyDegree` as axioms; security
  axioms A1 (`verifyEval_soundness`), A2 (`proveEval_complete`), A3
  (`verifyDegree_soundness`), A6 (`commit_binding`). Zero sorry.
- **Completed**: `Dal/Sharding.lean` — `cosetPoint`, `Ω`, `Z`, `shardEval`
  definitions; `s_mul_l_eq_n`, `l_dvd_n`, `coset_index_lt`, `ωs_isPrimitiveRoot`
  lemmas; `vanishing_poly_roots` (S3), `coset_partition` and `cosets_disjoint`
  (S2). All proved without `sorry`.
- **Completed**: `Dal/Serialization.lean` — `Bytes` type alias, `byteAt` (with
  zero-padding for partial last chunk), `byteChunk`, `bytesToFr` (via `Fintype.equivFin`),
  `serialize`; new axioms `slot_size_le : slot_size ≤ k * 31` (generalized from equality
  to handle `slot_size = 380832`) and `bytes31_lt_r : 256^31 < r`;
  `serialize_injective` (S1). All proved without `sorry`.
- **Completed**: `Dal/ReedSolomon.lean` — `rsEncode`, `cosetPoints`, `shardVals`,
  `cosetPoint_mem_Ω`, `cosetPoints_injective`, `shard_recovery` (S4). All proved
  without `sorry`.
- **Completed**: `Dal/Protocol.lean` — `page_verification_unique` (P2) and
  `rs_decoding_succeeds` (P1). Both proved without `sorry` from A1–A6 via A4+A5.
- **Completed**: `Dal/Properties.lean` — correctness certificate re-exporting all
  eight proved invariants: `s1_serialize_injective`, `s2_coset_partition`,
  `s2_cosets_disjoint`, `s3_vanishing_poly_roots`, `s4_shard_recovery`,
  `p2_page_verification_unique`, `p1_rs_decoding_succeeds`. Zero sorry.
- **Status**: `G1` is fully resolved. All modules in `Dal/` build clean with zero sorry.

---

## Known non-provable obligations (computational axioms)

These will never be proved — they are asserted as Lean `axiom` declarations.

### G2: Commitment binding (A6)

- **Statement**: `commit p = commit q → p = q`
- **Lean target**: `Dal.KZG.commit_binding`
- **Status**: `resolved` (declared as `axiom`)

### G3: Eval soundness (A1)

- **Statement**: `verifyEval x y c π = true → ∃ p, commit p = c ∧ proveEval p x y = some π`
- **Lean target**: `Dal.KZG.verifyEval_soundness`
- **Status**: `resolved` (declared as `axiom`)

### G4: Degree soundness (A3)

- **Statement**: `verifyDegree c bound π = true → ∃ p, commit p = c ∧ p.natDegree ≤ bound ∧ proveDegree p bound = some π`
- **Lean target**: `Dal.KZG.verifyDegree_soundness`
- **Status**: `resolved` (declared as `axiom`)

---

## Potentially provable obligations (to investigate)

These may be provable from Mathlib rather than assumed as axioms.

### G5: Interpolation correctness (A4)

- **Statement**: `interpolate xs ys = p → deg p ≤ d ∧ ∀ i, eval p (xs i) = ys i`
- **Lean target**: `Dal.Poly.interpolate_eval`, `Dal.Poly.interpolate_natDegree`
- **Status**: `resolved`
- **Note**: Proved using `Lagrange.eval_interpolate_at_node` and
  `Lagrange.degree_interpolate_lt` from `Mathlib.LinearAlgebra.Lagrange`.

### G6: Polynomial uniqueness (A5)

- **Statement**: two degree-`≤d` polynomials agreeing on `d+1` points are equal
- **Lean target**: `Dal.Poly.poly_unique_of_eval`
- **Status**: `resolved`
- **Note**: Proved using `Polynomial.eq_of_degrees_lt_of_eval_index_eq` from
  `Mathlib.LinearAlgebra.Lagrange`.

### G7: Serialization injectivity (S1)

- **Statement**: `serialize b₁ = serialize b₂ → b₁ = b₂`
- **Lean target**: `Dal.Serialization.serialize_injective`
- **Status**: `resolved`
- **Note**: Proved in `Dal/Serialization.lean` via `bytesToFr_injective` (using
  `Fintype.equivFin` + `ZMod.val_cast_of_lt`) and chunk extraction injectivity.
  Two supporting axioms added: `slot_size_le : slot_size ≤ k * 31` (generalized from
  the earlier equality to handle the real deployment where `slot_size = 380832` is not
  a multiple of 31) and `bytes31_lt_r : 256^31 < r`. Zero-padding via `byteAt` handles
  the partial last chunk.

---

## Planned gaps (not yet started)

These gaps were identified from external feedback and are planned for a future
formalization pass. No Lean code exists for any of them yet.

### G8: `shardRemainder`, `proveShardEval`, `verifyShardEval` (axiom declarations)

- **Scope**: `Dal/KZG.lean` — three new opaque declarations:
  - `shardRemainder : Poly → Fin s → Poly` — euclidean remainder of `p` by `Z_i`
    (degree `< l`, agrees with `p` on `Ω_i`)
  - `proveShardEval : Poly → Fin s → G1` — multi-reveal proof `[q_i(τ)]_1`
    where `q_i = (p - shardRemainder p i) / Z_i`
  - `verifyShardEval : G1 → Fin s → (Fin l → Fr) → G1 → Bool` — pairing check
    `e(c - [r_i(τ)]_1, g_2) = e(π_i, [τ^l]_2 - [ω^{il}]_2)`
- **Status**: `resolved`
- **Completed**: All three declared as `axiom` in `Dal/KZG.lean`. `Dal/KZG.lean`
  now imports `Dal.Sharding` for `Fin s`, `Fin l`, and `shardEval`. Zero sorry.

### G9: `verifyShardEval_soundness` axiom (A7)

- **Statement**: `verifyShardEval c i vs π = true → ∃ p, commit p = c ∧ proveShardEval p i = π ∧ ∀ j, shardEval p i j = vs j`
- **Lean target**: `Dal.KZG.verifyShardEval_soundness`
- **Status**: `resolved`
- **Completed**: Declared as `axiom` in `Dal/KZG.lean`. Approved 2026-03-25.
  See [decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

### G10: `shard_verification_recovery` theorem (P3)

- **Statement**: `(∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true) → ∃! p, commit p = c ∧ (∀ i ∈ I, ∀ j, shardEval p i j = vs i j) ∧ interpolate (cosetPoints I hI) (shardVals I hI vs) = p`
- **Lean target**: `Dal.Protocol.shard_verification_recovery`
- **Status**: `resolved`
- **Completed**: Proved in `Dal/Protocol.lean`. A7 gives degree-bounded candidates;
  A6 collapses to unique `p`; S4 (`shard_recovery`) gives the interpolant identity.
  Re-exported as `Dal.Properties.p3_shard_verification_recovery`. Zero sorry.
- **Note**: A7's conclusion includes `p.natDegree ≤ d` (baked in, since all valid
  KZG commitments bound the degree), making P3 self-contained without a separate
  degree-proof hypothesis.

---

## TODO: Areas not yet analyzed

These sections of `docs/protocol.md` have no KB coverage and no Lean code. They
are lower priority for the initial formalization.

- **Multi-reveal proof computation** (§Multiple multi-reveals): the efficient
  `O((n/l) log(n/l))` algorithm for computing all `s` shard proofs simultaneously.
  This is an algorithmic result; formalization may not be needed unless we want
  verified proof generation.
- **Degree bound proof protocol** (§Bound proof on the degree of committed
  polynomials, lines 371–428): the interactive/non-interactive protocol for
  `PK{f : C = g^{f(α)} ∧ deg f ≤ d}`. The internal structure of this proof
  (Fiat-Shamir heuristic, two-round protocol) is not needed because A3 is
  axiomatized. Acceptable gap.
- **BLS12-381 curve definition**: the concrete curve equation and group law. The
  formalization treats `𝔾_1`, `𝔾_2` as opaque types with axiomatized operations.
- **FFT / DFT algorithms** (§Fast Fourier Transform, §Prime factor algorithm):
  These are the algorithmic building blocks for RS encoding and multi-reveal proofs.
  Out of scope — the formalization axiomatizes the mathematical properties of these
  operations rather than verifying the algorithm implementations.
