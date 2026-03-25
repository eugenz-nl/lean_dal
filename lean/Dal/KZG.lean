import Dal.Field
import Dal.Poly
import Dal.Sharding

/-!
# Dal.KZG

KZG polynomial commitment scheme: opaque group types, commitment and proof
functions, and the five security axioms A1–A3, A6, A7.

## Contents

- `G1`, `G2`, `GT`                — opaque BLS12-381 group types
- `Commitment`, `Proof`           — type aliases for `G1`
- `commit`                        — polynomial commitment function
- `proveEval`                     — evaluation proof function
- `verifyEval`                    — evaluation proof verifier
- `proveDegree`                   — degree proof function
- `verifyDegree`                  — degree proof verifier
- `shardRemainder`                — euclidean remainder of `p` by `Z_i`
- `proveShardEval`                — multi-reveal shard proof function
- `verifyShardEval`               — multi-reveal shard proof verifier
- `verifyEval_soundness`          — A1 (axiom)
- `proveEval_complete`            — A2 (axiom)
- `verifyDegree_soundness`        — A3 (axiom)
- `commit_binding`                — A6 (axiom)
- `verifyShardEval_soundness`     — A7 (axiom)

## Design

All group types and KZG functions are opaque (`axiom`): formalizing BLS12-381
or the KZG computation would require a verified cryptography library that is
out of scope. The five security axioms (A1–A3, A6, A7) are the only things
needed to prove P1, P2, and P3 at the protocol level; they follow from the
`d`-strong Diffie-Hellman assumption over BLS12-381, which is a computational
hardness assumption outside the scope of this formalization.

Note: A2 must also be axiomatized because `proveEval` is opaque — its
completeness cannot be derived from the type alone.
-/

namespace Dal.KZG

open Dal.Field Dal.Poly Dal.Sharding

/-! ### Elliptic curve groups (opaque)

These are the three groups of the BLS12-381 pairing. Their internal structure
(curve equation, group law) is irrelevant to the protocol-level formalization.
-/

/-- First elliptic curve group `𝔾_1` of BLS12-381. Commitments and proofs live here. -/
axiom G1 : Type

/-- Second elliptic curve group `𝔾_2` of BLS12-381. Verifying key lives here. -/
axiom G2 : Type

/-- Target group `𝔾_T` of BLS12-381. Pairing outputs live here. -/
axiom GT : Type

/-! ### Type aliases -/

/-- A KZG commitment: an element of `𝔾_1`. -/
abbrev Commitment := G1

/-- A KZG proof (evaluation or degree): an element of `𝔾_1`. -/
abbrev KZGProof := G1

/-! ### KZG functions (opaque)

These are the five KZG scheme operations. Their implementations involve the
elliptic curve arithmetic and the SRS; all are axiomatized. -/

/-- Polynomial commitment: `commit p = [p(τ)]_1 = Σᵢ pᵢ · [τⁱ]₁`. -/
axiom commit : Poly → G1

/-- Evaluation proof: returns `some π` when `Polynomial.eval x p = y`
    (where `π = [(p − y)/(X − x)](τ)]₁`), and `none` otherwise. -/
axiom proveEval : Poly → Fr → Fr → Option G1

/-- Evaluation verifier: checks `e(c − [y]₁, g₂) = e(π, [τ]₂ − [x]₂)`. -/
axiom verifyEval : Fr → Fr → G1 → G1 → Bool

/-- Degree proof: returns `some π` when `p.natDegree ≤ bound`, `none` otherwise. -/
axiom proveDegree : Poly → ℕ → Option G1

/-- Degree verifier: checks the degree bound proof. -/
axiom verifyDegree : G1 → ℕ → G1 → Bool

/-! ### Multi-reveal shard proof functions (opaque)

These implement the efficient multi-reveal protocol: a single proof `π_i` certifies
all `l` evaluations of `p` on coset `Ω_i`. See `spec.md §Sharding` and gaps G8–G9.
-/

/-- Shard remainder: the unique polynomial of degree `< l` such that
    `p ≡ shardRemainder p i  (mod Z_i)`, i.e. the euclidean remainder of
    division by the vanishing polynomial `Z i`. -/
axiom shardRemainder : Poly → Fin s → Poly

/-- Multi-reveal shard proof: `proveShardEval p i = [q_i(τ)]_1` where
    `q_i = (p − shardRemainder p i) / Z_i`. -/
axiom proveShardEval : Poly → Fin s → G1

/-- Multi-reveal shard verifier: checks
    `e(c − [r_i(τ)]_1, g_2) = e(π, [τ^l]_2 − [ω^{il}]_2)`
    where `r_i` is reconstructed from the claimed evaluations `vs`. -/
axiom verifyShardEval : G1 → Fin s → (Fin l → Fr) → G1 → Bool

/-! ### Security axioms -/

/-- **A1 — Eval soundness**: a valid evaluation proof implies the existence of a
    committed polynomial with the claimed evaluation at the claimed point.
    Follows from the `d`-SDH assumption; cannot be proved in pure Lean. -/
axiom verifyEval_soundness (x y : Fr) (c π : G1) :
    verifyEval x y c π = true →
    ∃ p : Poly, commit p = c ∧ proveEval p x y = some π

/-- **A2 — Eval completeness**: `proveEval` returns `some` exactly when the
    claimed evaluation holds. Axiomatized because `proveEval` is opaque. -/
axiom proveEval_complete (p : Poly) (x y : Fr) :
    (∃ π : G1, proveEval p x y = some π) ↔ Polynomial.eval x p = y

/-- **A3 — Degree soundness**: a valid degree proof implies the polynomial has
    `natDegree ≤ bound`. Follows from the `d`-SDH assumption. -/
axiom verifyDegree_soundness (c π : G1) (bound : ℕ) :
    verifyDegree c bound π = true →
    ∃ p : Poly, commit p = c ∧ p.natDegree ≤ bound ∧ proveDegree p bound = some π

/-- **A6 — Commitment binding**: two polynomials with the same commitment are
    equal. Technically false in pure math but computationally infeasible to
    violate under the `d`-SDH assumption. -/
axiom commit_binding (p q : Poly) :
    commit p = commit q → p = q

/-- **A1c — Eval completeness (verifier)**: an honest prover's evaluation proof always
    passes verification. Axiomatized because `verifyEval` is opaque; follows from the
    algebraic correctness of the KZG pairing equation. -/
axiom verifyEval_complete (p : Poly) (x : Fr) (π : G1) :
    proveEval p x (Polynomial.eval x p) = some π →
    verifyEval x (Polynomial.eval x p) (commit p) π = true

/-- **A3c — Degree completeness**: if `p.natDegree ≤ bound`, then `proveDegree`
    produces a proof that `verifyDegree` accepts. Axiomatized because both functions
    are opaque; follows from algebraic correctness of the degree proof construction. -/
axiom proveDegree_complete (p : Poly) (bound : ℕ) :
    p.natDegree ≤ bound →
    ∃ π : G1, proveDegree p bound = some π ∧ verifyDegree (commit p) bound π = true

/-- **A7c — Shard eval completeness**: an honest prover's shard proof always passes
    verification. Axiomatized because `verifyShardEval` is opaque; follows from the
    algebraic correctness of the multi-reveal pairing equation. -/
axiom verifyShardEval_complete (p : Poly) (i : Fin s) :
    verifyShardEval (commit p) i (fun j => shardEval p i j) (proveShardEval p i) = true

/-- **A7 — Shard eval soundness**: a valid shard proof implies the existence of
    a committed polynomial whose evaluations on `Ω_i` equal the claimed values.
    Multi-reveal analogue of A1. Rests on the `d`-SDH assumption.
    Note: no degree bound is included — the multi-reveal verification equation
    does not enforce a degree bound. P3 obtains the degree bound separately via
    an explicit `verifyDegree` hypothesis (mirroring P1). -/
axiom verifyShardEval_soundness (c : G1) (i : Fin s) (vs : Fin l → Fr) (π : G1) :
    verifyShardEval c i vs π = true →
    ∃ p : Poly, commit p = c ∧ proveShardEval p i = π ∧
                ∀ j : Fin l, shardEval p i j = vs j

end Dal.KZG
