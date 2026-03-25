---
title: Properties and Invariants
last-updated: 2026-03-24
status: draft
---

# Properties and Invariants

This is the correctness checklist for the formalization. Every Lean change must
preserve every invariant listed here. If a proof is weakened, escalate to the user
— do not silently drop the invariant.

See also: [spec.md](spec.md) for context; [gaps.md](gaps.md) for open obligations;
[glossary.md](glossary.md) for term definitions.

---

## Status key

| Symbol | Meaning |
|--------|---------|
| `not started` | No Lean theorem statement exists |
| `stated` | Theorem statement exists; proof is `sorry` |
| `proved` | Proved without `sorry` |
| `axiom` | Asserted as an axiom (not to be proved) |

---

## Axioms (KZG security properties)

These are **not proved** — they are asserted as Lean `axiom` declarations. The KZG
construction satisfies them under the `d`-strong Diffie-Hellman assumption, which
is a computational hardness assumption and cannot be proved in pure mathematics.
See [decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

### A1: Eval soundness
`verifyEval x y c π = true → ∃ p, commit p = c ∧ proveEval p x y = some π`

- **Lean target**: `Dal.KZG.verifyEval_soundness`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)

### A2: Eval completeness
`(∃ π, proveEval p x y = some π) ↔ Polynomial.eval x p = y`

- **Lean target**: `Dal.KZG.proveEval_complete`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)
- **Note**: Decision 001 lists only A1, A3, A6 as axioms but omits A2; this is
  an oversight. Since `proveEval` is opaque, A2 must also be axiomatized.
  Decision 001 should be updated to reflect this.

### A3: Degree soundness
`verifyDegree c bound π = true → ∃ p, commit p = c ∧ p.natDegree ≤ bound ∧ proveDegree p bound = some π`

- **Lean target**: `Dal.KZG.verifyDegree_soundness`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)

### A6: Commitment binding
`commit p = commit q → p = q`

- **Lean target**: `Dal.KZG.commit_binding`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)
- **Note**: Technically false in pure math; true under `d`-SDH. See
  [decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

---

## Provable lemmas (from Mathlib)

These are **not axioms** — they are theorems that follow from the mathematics of
polynomials over finite fields and should be provable using Mathlib. See
[decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

### A4: Interpolation correctness
`interpolate xs ys = p → deg p ≤ d ∧ ∀ i, eval p (xs i) = ys i`

- **Lean targets**: `Dal.Poly.interpolate_eval` (eval part),
  `Dal.Poly.interpolate_natDegree` (degree part)
- **Lean form**: `theorem` (proved)
- **Status**: `proved`
- **Proof**: Via `Lagrange.eval_interpolate_at_node` and
  `Lagrange.degree_interpolate_lt` from `Mathlib.LinearAlgebra.Lagrange`.
  Requires `Function.Injective xs` (distinct evaluation points).

### A5: Polynomial uniqueness from evaluations
`deg p ≤ d → deg p̃ ≤ d → (∀ i ∈ Fin (d+1), eval p (xs i) = eval p̃ (xs i)) → p = p̃`

- **Lean target**: `Dal.Poly.poly_unique_of_eval`
- **Lean form**: `theorem` (proved)
- **Status**: `proved`
- **Proof**: Via `Polynomial.eq_of_degrees_lt_of_eval_index_eq` from
  `Mathlib.LinearAlgebra.Lagrange`. Requires `Function.Injective xs`.

---

## Main theorems (to be proved from axioms)

### P1: RS decoding succeeds (Property 1)

**Statement**: Given `c : C`, `d+1` distinct points `xs : Fin (d+1) → X`,
evaluations `ys : Fin (d+1) → Y`, proofs `πs : Fin (d+1) → Π`, and degree
proof `π_deg : Π`:

```
(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
→ verifyDegree c d π_deg = true
→ ∃! p,  commit p = c
       ∧ (∀ i, proveEval p (xs i) (ys i) = some (πs i))
       ∧ interpolate xs ys = p
```

The Lean statement also takes `hxs : Function.Injective xs` (distinct evaluation points),
required by `interpolate_natDegree` and `poly_unique_of_eval`. In `proveEval`, the return
type is `Option G1`, so the proof condition uses `= some (πs i)` rather than `πs i = ...`.

- **Lean target**: `Dal.Protocol.rs_decoding_succeeds`
- **Status**: `proved`
- **Proof**: A1 for each `i` gives candidates; A6 collapses to unique `p`. A2 gives
  `eval p (xs i) = ys i`. A3 gives degree bound. A4 + A5 give `interpolate xs ys = p`.

### P2: Page verification uniqueness (Property 2)

**Statement**: Given `c : C`, `d+1` distinct points `xs`, values `ys`, proofs `πs`:

```
(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
→ ∃! p,  commit p = c
       ∧ (∀ i, proveEval p (xs i) (ys i) = some (πs i))
```

- **Lean target**: `Dal.Protocol.page_verification_unique`
- **Status**: `proved`
- **Proof**: A1 for each `i` gives candidates; A6 collapses to unique `p`.

---

## Structural / well-formedness properties

### S1: Serialization injectivity

The byte-to-scalar serialization is injective (for fixed DAL parameters).

`serialize b₁ = serialize b₂ → b₁ = b₂`

- **Lean target**: `Dal.Serialization.serialize_injective`
- **Status**: `proved`
- **Source**: `docs/protocol.md` §"Serialize a byte sequence to a scalar array"
- **Proof**: Via `Fintype.equivFin` injectivity and `ZMod.val_cast_of_lt` (cast to `Fr`
  is injective for values < `256^31 < r`).

### S2: Coset partition

The evaluation domain partitions into `s` disjoint cosets:

`⟨ω⟩ = ⊔ (i : Fin s), Ω i` (disjoint union)

- **Lean targets**: `Dal.Sharding.coset_partition` (union), `Dal.Sharding.cosets_disjoint` (disjointness)
- **Status**: `proved`

### S3: Vanishing polynomial roots

`Z_i(x) = x^l - ω^{il}` has exactly the elements of `Ω_i` as roots:

`∀ x, Z i x = 0 ↔ x ∈ Ω i`

- **Lean target**: `Dal.Sharding.vanishing_poly_roots`
- **Status**: `proved`

### S4: Shard recovery (MDS property)

Any `k/l` shards (i.e., evaluations at any `k/l` cosets) suffice to reconstruct
the polynomial. Precondition: `l ∣ k` (see `kb/spec.md` Parameters constraints).

Let `cosetPoints (I : Finset (Fin s)) : Fin (d+1) → X` collect, in order,
all `cosetPoint i j` for `i ∈ I`, `j : Fin l`. Let `shardVals` collect the
corresponding evaluations. Then:

```
∀ I : Finset (Fin s),  |I| = k / l
→ ∀ p : Poly,  ∀ vs : Fin s → Fin l → Y,
  (∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j)
  → p = interpolate (cosetPoints I) (shardVals I vs)
```

where `interpolate` is applied to the `k = d+1 = (k/l) * l` collected evaluation
point/value pairs. The domain type `Fin (d+1)` (rather than `Fin (k/l*l)`) is used so
that `cosetPoints` and `shardVals` directly match the argument type of `Dal.Poly.interpolate`.

- **Lean target**: `Dal.ReedSolomon.shard_recovery`
- **Status**: `proved`
- **Proof**: Via `poly_unique_of_eval` (A5). Distinctness of the `d+1` coset points
  uses `cosets_disjoint` (S2) for cross-coset pairs and `ω_pow_inj` for within-coset
  pairs. See `Dal/ReedSolomon.lean`.

### P3: Shard verification implies recovery (planned)

**Statement**: Given `c : C`, an index set `I : Finset (Fin s)` with `|I| = k/l`,
shard evaluation values `vs : Fin s → Fin l → Fr`, and shard proofs `πs : Fin s → G1`:

```
(∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true)
→ ∃! p : Poly, commit p = c
             ∧ (∀ i ∈ I, proveShardEval p i = πs i)
             ∧ (∀ i ∈ I, ∀ j, shardEval p i j = vs i j)
             ∧ interpolate (cosetPoints I hI) (shardVals I hI vs) = p
```

- **Lean target**: `Dal.Protocol.shard_verification_recovery` (planned)
- **Status**: `not started`
- **Dependencies**: G8 (shardRemainder, proveShardEval, verifyShardEval declared in KZG),
  G9 (verifyShardEval_soundness axiom A7)
- **Proof plan**: A7 for each `i ∈ I` gives candidates; A6 collapses to unique `p`.
  S4 gives `interpolate(cosetPoints I, shardVals I vs) = p`. Degree bound `p.natDegree ≤ d`
  comes from A7 (the candidate has degree `≤ d` from its KZG commitment). Distinctness
  of `cosetPoints I hI` is `cosetPoints_injective` (already proved in S4).

---

## Invariant preservation checklist

When modifying any Lean file, verify:

- [ ] A1–A6 are still present as `axiom` or proved statements
- [ ] P1 and P2 still type-check (even if `sorry`-bodied)
- [ ] S1–S4 still type-check
- [ ] No existing proved theorem has been weakened (statement made strictly weaker)
- [ ] `lake build` passes
