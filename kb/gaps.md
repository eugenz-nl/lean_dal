---
title: Open Proof Obligations and Gaps
last-updated: 2026-04-24
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
  constraints, `ω`, `ω_isPrimitiveRoot`; derived lemmas `ω_pow_n`, `ω_orderOf`,
  `ω_pow_inj`, `d_succ_eq_k`.
- **Completed**: `Dal/Poly.lean` — `Poly` type alias, `interpolate` (wrapping
  `Lagrange.interpolate`), `interpolate_eval` (A4 eval), `interpolate_natDegree`
  (A4 degree), `poly_unique_of_eval` (A5). All proved without `sorry`.
- **Completed**: `Dal/KZG.lean` — `G1`, `G2`, `GT` opaque types; `commit`,
  `proveEval`, `verifyEval`, `proveDegree`, `verifyDegree`, `shardRemainder`,
  `proveShardEval`, `verifyShardEval` as axioms; security axioms A1
  (`verifyEval_soundness`), A2 (`proveEval_complete`), A3
  (`verifyDegree_soundness`), A6 (`commit_binding`), A7
  (`verifyShardEval_soundness`); completeness axioms A1c (`verifyEval_complete`),
  A3c (`proveDegree_complete`), A7c (`verifyShardEval_complete`). Zero sorry.
- **Completed**: `Dal/Sharding.lean` — `cosetPoint`, `Ω`, `Z`, `shardEval`
  definitions; `s_mul_l_eq_n`, `l_dvd_n`, `coset_index_lt`, `ωs_isPrimitiveRoot`
  lemmas; `vanishing_poly_roots` (S3), `coset_partition` and `cosets_disjoint`
  (S2). All proved without `sorry`.
- **Completed**: `Dal/Serialization.lean` — `Bytes` type alias; page structure
  axioms (`pages_per_slot`, `page_size`, `page_length`, positivity, product, bound
  axioms); `slot_size_le` (derived lemma); `byteAt` (zero-padded); interleaved
  `byteChunk` (`page = i % pages_per_slot`, `elt = i / pages_per_slot`, byte at
  `page * page_size + elt * 31 + j`); `bytesToFr` (via `Fintype.equivFin`);
  `serialize`; `serialize_injective` (S1); `deserialize` (`Function.invFun
  serialize`); `deserialize_left_inverse`. All proved without `sorry`.
  See G11 (resolved).
- **Completed**: `Dal/ReedSolomon.lean` — `rsEncode`, `cosetPoints`, `shardVals`,
  `cosetPoint_mem_Ω`, `cosetPoints_injective`, `shard_recovery` (S4). All proved
  without `sorry`.
- **Completed**: `Dal/Protocol.lean` — `page_verification_unique` (P2),
  `rs_decoding_succeeds` (P1), `shard_verification_recovery` (P3), and
  `round_trip` (G13). All proved without `sorry` from A1–A7 and S4.
- **Completed**: `Dal/Properties.lean` — correctness certificate re-exporting
  eleven entries: `s1_serialize_injective`, `s2_coset_partition`,
  `s2_cosets_disjoint`, `s3_vanishing_poly_roots`, `s4_shard_recovery`,
  `p1_rs_decoding_succeeds`, `p2_page_verification_unique`,
  `p3_shard_verification_recovery`, `a1c_verifyEval_complete`,
  `a3c_proveDegree_complete`, `a7c_verifyShardEval_complete`, `g13_round_trip`.
  Zero sorry.
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
- **Note (review finding F4)**: An earlier version included `p.natDegree ≤ d` in
  A7's conclusion, but this was stronger than the cryptographic primitive warrants:
  the multi-reveal verification equation does not enforce a degree bound. The degree
  bound was removed from A7; P3 now requires an explicit `verifyDegree` hypothesis,
  mirroring P1.

### G10: `shard_verification_recovery` theorem (P3)

- **Statement**: `verifyDegree c d π_deg = true → (∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true) → ∃! p, commit p = c ∧ (∀ i ∈ I, ∀ j, shardEval p i j = vs i j) ∧ interpolate (cosetPoints I hI) (shardVals I hI vs) = p`
- **Lean target**: `Dal.Protocol.shard_verification_recovery`
- **Status**: `resolved`
- **Completed**: Proved in `Dal/Protocol.lean`. A7 gives candidates (no degree
  bound); A3 (`verifyDegree_soundness`) gives `p.natDegree ≤ d` via a separate
  degree-proof hypothesis `π_deg` (mirroring P1); A6 collapses to unique `p`; S4
  gives the interpolant identity. Re-exported as
  `Dal.Properties.p3_shard_verification_recovery`. Zero sorry.

---

## Gaps identified by external review (docs/review-1bdfef9.md)

### G11: Page-based serialization with interleaving (Finding F1)

- **Scope**: `Dal/Serialization.lean` — the current model uses contiguous 31-byte
  chunks. The real Tezos DAL uses an interleaved layout:
  `res[elt * pages_per_slot + page]`, ensuring each page's scalar elements form a
  coset of the interpolation domain. This enables constant-time KZG multi-reveal
  proofs for L1 page verification.
- **Status**: `resolved`
- **Completed**: `Dal/Serialization.lean` rewritten with page structure axioms
  (`pages_per_slot`, `page_size`, `page_length`, their positivity and constraint
  axioms), `slot_size_le` (derived from the page bounds), interleaved `byteChunk`
  (scalar `i` → page `i % pages_per_slot`, element `i / pages_per_slot`, byte at
  `page * page_size + elt * 31 + j`), and a fully reproved `serialize_injective`
  (S1). Zero sorry. Build clean.
- **Impact**: S1 (serialization injectivity) holds for the interleaved layout.
  A future page-level verification property (P4, analogous to P3 but for pages)
  would build directly on this model.

### G12: Completeness axioms for KZG verification (Finding F2)

- **Scope**: The formalization proves soundness ("if verification passes, then a
  valid witness exists") but not completeness ("an honest prover's proofs always
  pass verification"). Missing axioms:
  - `verifyEval_complete` (A1c): `proveEval p x (eval p x) = some π → verifyEval x (eval p x) (commit p) π = true`
  - `proveDegree_complete` (A3c): `p.natDegree ≤ d → ∃ π, proveDegree p d = some π ∧ verifyDegree (commit p) d π = true`
  - `verifyShardEval_complete` (A7c): `verifyShardEval (commit p) i (fun j => shardEval p i j) (proveShardEval p i) = true`
- **Status**: `resolved`
- **Completed**: All three declared as `axiom` in `Dal/KZG.lean` (A1c, A3c, A7c)
  and re-exported as theorems from `Dal/Properties.lean`. These are axiomatized
  because all KZG functions are opaque; completeness follows from the algebraic
  correctness of the pairing equations but cannot be proved in pure Lean.
  Zero sorry. Build clean.

### G13: End-to-end round-trip theorem (Finding F3)

- **Scope**: `Dal/Protocol.lean` — the full DAL pipeline is:
  `bytes → serialize → scalars → interpolate → poly → commit → … → verify shards → interpolate → poly → evaluate → scalars → deserialize → bytes`.
  The formalization proves individual links (S1, P1, P3) but not their composition.
- **Status**: `resolved`
- **Completed**:
  - `Dal/Serialization.lean`: `deserialize` defined as `Function.invFun serialize`;
    `deserialize_left_inverse` proved via `Function.leftInverse_invFun serialize_injective`.
  - `Dal/Field.lean`: `d_succ_eq_k : d + 1 = k` added as a public lemma (used to
    cast between `Fin (d+1)` and `Fin k` in the round-trip).
  - `Dal/Protocol.lean`: `round_trip` theorem proved — given `hc : commit (interpolate xs
    (serialize b ∘ Fin.cast d_succ_eq_k)) = c`, shard verification, and degree proof,
    `deserialize (fun i => eval (xs (Fin.cast d_succ_eq_k.symm i)) (interpolate (cosetPoints I hI) ...)) = b`.
    Proof: P3 → unique `p`; A6 → `p = interpolate xs (serialize b ∘ ...)`; A4 recovers
    evaluations; cast composition gives `serialize b`; `deserialize_left_inverse` closes.
  - `Dal/Properties.lean`: `g13_round_trip` re-exports the theorem.
  Zero sorry. Build clean.

---

## DAL-level security theorems

### G14: Security theorems Sec1–Sec7

- **Scope**: `Dal/Protocol.lean` — a new block of theorems lifting the KZG
  axioms and the main theorems (P1, P2, P3, G13) to attacker-relevant
  DAL-level guarantees. Re-exported from `Dal/Properties.lean`.
- **Status**: `resolved`
- **Completed** (all proved in `Dal/Protocol.lean`, re-exported from
  `Dal/Properties.lean`):
  - `slot_binding` (Sec1) — `b₁ = b₂` from equal slot-level commitments.
    Proof: A6 + A4 + cast cancellation + S1.
  - `decoder_determinism` (Sec2) — two verifying shard subsets under the
    same commitment produce equal interpolants. Proof: P3 twice + A6.
  - `shard_values_unforgeable` (Sec3) — `verifyShardEval` acceptance pins
    shard values and proof to the known-slot expectation. Proof: A7 + A6.
  - `threshold_robustness` (Sec4) — honest shard set of size ≥ k/l suffices
    to reconstruct, for any k/l-subset. Proof: A7c + A3c + G13.
  - `page_values_sound` (Sec5) — `verifyEval` acceptance at all `xs` forces
    `ys` to equal `serialize b ∘ cast`. Proof: P2 + A2 + A6 + A4.
  - `commitment_well_formed` (Sec6) — `verifyDegree` acceptance implies
    commitment is in the image of `commit`. Proof: weakening of A3.
  - `eval_proof_unique`, `degree_proof_unique`, `shard_proof_unique` (Sec7)
    — three proof-non-malleability theorems. Proof: A1/A3/A7 + A6 +
    `Option.some.inj` (for eval/degree) / direct transitivity (shard).
- **Dependencies used**: A1, A2, A3, A6, A7, A1c (indirectly via P2/G13),
  A3c, A7c, P1, P2, P3, S1, S4, G13, and `d_succ_eq_k`. No new axioms added.
- **Reference**: [properties.md § Security theorems](properties.md#security-theorems-dal-level-corollaries).

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
