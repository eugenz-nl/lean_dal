import Mathlib.Data.ZMod.Basic
import Mathlib.FieldTheory.Finite.Basic
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots

/-!
# Dal.Field

Scalar field `𝔽_r`, all deployment parameters, and the primitive `n`-th root of
unity `ω` for the DAL formalization.

## Design

All global DAL deployment parameters are declared as `axiom` here so that every
downstream module (`Poly`, `KZG`, `Sharding`, …) can refer to them by name after a
single `import Dal.Field`, without threading them through every signature.

`𝔽_r` is modelled as `ZMod r`.  `ω` is axiomatized via `IsPrimitiveRoot ω n`.
Existence of a primitive `n`-th root follows from the cyclic structure of `(ZMod r)ˣ`
and `n ∣ r − 1`, but axiomatizing it is consistent with the treatment of KZG
constants and avoids Mathlib API work that is out of scope here.

## Parameters exposed by this module

- `r`, `r_prime`                          — scalar field prime
- `k`, `n`, `s`, `l`, `α`, `slot_size`   — RS / sharding dimensions
- `d`                                     — degree bound (`d = k - 1`)
- Constraints: `n_dvd_r_sub_one`, `s_dvd_n`, `alpha_eq`, `d_eq`, `l_eq`,
  `alpha_ge_two`, `d_ge_2l`, `l_dvd_k`
- `ω`, `ω_isPrimitiveRoot`                — primitive root of unity
-/

namespace Dal.Field

/-! ### Deployment parameters

All declared as `axiom` so downstream modules can use bare names without
threading parameters through every function signature.
-/

/-- BLS12-381 scalar field prime order. -/
axiom r : ℕ

/-- `r` is prime. -/
axiom r_prime : Nat.Prime r

instance : Fact (Nat.Prime r) := ⟨r_prime⟩

/-- Number of scalars encoding a slot (`k ≈ slot_size / 31`). -/
axiom k : ℕ

/-- RS codeword length (`n = α · k`). -/
axiom n : ℕ

/-- Number of shards. -/
axiom s : ℕ

/-- Shard length in evaluations (`l = n / s`). -/
axiom l : ℕ

/-- Redundancy factor (`α = n / k`). -/
axiom α : ℕ

/-- Byte size of a slot. -/
axiom slot_size : ℕ

/-- Degree bound of the committed polynomial (`d = k - 1`). -/
axiom d : ℕ

/-! ### Parameter constraints -/

/-- `n` divides `r - 1`: necessary and sufficient for a primitive `n`-th root of
    unity to exist in `𝔽_r`. -/
axiom n_dvd_r_sub_one : n ∣ r - 1

/-- `s` divides `n`: required so that cosets partition the evaluation domain evenly. -/
axiom s_dvd_n : s ∣ n

/-- `α = n / k`: redundancy factor definition. -/
axiom alpha_eq : α = n / k

/-- `d = k - 1`: degree bound is one less than the message length. -/
axiom d_eq : d = k - 1

/-- `l = n / s`: shard length definition. -/
axiom l_eq : l = n / s

/-- `α ≥ 2`: minimum redundancy for MDS recovery. -/
axiom alpha_ge_two : 2 ≤ α

/-- `d ≥ 2 * l`: required by the multi-reveal proof construction. -/
axiom d_ge_2l : 2 * l ≤ d

/-- `l ∣ k`: ensures `k / l` is exact, needed for S4 (shard recovery). -/
axiom l_dvd_k : l ∣ k

/-- `k` is positive (follows from `slot_size > 0` and serialization, but axiomatized
    here for convenience). -/
axiom k_pos : 0 < k

/-- `n` is positive (follows from `n = α * k ≥ 2 * 1`). -/
axiom n_pos : 0 < n

/-- `s` is positive. -/
axiom s_pos : 0 < s

/-- `l` is positive. -/
axiom l_pos : 0 < l

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
