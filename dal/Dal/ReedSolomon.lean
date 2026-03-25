import Dal.Field
import Dal.Poly
import Dal.Sharding

/-!
# Dal.ReedSolomon

Reed-Solomon encoding and S4 (shard recovery / MDS property).

## Contents

- `rsEncode`              — evaluate `p` at all `n` roots of unity: `rsEncode p i = p(ω^i)`
- `cosetPoints`           — enumerate `d+1 = k` evaluation points from `k/l` cosets
- `shardVals`             — collect shard values in the same enumeration order
- `cosetPoint_mem_Ω`     — each coset point belongs to its coset
- `cosetPoints_injective` — the `d+1` enumerated points are pairwise distinct
- `shard_recovery`        — **S4**: any `k/l` shards recover the polynomial

## Design

`cosetPoints I hI` and `shardVals I hI vs` enumerate the `k = (k/l)·l = d+1`
evaluation points and values as `Fin (d+1) → Fr`, matching the argument type of
`Dal.Poly.interpolate`.  Point `m` comes from coset `I[⌊m/l⌋]` (using
`Finset.orderIsoOfFin` to sort `I`) at position `m % l` within that coset.

S4 reduces to `poly_unique_of_eval` (A5): the interpolated polynomial is the unique
degree-`≤ d` polynomial with the given evaluations at `d+1` distinct coset points.
Distinctness uses `cosets_disjoint` (S2) for cross-coset pairs and `ω_pow_inj` for
within-coset pairs.

The full theorem statements are given by the signatures below.
-/

namespace Dal.ReedSolomon

open Dal.Field Dal.Poly Dal.Sharding Polynomial

/-! ### Arithmetic lemmas -/

/-- `d + 1 = k`. -/
private lemma d_succ_eq_k : d + 1 = k := by
  have := d_eq; have := k_pos; omega

/-- `k / l * l = d + 1`: `k/l` cosets of `l` points cover exactly `k = d+1` points. -/
private lemma kl_eq_d_succ : k / l * l = d + 1 :=
  (Nat.div_mul_cancel l_dvd_k).trans d_succ_eq_k.symm

/-- `m.val / l < k / l` for `m : Fin (d + 1)`. -/
private lemma m_div_lt (m : Fin (d + 1)) : m.val / l < k / l := by
  have hm : m.val < k / l * l := kl_eq_d_succ.symm ▸ m.isLt
  exact (Nat.div_lt_iff_lt_mul l_pos).mpr hm

/-- `m.val % l < l` for `m : Fin (d + 1)`. -/
private lemma m_mod_lt (m : Fin (d + 1)) : m.val % l < l :=
  Nat.mod_lt _ l_pos

/-! ### RS encoding -/

/-- Reed-Solomon encoding: evaluate `p` at the `n` roots of unity `{ω^i : i < n}`.
    `rsEncode p i = p(ω^i)`. -/
noncomputable def rsEncode (p : Poly) (i : Fin n) : Fr :=
  Polynomial.eval (ω ^ i.val) p

/-! ### S4 helper functions -/

/-- The `d+1` evaluation points for S4: point `m` is the `(m % l)`-th element of
    coset `I[⌊m/l⌋]`, using `Finset.orderIsoOfFin` to enumerate `I` in sorted order. -/
noncomputable def cosetPoints (I : Finset (Fin s)) (hI : I.card = k / l)
    (m : Fin (d + 1)) : Fr :=
  cosetPoint ((I.orderIsoOfFin hI ⟨m.val / l, m_div_lt m⟩).val)
             ⟨m.val % l, m_mod_lt m⟩

/-- The `d+1` shard values for S4: `vs` collected in the same order as `cosetPoints`. -/
noncomputable def shardVals (I : Finset (Fin s)) (hI : I.card = k / l)
    (vs : Fin s → Fin l → Fr) (m : Fin (d + 1)) : Fr :=
  vs ((I.orderIsoOfFin hI ⟨m.val / l, m_div_lt m⟩).val)
     ⟨m.val % l, m_mod_lt m⟩

/-! ### Supporting lemmas -/

/-- Each coset point belongs to its coset: `cosetPoint i j ∈ Ω i`. -/
lemma cosetPoint_mem_Ω (i : Fin s) (j : Fin l) : cosetPoint i j ∈ Ω i := by
  simp only [Ω, Finset.mem_image, Finset.mem_univ, true_and]
  exact ⟨j, rfl⟩

/-- The `d+1` enumerated coset points are pairwise distinct.

    **Proof**: Suppose `cosetPoints I hI m1 = cosetPoints I hI m2`.
    - If the two coset indices differ (`i1 ≠ i2`): the points lie in different cosets,
      which are disjoint by `cosets_disjoint` — contradiction.
    - If the coset indices agree (`i1 = i2`): `ω_pow_inj` forces equal positions, so
      `m1.val % l = m2.val % l`.  Combined with `m1.val / l = m2.val / l` (from coset
      index equality), Euclidean division uniqueness gives `m1 = m2`. -/
lemma cosetPoints_injective (I : Finset (Fin s)) (hI : I.card = k / l) :
    Function.Injective (cosetPoints I hI) := by
  intro m1 m2 heq
  simp only [cosetPoints] at heq
  -- Local names for the two coset-array indices
  let e := I.orderIsoOfFin hI
  let ia1 : Fin (k / l) := ⟨m1.val / l, m_div_lt m1⟩
  let ia2 : Fin (k / l) := ⟨m2.val / l, m_div_lt m2⟩
  -- heq : cosetPoint (e ia1).val ⟨m1.val % l, _⟩ = cosetPoint (e ia2).val ⟨m2.val % l, _⟩
  by_cases hi : (e ia1).val = (e ia2).val
  · -- Same coset: back out ia1 = ia2, then show m1.val % l = m2.val % l.
    have hia : ia1 = ia2 :=
      e.toEquiv.injective (Subtype.val_inj.mp hi)
    have hdiv : m1.val / l = m2.val / l := congr_arg Fin.val hia
    -- Rewrite RHS of heq to use (e ia1).val
    rw [show (e ia2).val = (e ia1).val from hi.symm] at heq
    -- heq : cosetPoint (e ia1).val ⟨m1%l,_⟩ = cosetPoint (e ia1).val ⟨m2%l,_⟩
    unfold cosetPoint at heq
    have hpow :=
      (ω_pow_inj (coset_index_lt (e ia1).val ⟨m1.val % l, m_mod_lt m1⟩)
                 (coset_index_lt (e ia1).val ⟨m2.val % l, m_mod_lt m2⟩)).mp heq
    -- hpow : (e ia1).val.val + s * (m1.val % l) = (e ia1).val.val + s * (m2.val % l)
    have hmul : s * (m1.val % l) = s * (m2.val % l) := by linarith
    have hmod : m1.val % l = m2.val % l := Nat.eq_of_mul_eq_mul_left s_pos hmul
    -- Recover m1.val = m2.val from Euclidean division uniqueness.
    -- l * (m1/l) = l * (m2/l) from hdiv; l*(·) is nonlinear so linarith handles it.
    have hm1 := Nat.div_add_mod m1.val l  -- l * (m1.val / l) + m1.val % l = m1.val
    have hm2 := Nat.div_add_mod m2.val l
    have hml : l * (m1.val / l) = l * (m2.val / l) := congr_arg (l * ·) hdiv
    exact Fin.ext (by linarith)
  · -- Different cosets: contradiction via cosets_disjoint.
    exfalso
    have hmem1 : cosetPoint (e ia1).val ⟨m1.val % l, m_mod_lt m1⟩ ∈ Ω (e ia1).val :=
      cosetPoint_mem_Ω _ _
    have hmem2 : cosetPoint (e ia1).val ⟨m1.val % l, m_mod_lt m1⟩ ∈ Ω (e ia2).val := by
      rw [heq]; exact cosetPoint_mem_Ω _ _
    exact absurd hmem2
      (Finset.disjoint_left.mp (cosets_disjoint (e ia1).val (e ia2).val hi) hmem1)

/-! ### S4: Shard recovery -/

/-- **S4**: Any `k/l` cosets suffice to recover the polynomial.

    If `p` has degree `≤ d` and the evaluations of `p` at cosets `I` equal `vs`,
    then `p` equals the Lagrange interpolant through the `k` collected coset points.

    **Proof**: Apply `poly_unique_of_eval` (A5) with the `d+1` distinct coset points
    (`cosetPoints_injective`).  The interpolant has degree `≤ d` by `interpolate_natDegree`
    (A4).  The evaluations agree: for the interpolant this is `interpolate_eval` (A4);
    for `p` this is `heval` combined with the definition of `shardEval`. -/
theorem shard_recovery
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (p : Poly) (hp : p.natDegree ≤ d)
    (vs : Fin s → Fin l → Fr)
    (heval : ∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j) :
    p = Dal.Poly.interpolate (cosetPoints I hI) (shardVals I hI vs) :=
  poly_unique_of_eval (cosetPoints I hI) (cosetPoints_injective I hI) p _
    hp
    (Dal.Poly.interpolate_natDegree _ _ (cosetPoints_injective I hI))
    (fun m => by
      rw [Dal.Poly.interpolate_eval _ _ (cosetPoints_injective I hI) m]
      -- Goal: Polynomial.eval (cosetPoints I hI m) p = shardVals I hI vs m
      -- Both sides unfold via cosetPoints/shardVals/shardEval to the same heval instance.
      change shardEval p ((I.orderIsoOfFin hI ⟨m.val / l, m_div_lt m⟩).val)
                       ⟨m.val % l, m_mod_lt m⟩ =
           vs ((I.orderIsoOfFin hI ⟨m.val / l, m_div_lt m⟩).val)
              ⟨m.val % l, m_mod_lt m⟩
      exact heval _ ((I.orderIsoOfFin hI ⟨m.val / l, m_div_lt m⟩).prop) _)

end Dal.ReedSolomon
