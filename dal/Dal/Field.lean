import Mathlib.Data.ZMod.Basic
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots

/-!
# Dal.Field

Scalar field `𝔽_r` and primitive `n`-th root of unity `ω` for the DAL formalization.

## Design

`𝔽_r` is modelled as `ZMod r` for the BLS12-381 scalar field prime `r`.

The primitive `n`-th root of unity `ω` exists in `𝔽_r` whenever `n ∣ r - 1`
(because `(ZMod r)ˣ` is cyclic of order `r - 1`).  We expose `ω` as an axiom with
its characterizing property `IsPrimitiveRoot ω n`.  This matches the treatment of
the KZG constants in `Dal/KZG.lean` (see `decisions/001-kzg-axioms.md`): cryptographic
and setup constants are axiomatized rather than constructed.

Downstream modules import this file and use `Dal.Field.Fr`, `Dal.Field.ω`, and
`Dal.Field.ω_isPrimitiveRoot`.
-/

namespace Dal.Field

/-! ### Deployment parameters

These are declared as Lean `axiom`s rather than `variable`s so that downstream
modules can refer to the concrete names `Dal.Field.r`, `Dal.Field.n`, etc. without
threading them explicitly through every function signature.
-/

/-- BLS12-381 scalar field prime order. -/
axiom r : ℕ

/-- `r` is prime. -/
axiom r_prime : Nat.Prime r

instance : Fact (Nat.Prime r) := ⟨r_prime⟩

/-- RS codeword length (`n = α · k`, `α ≥ 2`). -/
axiom n : ℕ

/-- The codeword length is positive. -/
axiom n_pos : 0 < n

/-- `n` divides `r - 1`, which is the order of the multiplicative group `𝔽_r*`.
    This is the necessary and sufficient condition for a primitive `n`-th root of
    unity to exist in `𝔽_r`. -/
axiom n_dvd_r_sub_one : n ∣ r - 1

/-! ### Scalar field -/

/-- The scalar field `𝔽_r = ℤ/rℤ`. -/
abbrev Fr := ZMod r

/-! ### Primitive root of unity -/

/-- A primitive `n`-th root of unity in `𝔽_r`.
    Existence follows from the fact that `(ZMod r)ˣ` is cyclic of order `r - 1`
    and `n ∣ r - 1`, but we axiomatize it here for simplicity (see design note). -/
axiom ω : Fr

/-- `ω` is a primitive `n`-th root of unity: `ω ^ n = 1` and `ω` has order exactly
    `n` (i.e., `ω ^ m ≠ 1` for any `0 < m < n`). -/
axiom ω_isPrimitiveRoot : IsPrimitiveRoot (ω : Fr) n

/-! ### Derived lemmas from `IsPrimitiveRoot` -/

/-- `ω ^ n = 1`. -/
theorem ω_pow_n : (ω : Fr) ^ n = 1 :=
  ω_isPrimitiveRoot.pow_eq_one

/-- The order of `ω` is exactly `n`. -/
theorem ω_orderOf : orderOf (ω : Fr) = n :=
  ω_isPrimitiveRoot.eq_orderOf.symm

/-- Powers `ω ^ i` and `ω ^ j` with `i, j < n` are equal iff `i = j`. -/
theorem ω_pow_inj {i j : ℕ} (hi : i < n) (hj : j < n) : (ω : Fr) ^ i = (ω : Fr) ^ j ↔ i = j :=
  ⟨ω_isPrimitiveRoot.pow_inj hi hj, fun h => h ▸ rfl⟩

end Dal.Field
