---
title: Properties and Invariants
last-updated: 2026-04-24
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

### A1c: Eval completeness (verifier)
`proveEval p x (eval p x) = some π → verifyEval x (eval p x) (commit p) π = true`

- **Lean target**: `Dal.KZG.verifyEval_complete`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)
- **Note**: Complements A2 (which ensures `proveEval` produces a proof when
  `eval p x = y`) by guaranteeing that proof also passes `verifyEval`.
  Axiomatized because `verifyEval` is opaque; follows from algebraic correctness
  of the KZG pairing equation, not from hardness assumptions.

### A3c: Degree completeness
`p.natDegree ≤ bound → ∃ π, proveDegree p bound = some π ∧ verifyDegree (commit p) bound π = true`

- **Lean target**: `Dal.KZG.proveDegree_complete`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)
- **Note**: Axiomatized because `proveDegree` and `verifyDegree` are opaque.

### A7: Shard eval soundness
`verifyShardEval c i vs π = true → ∃ p, commit p = c ∧ proveShardEval p i = π ∧ ∀ j, shardEval p i j = vs j`

- **Lean target**: `Dal.KZG.verifyShardEval_soundness`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)
- **Note**: Multi-reveal analogue of A1. The degree bound is **not** included in
  A7's conclusion: the multi-reveal verification equation does not enforce a degree
  bound (review finding F4). P3 instead requires an explicit `verifyDegree`
  hypothesis, mirroring P1. Approved 2026-03-25.

### A7c: Shard eval completeness
`verifyShardEval (commit p) i (fun j => shardEval p i j) (proveShardEval p i) = true`

- **Lean target**: `Dal.KZG.verifyShardEval_complete`
- **Lean form**: `axiom`
- **Status**: `axiom` (declared)
- **Note**: Multi-reveal analogue of A1c. Axiomatized because `verifyShardEval`
  and `proveShardEval` are opaque; follows from algebraic correctness of the
  multi-reveal pairing equation.

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

### P3: Shard verification implies recovery

**Statement**: Given `c : C`, an index set `I : Finset (Fin s)` with `|I| = k/l`,
a degree proof `π_deg : G1`, shard evaluation values `vs : Fin s → Fin l → Fr`, and
shard proofs `πs : Fin s → G1`:

```
verifyDegree c d π_deg = true
→ (∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true)
→ ∃! p : Poly, commit p = c
             ∧ (∀ i ∈ I, proveShardEval p i = πs i)
             ∧ (∀ i ∈ I, ∀ j, shardEval p i j = vs i j)
             ∧ interpolate (cosetPoints I hI) (shardVals I hI vs) = p
```

- **Lean target**: `Dal.Protocol.shard_verification_recovery`
- **Status**: `proved`
- **Proof**: A7 for each `i ∈ I` gives candidates (no degree bound). A3
  (`verifyDegree_soundness`) gives `p.natDegree ≤ d` from the explicit degree-proof
  hypothesis `π_deg`, mirroring P1. A6 collapses to unique `p`. S4 gives the
  interpolant identity. Re-exported as `Dal.Properties.p3_shard_verification_recovery`.
- **Note (review finding F4)**: The earlier version obtained the degree bound from
  A7 directly (A7 included `p.natDegree ≤ d`). This was overstated: the multi-reveal
  verification equation does not enforce a degree bound. The fix adds an explicit
  `verifyDegree` hypothesis, consistent with how P1 handles degree.

---

### G13: End-to-end round-trip

**Statement**: Given `b : Bytes`, distinct nodes `xs : Fin (d+1) → Fr`, commitment
`c` to the interpolant of `serialize b` at `xs`, degree proof `π_deg`, index set `I`
with `|I| = k/l`, shard values `vs`, and proofs `πs` all verifying against `c`:

```
commit (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)) = c
→ verifyDegree c d π_deg = true
→ (∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true)
→ deserialize (fun i =>
      eval (xs (Fin.cast d_succ_eq_k.symm i))
           (interpolate (cosetPoints I hI) (shardVals I hI vs))) = b
```

- **Lean targets**: `Dal.Serialization.deserialize`, `Dal.Serialization.deserialize_left_inverse`,
  `Dal.Field.d_succ_eq_k`, `Dal.Protocol.round_trip`, `Dal.Properties.g13_round_trip`
- **Status**: `proved`
- **Proof**: P3 gives the unique `p` with `commit p = c`. A6 identifies `p` with
  `interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)`. A4 recovers the evaluations.
  Cast composition (`Fin.cast d_succ_eq_k ∘ Fin.cast d_succ_eq_k.symm = id`) gives
  back `serialize b`. `deserialize_left_inverse` closes the goal.

---

## Security theorems (DAL-level corollaries)

These restate the cryptographic guarantees of KZG and Reed-Solomon at the DAL
interface level (`Bytes`, slot-as-a-whole), giving attacker-relevant soundness
and binding statements. They are corollaries of the KZG axioms (A1, A3, A6, A7)
together with the structural lemmas (S1, S4) and the main theorems (P1, P2, P3,
G13). None of them introduces a new cryptographic assumption — they lift the
existing primitive-level guarantees to the interface an integrator or auditor
reasons about.

See [spec.md](spec.md) for the primitive-level statements; [gaps.md](gaps.md)
for tracking (entry G14).

### Sec1: Slot binding

Two slots whose interpolants commit to the same KZG value are equal.

**Statement**: For `xs : Fin (d+1) → Fr` with `Function.Injective xs` and
`b₁ b₂ : Bytes`:
```
commit (interpolate xs (serialize b₁ ∘ Fin.cast d_succ_eq_k))
  = commit (interpolate xs (serialize b₂ ∘ Fin.cast d_succ_eq_k))
→ b₁ = b₂
```

- **Lean target**: `Dal.Protocol.slot_binding`
- **Status**: `not started`
- **Proof sketch**: A6 on the two commitments gives equal interpolants. A4
  (evaluation correctness) applied at every `xs i` gives
  `serialize b₁ ∘ cast = serialize b₂ ∘ cast` pointwise. Cast cancellation
  (right-inverse of `Fin.cast`) gives `serialize b₁ = serialize b₂`. S1 closes.
- **Threat model**: Rules out any adversary producing two distinct slots that
  commit to the same L1 value. The commitment posted on L1 unambiguously
  identifies the slot.

### Sec2: Decoder determinism under adversarial shard sets

Two distinct verifying shard subsets under the same commitment reconstruct the
same polynomial — no adversarial "shard split" attack.

**Statement**: For commitment `c`, degree proof `π_deg`, two index sets
`I, I' : Finset (Fin s)` with `hI : |I| = k/l`, `hI' : |I'| = k/l`, shard
values `vs, vs'`, and shard proofs `πs, πs'`:
```
verifyDegree c d π_deg = true
→ (∀ i ∈ I,  verifyShardEval c i (vs  i) (πs  i) = true)
→ (∀ i ∈ I', verifyShardEval c i (vs' i) (πs' i) = true)
→ interpolate (cosetPoints I  hI)  (shardVals I  hI  vs)
  = interpolate (cosetPoints I' hI') (shardVals I' hI' vs')
```

- **Lean target**: `Dal.Protocol.decoder_determinism`
- **Status**: `not started`
- **Proof sketch**: Apply P3 to `(I, vs, πs)` → unique `p` with `commit p = c`
  and interpolant identity. Apply P3 to `(I', vs', πs')` → unique `p'` with
  `commit p' = c` and its interpolant identity. A6 → `p = p'`. Chain the two
  interpolant identities.
- **Threat model**: Rules out an adversary who serves different-looking but
  all-verifying shard sets to different honest verifiers, causing them to
  recover inconsistent slots.

### Sec3: Shard unforgeability (slot level)

Any shard values that verify against a commitment to a known slot are the true
shard evaluations of that slot; the accompanying proof is also unique.

**Statement**: For `b : Bytes`, distinct `xs : Fin (d+1) → Fr`, letting
`p_b := interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)` and
`c := commit p_b`:
```
verifyShardEval c i vs π = true
→ (∀ j, vs j = shardEval p_b i j) ∧ π = proveShardEval p_b i
```

- **Lean target**: `Dal.Protocol.shard_values_unforgeable`
- **Status**: `not started`
- **Proof sketch**: A7 gives `∃ p, commit p = c ∧ proveShardEval p i = π ∧
  ∀ j, shardEval p i j = vs j`. A6 on `commit p = c = commit p_b` gives
  `p = p_b`. Substitute.
- **Threat model**: Rules out fabricated shard data that still passes
  `verifyShardEval` against a genuine slot commitment.

### Sec4: Threshold robustness (MDS security / DA liveness)

If at least `k/l` honest shards are available, honest parties reconstruct the
committed slot — regardless of the remaining `s − k/l` shards.

**Statement**: For `b : Bytes`, distinct `xs : Fin (d+1) → Fr`, with
`p_b := interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)` and `c := commit p_b`,
honest shard values `vs i j := shardEval p_b i j` and proofs
`πs i := proveShardEval p_b i` for `i ∈ H` where `H : Finset (Fin s)` with
`|H| ≥ k/l`: for every `I ⊆ H` with `hI : |I| = k/l`,
```
deserialize (fun i => eval (xs (Fin.cast d_succ_eq_k.symm i))
                          (interpolate (cosetPoints I hI) (shardVals I hI vs))) = b
```

- **Lean target**: `Dal.Protocol.threshold_robustness`
- **Status**: `not started`
- **Proof sketch**: Honest shard values and proofs pass `verifyShardEval` by
  A7c. An honest degree proof exists by A3c. Apply G13 (`round_trip`) to `I`.
- **Threat model**: Data-availability liveness — an adversary controlling
  strictly fewer than `s − k/l` shards cannot prevent reconstruction.

### Sec5: Evaluation proof soundness (slot level)

Evaluation proofs cannot convince a verifier of incorrect scalar values at the
slot's evaluation points.

**Statement**: For `b : Bytes`, distinct `xs : Fin (d+1) → Fr` with
`hxs : Function.Injective xs`,
`c := commit (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k))`,
alleged evaluations `ys : Fin (d+1) → Fr`, and proofs `πs : Fin (d+1) → G1`:
```
(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
→ ∀ i, ys i = (serialize b ∘ Fin.cast d_succ_eq_k) i
```

- **Lean target**: `Dal.Protocol.page_values_sound`
- **Status**: `not started`
- **Proof sketch**: P2 gives a unique `p` with `commit p = c` and
  `proveEval p (xs i) (ys i) = some (πs i)` for all `i`. A2 applied to each `i`
  gives `eval p (xs i) = ys i`. A6 on the two commitments to `c` gives
  `p = interpolate xs (serialize b ∘ cast)`. A4 then evaluates this interpolant
  at `xs i` to `(serialize b ∘ cast) i`, so `ys i = (serialize b ∘ cast) i`.
- **Threat model**: A light-client page verifier cannot be tricked into
  believing incorrect scalar values at the page's evaluation points.

### Sec6: No fake commitments

Any commitment that passes the degree check comes from a bounded-degree
polynomial.

**Statement**:
```
verifyDegree c d π = true → ∃ p, commit p = c ∧ p.natDegree ≤ d
```

- **Lean target**: `Dal.Protocol.commitment_well_formed`
- **Status**: `not started`
- **Proof sketch**: Weakening of A3 (drop the `proveDegree p d = some π`
  conjunct).
- **Threat model**: Rules out arbitrary group elements posing as DAL
  commitments on L1. Restates A3 in the security section so that the
  "no fake commitments" guarantee is visible at this layer.

### Sec7: Proof non-malleability

Given a commitment and a query, the verifying proof is unique — an adversary
cannot produce two distinct verifying proofs for the same statement.

**Statement** (three variants):
```
verifyEval x y c π = true → verifyEval x y c π' = true → π = π'           (eval)
verifyDegree c d π = true → verifyDegree c d π' = true → π = π'           (degree)
verifyShardEval c i vs π = true → verifyShardEval c i vs π' = true → π = π'   (shard)
```

- **Lean targets**: `Dal.Protocol.eval_proof_unique`,
  `Dal.Protocol.degree_proof_unique`,
  `Dal.Protocol.shard_proof_unique`
- **Status**: `not started`
- **Proof sketch (eval)**: A1 on both hypotheses gives `p, p'` with
  `commit p = commit p' = c`, `proveEval p x y = some π`,
  `proveEval p' x y = some π'`. A6 → `p = p'`. Therefore
  `some π = some π'`, hence `π = π'`. Degree and shard cases analogous via
  A3 and A7 respectively.
- **Threat model**: Prevents malleability attacks in protocols that identify
  proofs by their bit-level contents (e.g., hashing proofs as transcript
  inputs). Under KZG, evaluation/degree/shard proofs are deterministic given
  the polynomial and query; the binding axiom (A6) pins down the polynomial,
  and the `proveX` function pins down the proof bits.

---

## Invariant preservation checklist

When modifying any Lean file, verify:

- [ ] A1–A7 and A1c, A3c, A7c are still present as `axiom` declarations
- [ ] P1, P2, and P3 still type-check (even if `sorry`-bodied)
- [ ] S1–S4 still type-check
- [ ] Sec1–Sec7 statements, once formalized, remain provable from the
      unchanged axioms (no regression of security theorems)
- [ ] No existing proved theorem has been weakened (statement made strictly weaker)
- [ ] `lake build` passes
