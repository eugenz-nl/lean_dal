---
title: Properties and Invariants
last-updated: 2026-03-23
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

## Axioms (KZG scheme properties)

These are **not proved** — they are assumed. The KZG construction satisfies them
under the `d`-strong Diffie-Hellman assumption. See
[decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

### A1: Eval soundness
`verifyEval x y c π = true → ∃ p, commit p = c ∧ π = proveEval p x y`

- **Lean target**: `Dal.KZG.verifyEval_soundness`
- **Status**: `not started`

### A2: Eval completeness
`proveEval p x y = some π ↔ eval p x = y`

- **Lean target**: `Dal.KZG.proveEval_complete`
- **Status**: `not started`

### A3: Degree soundness
`verifyDegree c d π = true → ∃ p, commit p = c ∧ deg p ≤ d ∧ π = proveDegree p d`

- **Lean target**: `Dal.KZG.verifyDegree_soundness`
- **Status**: `not started`

### A4: Interpolation correctness
`interpolate xs ys = p → deg p ≤ d ∧ ∀ i, eval p (xs i) = ys i`

- **Lean target**: `Dal.Poly.interpolate_correct`
- **Status**: `not started`
- **Note**: This may be provable from Mathlib's Lagrange interpolation, not just an
  axiom. To be determined.

### A5: Polynomial uniqueness from evaluations
`deg p ≤ d → deg p̃ ≤ d → (∀ i ∈ [0,d], eval p (xs i) = eval p̃ (xs i)) → p = p̃`

- **Lean target**: `Dal.Poly.poly_unique_of_eval`
- **Status**: `not started`
- **Note**: This follows from the fact that a nonzero polynomial of degree `≤ d`
  has at most `d` roots. Should be provable from Mathlib.

### A6: Commitment binding (computational assumption)
`commit p = commit p̃ → p = p̃`

- **Lean target**: `Dal.KZG.commit_binding`
- **Status**: `not started` (will be `axiom`)
- **Note**: Computationally binding under `d`-SDH. Cannot be proved in pure Lean —
  asserted as `axiom`. See [decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

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
       ∧ (∀ i, πs i = proveEval p (xs i) (ys i))
       ∧ interpolate xs ys = p
```

- **Lean target**: `Dal.Protocol.rs_decoding_succeeds`
- **Status**: `not started`
- **Proof plan**: Apply A1 for each `i` → get candidates `p_i`. Apply A6 → unique `p`.
  Apply A3 → `deg p ≤ d`. Apply A4 → interpolated `p̃` satisfies `eval p̃ (xs i) = ys i`.
  Apply A2 → `eval p (xs i) = ys i`. Apply A5 → `p̃ = p`.

### P2: Page verification uniqueness (Property 2)

**Statement**: Given `c : C`, `d+1` distinct points `xs`, values `ys`, proofs `πs`:

```
(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
→ ∃! p,  commit p = c
       ∧ (∀ i, πs i = proveEval p (xs i) (ys i))
```

- **Lean target**: `Dal.Protocol.page_verification_unique`
- **Status**: `not started`
- **Proof plan**: Apply A1 for each `i`. Apply A6 (uniqueness).

---

## Structural / well-formedness properties

### S1: Serialization injectivity

The byte-to-scalar serialization is injective (for fixed DAL parameters).

`serialize b₁ = serialize b₂ → b₁ = b₂`

- **Lean target**: `Dal.Serialization.serialize_injective`
- **Status**: `not started`
- **Source**: `docs/protocol.md` §"Serialize a byte sequence to a scalar array"

### S2: Coset partition

The evaluation domain partitions into `s` disjoint cosets:

`⟨ω⟩ = ⊔ (i : Fin s), Ω i` (disjoint union)

- **Lean target**: `Dal.Sharding.coset_partition`
- **Status**: `not started`

### S3: Vanishing polynomial roots

`Z_i(x) = x^l - ω^{il}` has exactly the elements of `Ω_i` as roots:

`∀ x, Z i x = 0 ↔ x ∈ Ω i`

- **Lean target**: `Dal.Sharding.vanishing_poly_roots`
- **Status**: `not started`

### S4: Shard recovery (MDS property)

Any `k/l` shards (i.e., evaluations at any `k/l` cosets) suffice to reconstruct
the polynomial. Precondition: `l ∣ k` (see `kb/spec.md` Parameters constraints).

Let `cosetPoints (I : Finset (Fin s)) : Fin (k/l * l) → X` collect, in order,
all `cosetPoint i j` for `i ∈ I`, `j : Fin l`. Let `shardVals` collect the
corresponding evaluations. Then:

```
∀ I : Finset (Fin s),  |I| = k / l
→ ∀ p : Poly,  ∀ vs : Fin s → Fin l → Y,
  (∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j)
  → p = interpolate (cosetPoints I) (shardVals I vs)
```

where `interpolate` is applied to the `k = (k/l) * l` collected evaluation
point/value pairs.

- **Lean target**: `Dal.Protocol.shard_recovery`
- **Status**: `not started`
- **Note**: Follows from the MDS property of Reed-Solomon codes (any `k` evaluation
  points at distinct locations determine the degree-`< k` polynomial). Mathlib may
  have relevant results in `Polynomial.Lagrange`.

---

## Invariant preservation checklist

When modifying any Lean file, verify:

- [ ] A1–A6 are still present as `axiom` or proved statements
- [ ] P1 and P2 still type-check (even if `sorry`-bodied)
- [ ] S1–S4 still type-check
- [ ] No existing proved theorem has been weakened (statement made strictly weaker)
- [ ] `lake build` passes
