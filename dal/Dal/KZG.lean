import Dal.Field
import Dal.Poly

/-!
# Dal.KZG

KZG polynomial commitment scheme: opaque group types, commitment and proof
functions, and the four security axioms A1–A3, A6.

## Contents

- `G1`, `G2`, `GT`         — opaque BLS12-381 group types
- `Commitment`, `Proof`    — type aliases for `G1`
- `commit`                 — polynomial commitment function
- `proveEval`              — evaluation proof function
- `verifyEval`             — evaluation proof verifier
- `proveDegree`            — degree proof function
- `verifyDegree`           — degree proof verifier
- `verifyEval_soundness`   — A1 (axiom)
- `proveEval_complete`     — A2 (axiom)
- `verifyDegree_soundness` — A3 (axiom)
- `commit_binding`         — A6 (axiom)

## Design

All group types and KZG functions are opaque (`axiom`): formalizing BLS12-381
or the KZG computation would require a verified cryptography library that is
out of scope. The four security axioms are the only things needed to prove P1
and P2 at the protocol level. See `decisions/001-kzg-axioms.md`.

Note: `spec.md` and `properties.md` both list A2 as an axiom (alongside A1, A3,
A6). Decision 001 mentions only three axioms (A1, A3, A6), which is an oversight
— A2 is also axiomatized here since `proveEval` is opaque.
-/

namespace Dal.KZG

open Dal.Field Dal.Poly

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
    violate under `d`-SDH. See `decisions/001-kzg-axioms.md`. -/
axiom commit_binding (p q : Poly) :
    commit p = commit q → p = q

end Dal.KZG
