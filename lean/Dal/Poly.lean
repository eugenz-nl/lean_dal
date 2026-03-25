import Dal.Field
import Mathlib.LinearAlgebra.Lagrange

/-!
# Dal.Poly

Polynomial type `Poly`, Lagrange interpolation, and the two provable lemmas A4 and A5.

## Contents

- `Poly`                   — type alias `Polynomial Fr`
- `interpolate`            — Lagrange interpolation at `d+1` distinct nodes
- `interpolate_eval`       — A4 (eval): the interpolant evaluates correctly at each node
- `interpolate_natDegree`  — A4 (degree): the interpolant has `natDegree ≤ d`
- `poly_unique_of_eval`    — A5: two polys of `natDegree ≤ d` agreeing on `d+1`
                             distinct points are equal

## Design

Uses Mathlib's `Lagrange.interpolate` over `Finset.univ (α := Fin (d + 1))`.
All theorems require the evaluation points to be distinct: `Function.Injective xs`.
KZG functions and protocol proofs operate on `Poly` directly; serialization converts
bytes to/from field element arrays separately, keeping the algebraic layer clean.

## Mathlib API notes

- `Lagrange.eval_interpolate_at_node (r : ι → F) (hvs) (hi)` — `r` (values) is the
  first explicit argument (section variable), then `hvs` (injectivity), then `hi`
  (membership).
- `Lagrange.degree_interpolate_lt (r : ι → F) (hvs)` — same ordering.
- `Polynomial.eq_of_degrees_lt_of_eval_index_eq (s) (hvs) ...` — lives in
  `namespace Polynomial` (not `Lagrange`), and `s` is explicit.
-/

namespace Dal.Poly

open Dal.Field

set_option linter.dupNamespace false

/-! ### Polynomial type -/

/-- Polynomials over the scalar field `𝔽_r`. -/
abbrev Poly := Polynomial Fr

/-! ### Interpolation -/

/-- Lagrange interpolation: given `d+1` distinct evaluation points `xs` and values
    `ys`, returns the unique polynomial of `natDegree ≤ d` passing through them.
    Wraps `Lagrange.interpolate` over `Finset.univ (α := Fin (d + 1))`. -/
noncomputable def interpolate
    (xs : Fin (d + 1) → Fr) (ys : Fin (d + 1) → Fr) : Poly :=
  Lagrange.interpolate Finset.univ xs ys

/-! ### A4: Interpolation correctness -/

/-- **A4 (eval)**: the interpolant evaluates to `ys i` at each node `xs i`.
    Requires the nodes to be distinct (`hxs : Function.Injective xs`). -/
theorem interpolate_eval
    (xs : Fin (d + 1) → Fr) (ys : Fin (d + 1) → Fr)
    (hxs : Function.Injective xs) (i : Fin (d + 1)) :
    Polynomial.eval (xs i) (interpolate xs ys) = ys i := by
  -- Note: in Lagrange.Interpolate section, `r` (values) is the first explicit arg.
  simp only [interpolate]
  exact Lagrange.eval_interpolate_at_node ys hxs.injOn (Finset.mem_univ i)

/-- **A4 (degree)**: the interpolant has `natDegree ≤ d`.
    Requires the nodes to be distinct (`hxs : Function.Injective xs`). -/
theorem interpolate_natDegree
    (xs : Fin (d + 1) → Fr) (ys : Fin (d + 1) → Fr)
    (hxs : Function.Injective xs) :
    (interpolate xs ys).natDegree ≤ d := by
  change (Lagrange.interpolate Finset.univ xs ys).natDegree ≤ d
  have hdeg : (Lagrange.interpolate Finset.univ xs ys).degree <
              ↑(Finset.univ (α := Fin (d + 1))).card :=
    Lagrange.degree_interpolate_lt ys hxs.injOn
  simp only [Finset.card_univ, Fintype.card_fin] at hdeg
  rcases eq_or_ne (Lagrange.interpolate Finset.univ xs ys) 0 with h0 | h0
  · simp [h0]
  · have hlt : (Lagrange.interpolate Finset.univ xs ys).natDegree < d + 1 := by
      rw [Polynomial.degree_eq_natDegree h0] at hdeg
      exact_mod_cast hdeg
    omega

/-! ### A5: Polynomial uniqueness -/

/-- **A5**: two polynomials of `natDegree ≤ d` that agree on `d+1` distinct
    points are equal. -/
theorem poly_unique_of_eval
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (p q : Poly)
    (hp : p.natDegree ≤ d) (hq : q.natDegree ≤ d)
    (heval : ∀ i : Fin (d + 1),
        Polynomial.eval (xs i) p = Polynomial.eval (xs i) q) :
    p = q := by
  -- Polynomial.eq_of_degrees_lt_of_eval_index_eq lives in namespace Polynomial;
  -- s : Finset ι is its first explicit argument.
  apply Polynomial.eq_of_degrees_lt_of_eval_index_eq
    (Finset.univ (α := Fin (d + 1))) hxs.injOn
  · -- p.degree < #Finset.univ = d + 1
    simp only [Finset.card_univ, Fintype.card_fin]
    calc p.degree ≤ ↑p.natDegree := Polynomial.degree_le_natDegree
        _ ≤ ↑d        := by exact_mod_cast hp
        _ < ↑(d + 1)  := by exact_mod_cast Nat.lt_succ_self d
  · -- q.degree < d + 1
    simp only [Finset.card_univ, Fintype.card_fin]
    calc q.degree ≤ ↑q.natDegree := Polynomial.degree_le_natDegree
        _ ≤ ↑d        := by exact_mod_cast hq
        _ < ↑(d + 1)  := by exact_mod_cast Nat.lt_succ_self d
  · -- p and q agree at every node
    intro i _
    exact heval i

end Dal.Poly
