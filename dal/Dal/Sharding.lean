import Dal.Field
import Dal.Poly
import Mathlib.Algebra.Polynomial.Roots

/-!
# Dal.Sharding

Coset structure of the evaluation domain, vanishing polynomials, and the structural
properties S2 (coset partition) and S3 (vanishing polynomial roots).

## Contents

- `cosetPoint`              — `j`-th point of coset `i`: `ω^(i + s·j)`
- `Ω`                       — coset `i` as a finset: `{cosetPoint i j | j < l}`
- `Z`                       — vanishing polynomial `Z_i = X^l − C(ω^(i·l))`
- `shardEval`               — evaluations of `p` at all points of coset `i`
- `s_mul_l_eq_n`            — arithmetic: `s · l = n`
- `ωs_isPrimitiveRoot`      — `ω^s` is a primitive `l`-th root of unity
- `vanishing_poly_roots`    — S3: `Z_i(x) = 0 ↔ x ∈ Ω_i`
- `coset_partition`         — S2: evaluation domain = `⊔ Ω_i`
- `cosets_disjoint`         — S2: distinct cosets are disjoint

## Design

`cosetPoint i j = ω^(i.val + s·j.val)`, matching `docs/protocol.md` §Sharding and the
coset definition `Ω_i = ω^i · Ω_0` where `Ω_0 = {ω^(sj) : j < l}`.

S3 is proved using `IsPrimitiveRoot.nthRoots_eq`, which characterises the roots of
`X^l − a` as `{ζ^j · α : j < l}` whenever `ζ` is a primitive `l`-th root of unity
and `α^l = a`.  S2 follows from the Euclidean-division bijection on `{0, …, n−1}`.

The full invariant statements are given by the theorem signatures below.
-/

namespace Dal.Sharding

open Dal.Field Dal.Poly Polynomial

/-! ### Arithmetic lemmas -/

/-- `s · l = n`: shard count times shard length equals codeword length. -/
lemma s_mul_l_eq_n : s * l = n := by
  have h := Nat.div_mul_cancel s_dvd_n   -- n / s * s = n
  rw [← l_eq] at h                       -- l * s = n
  linarith

/-- `l ∣ n` (since `s · l = n`). -/
lemma l_dvd_n : l ∣ n := ⟨s, by rw [mul_comm]; exact s_mul_l_eq_n.symm⟩

/-- Every coset index `i + s·j` lies in `{0, …, n−1}`. -/
lemma coset_index_lt (i : Fin s) (j : Fin l) : i.val + s * j.val < n := by
  calc i.val + s * j.val
      < s + s * j.val     := by omega
    _ = s * (j.val + 1)   := by ring
    _ ≤ s * l             := Nat.mul_le_mul_left s (by omega)
    _ = n                 := s_mul_l_eq_n

/-! ### Primitive root for cosets -/

/-- `ω^s` is a primitive `l`-th root of unity.
    Derived from `ω_isPrimitiveRoot` via `IsPrimitiveRoot.pow` with `n = s · l`. -/
lemma ωs_isPrimitiveRoot : IsPrimitiveRoot (ω ^ s) l :=
  ω_isPrimitiveRoot.pow n_pos s_mul_l_eq_n.symm

/-! ### Definitions -/

/-- The `j`-th point of coset `i`: `ω^(i + s·j)`. -/
noncomputable def cosetPoint (i : Fin s) (j : Fin l) : Fr := ω ^ (i.val + s * j.val)

/-- Coset `i` of the evaluation domain: the finset `{cosetPoint i j | j < l}`. -/
noncomputable def Ω (i : Fin s) : Finset Fr := Finset.image (cosetPoint i) Finset.univ

/-- Vanishing polynomial for coset `i`: `Z_i(x) = x^l − ω^(i·l)`.
    Its roots are exactly the elements of `Ω_i`. -/
noncomputable def Z (i : Fin s) : Poly :=
  Polynomial.X ^ l - Polynomial.C (ω ^ (i.val * l))

/-- Evaluations of `p` at all `l` points of coset `i`. -/
noncomputable def shardEval (p : Poly) (i : Fin s) (j : Fin l) : Fr :=
  Polynomial.eval (cosetPoint i j) p

/-! ### S3: Vanishing polynomial roots -/

/-- **S3**: The vanishing polynomial `Z_i` has exactly the elements of coset `Ω_i` as
    roots: `Z_i(x) = 0 ↔ x ∈ Ω_i`.

    **Proof sketch**:
    - `(←)` Direct calculation: `(cosetPoint i j)^l = ω^((i+sj)·l) = ω^(il) · (ω^n)^j = ω^(il)`.
    - `(→)` Apply `IsPrimitiveRoot.nthRoots_eq` with `ζ = ω^s`, `α = ω^i`: the `l`-th
      roots of `ω^(il)` are exactly `{(ω^s)^j · ω^i : j < l} = {cosetPoint i j}`. -/
theorem vanishing_poly_roots (i : Fin s) (x : Fr) :
    Polynomial.eval x (Z i) = 0 ↔ x ∈ Ω i := by
  constructor
  · -- (→) Zero of Z_i  ⟹  member of Ω_i
    intro heval
    simp only [Z, eval_sub, eval_pow, eval_X, eval_C] at heval
    -- heval : x ^ l - ω ^ (i.val * l) = 0
    have hxl : x ^ l = ω ^ (i.val * l) := sub_eq_zero.mp heval
    -- x is an l-th root of ω^(i·l)
    have hmem : x ∈ Polynomial.nthRoots l (ω ^ (i.val * l)) :=
      (Polynomial.mem_nthRoots l_pos).mpr hxl
    -- The l-th roots of ω^(il) are exactly {(ω^s)^j · ω^i : j < l}
    rw [ωs_isPrimitiveRoot.nthRoots_eq (pow_mul ω i.val l).symm] at hmem
    obtain ⟨j, hj, hjval⟩ := Multiset.mem_map.mp hmem
    rw [Multiset.mem_range] at hj
    -- (ω^s)^j · ω^i.val = cosetPoint i ⟨j, hj⟩
    have hcpt : cosetPoint i ⟨j, hj⟩ = (ω ^ s) ^ j * ω ^ i.val := by
      unfold cosetPoint
      simp only [← pow_mul, ← pow_add, add_comm (s * j) i.val]
    simp only [Ω, Finset.mem_image, Finset.mem_univ, true_and]
    exact ⟨⟨j, hj⟩, hcpt.trans hjval⟩
  · -- (←) Member of Ω_i  ⟹  zero of Z_i
    intro hmem
    simp only [Ω, Finset.mem_image, Finset.mem_univ, true_and] at hmem
    obtain ⟨j, rfl⟩ := hmem
    simp only [Z, eval_sub, eval_pow, eval_X, eval_C]
    rw [sub_eq_zero]
    -- Goal: (cosetPoint i j) ^ l = ω ^ (i.val * l)
    unfold cosetPoint
    rw [← pow_mul]
    -- Goal: ω ^ ((i.val + s * j.val) * l) = ω ^ (i.val * l)
    have heq : (i.val + s * j.val) * l = i.val * l + j.val * n := by
      calc (i.val + s * j.val) * l
          = i.val * l + j.val * (s * l) := by ring
        _ = i.val * l + j.val * n       := by rw [s_mul_l_eq_n]
    rw [heq, pow_add]
    have hjn : ω ^ (j.val * n) = 1 := by
      rw [mul_comm (j.val) n, pow_mul, ω_pow_n, one_pow]
    rw [hjn, mul_one]

/-! ### S2: Coset partition -/

/-- **S2 (union)**: The evaluation domain `{ω^m : m < n}` equals the union of all cosets. -/
theorem coset_partition :
    Finset.image (fun m : Fin n => ω ^ m.val) Finset.univ =
    (Finset.univ : Finset (Fin s)).biUnion Ω := by
  ext x
  simp only [Finset.mem_image, Finset.mem_univ, true_and, Finset.mem_biUnion,
             Ω, Finset.mem_image, Finset.mem_univ, true_and]
  constructor
  · -- Forward: split m by Euclidean division to find coset i and position j
    rintro ⟨m, rfl⟩
    have hms : m.val % s < s := Nat.mod_lt _ s_pos
    have hls : m.val / s < l := by
      rw [Nat.div_lt_iff_lt_mul s_pos, mul_comm]
      linarith [m.isLt, s_mul_l_eq_n]
    exact ⟨⟨m.val % s, hms⟩, ⟨m.val / s, hls⟩,
           by unfold cosetPoint; congr 1; exact Nat.mod_add_div m.val s⟩
  · -- Backward: cosetPoint i j lives in the evaluation domain
    rintro ⟨i, j, rfl⟩
    exact ⟨⟨i.val + s * j.val, coset_index_lt i j⟩, by unfold cosetPoint; rfl⟩

/-- **S2 (disjointness)**: Distinct cosets are disjoint. -/
theorem cosets_disjoint (i j : Fin s) (hij : i ≠ j) : Disjoint (Ω i) (Ω j) := by
  rw [Finset.disjoint_left]
  intro x hxi hxj
  simp only [Ω, Finset.mem_image, Finset.mem_univ, true_and] at hxi hxj
  obtain ⟨a, rfl⟩ := hxi
  obtain ⟨b, hb⟩ := hxj
  -- hb : cosetPoint j b = cosetPoint i a
  unfold cosetPoint at hb
  -- ω^(j.val + s*b.val) = ω^(i.val + s*a.val)
  have heq : j.val + s * b.val = i.val + s * a.val :=
    (ω_pow_inj (coset_index_lt j b) (coset_index_lt i a)).mp hb
  -- Translate to ℤ and use |j.val − i.val| < s together with s ∣ (j.val − i.val)
  have hj_lt := j.isLt
  have hi_lt := i.isLt
  have hint : (j.val : ℤ) + s * b.val = i.val + s * a.val := by exact_mod_cast heq
  have hdiff : (j.val : ℤ) - i.val = s * ((a.val : ℤ) - b.val) := by linarith
  have hdvd : (s : ℤ) ∣ ((j.val : ℤ) - i.val) := ⟨(a.val : ℤ) - b.val, hdiff⟩
  have habs : |(↑j.val - ↑i.val : ℤ)| < (s : ℤ) := by
    rw [abs_lt]
    constructor
    · have h1 : (0 : ℤ) ≤ j.val := Int.natCast_nonneg _
      have h2 : (i.val : ℤ) < s := by exact_mod_cast hi_lt
      linarith
    · have h1 : (0 : ℤ) ≤ i.val := Int.natCast_nonneg _
      have h2 : (j.val : ℤ) < s := by exact_mod_cast hj_lt
      linarith
  have h0 := Int.eq_zero_of_abs_lt_dvd hdvd habs
  -- h0 : (j.val : ℤ) - i.val = 0
  have hjeq : j.val = i.val := by exact_mod_cast (show (j.val : ℤ) = i.val by linarith)
  exact hij (Fin.ext hjeq).symm

end Dal.Sharding
