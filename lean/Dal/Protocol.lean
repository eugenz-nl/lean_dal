import Dal.Field
import Dal.Poly
import Dal.KZG
import Dal.Sharding
import Dal.Serialization
import Dal.ReedSolomon

/-!
# Dal.Protocol

Top-level correctness theorems P1, P2, and P3 assembled from the KZG axioms A1–A7.

## Contents

- `page_verification_unique`       — **P2**: if `d+1` evaluation proofs verify against
  commitment `c`, there is a unique polynomial explaining them.
- `rs_decoding_succeeds`           — **P1**: additionally using a degree proof, the unique
  polynomial equals the Lagrange interpolant of the evaluation pairs.
- `shard_verification_recovery`    — **P3**: if `k/l` shard proofs verify against `c`,
  there is a unique polynomial committed to by `c` whose shard evaluations match and
  which equals the Lagrange interpolant of the collected coset points.

## Proof strategy

**P2** (simpler): apply A1 to each `i` to extract a candidate polynomial, then A6
(commitment binding) to collapse all candidates to one unique polynomial.

**P1** additionally uses:
- A2 (eval completeness) to recover `eval p (xs i) = ys i` from the proof witnesses
- A3 (degree soundness) to get `p.natDegree ≤ d`
- A4 (interpolation correctness) + A5 (polynomial uniqueness) to conclude
  `interpolate xs ys = p`

**P3**: apply A7 to each `i ∈ I` to extract candidates. A3 (degree soundness) via
the explicit `verifyDegree` hypothesis gives `p.natDegree ≤ d`. A6 collapses to
unique `p`. S4 (`shard_recovery`) gives `interpolate (cosetPoints I) (shardVals I vs) = p`.

The full invariant statements are given by the theorem signatures below.
-/

namespace Dal.Protocol

open Dal.Field Dal.Poly Dal.KZG Dal.Sharding Dal.ReedSolomon Dal.Serialization Polynomial

/-! ### P2: Page verification uniqueness -/

/-- **P2**: If `d+1` evaluation proofs all verify against commitment `c`, there is a
    unique polynomial `p` committed to by `c` whose proofs match.

    **Proof**: A1 (eval soundness) yields a candidate polynomial for each index `i`.
    A6 (commitment binding) shows all candidates are equal, giving the unique `p`. -/
theorem page_verification_unique
    (c : G1) (xs : Fin (d + 1) → Fr) (ys : Fin (d + 1) → Fr)
    (πs : Fin (d + 1) → G1)
    (hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true) :
    ∃! p : Poly, commit p = c ∧
                 ∀ i, proveEval p (xs i) (ys i) = some (πs i) := by
  -- A1 applied to each i: extract a candidate polynomial
  have hA1 : ∀ i : Fin (d + 1),
      ∃ q : Poly, commit q = c ∧ proveEval q (xs i) (ys i) = some (πs i) :=
    fun i => verifyEval_soundness (xs i) (ys i) c (πs i) (hverify i)
  -- Pick a witness from i = 0
  obtain ⟨p, hpc, _⟩ := hA1 ⟨0, Nat.lt_succ_of_le (Nat.zero_le d)⟩
  -- All candidates equal p by A6; hence p satisfies proveEval at every i
  have hall : ∀ i : Fin (d + 1), proveEval p (xs i) (ys i) = some (πs i) := fun i => by
    obtain ⟨qi, hqc, hqprove⟩ := hA1 i
    rw [commit_binding p qi (hpc.trans hqc.symm)]
    exact hqprove
  -- Existence: p witnesses the property; uniqueness: A6
  exact ⟨p, ⟨hpc, hall⟩,
         fun q ⟨hqc, _⟩ => commit_binding q p (hqc.trans hpc.symm)⟩

/-! ### P1: RS decoding succeeds -/

/-- **P1**: If `d+1` distinct evaluation proofs verify against `c` and a degree-`d`
    proof verifies, there is a unique polynomial `p` that:
    - is committed to by `c`,
    - has the claimed evaluation proofs, and
    - equals the Lagrange interpolant of the `(xs, ys)` pairs.

    **Proof**: P2 gives the unique `p` with `commit p = c`.  A2 recovers the evaluations
    `eval p (xs i) = ys i`. A3 gives `p.natDegree ≤ d`.  A4 + A5 conclude
    `interpolate xs ys = p`. -/
theorem rs_decoding_succeeds
    (c : G1) (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (ys : Fin (d + 1) → Fr)
    (πs : Fin (d + 1) → G1) (π_deg : G1)
    (hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
    (hdeg : verifyDegree c d π_deg = true) :
    ∃! p : Poly, commit p = c ∧
                 (∀ i, proveEval p (xs i) (ys i) = some (πs i)) ∧
                 interpolate xs ys = p := by
  -- Obtain p from P2 (reuse the same A1+A6 argument)
  have hA1 : ∀ i : Fin (d + 1),
      ∃ q : Poly, commit q = c ∧ proveEval q (xs i) (ys i) = some (πs i) :=
    fun i => verifyEval_soundness (xs i) (ys i) c (πs i) (hverify i)
  obtain ⟨p, hpc, _⟩ := hA1 ⟨0, Nat.lt_succ_of_le (Nat.zero_le d)⟩
  have hall : ∀ i : Fin (d + 1), proveEval p (xs i) (ys i) = some (πs i) := fun i => by
    obtain ⟨qi, hqc, hqprove⟩ := hA1 i
    rw [commit_binding p qi (hpc.trans hqc.symm)]; exact hqprove
  -- A2: recover evaluations from proof witnesses
  have heval : ∀ i : Fin (d + 1), Polynomial.eval (xs i) p = ys i := fun i =>
    (proveEval_complete p (xs i) (ys i)).mp ⟨πs i, hall i⟩
  -- A3: recover degree bound from the degree proof
  obtain ⟨p', hp'c, hp'deg, _⟩ := verifyDegree_soundness c π_deg d hdeg
  have hp_deg : p.natDegree ≤ d :=
    commit_binding p p' (hpc.trans hp'c.symm) ▸ hp'deg
  -- A4 + A5: the interpolant agrees with p on all xs, same degree bound → equal
  have hint : interpolate xs ys = p :=
    poly_unique_of_eval xs hxs (interpolate xs ys) p
      (interpolate_natDegree xs ys hxs) hp_deg
      (fun i => (interpolate_eval xs ys hxs i).trans (heval i).symm)
  -- Existence and uniqueness by A6
  exact ⟨p, ⟨hpc, hall, hint⟩,
         fun q ⟨hqc, _, _⟩ => commit_binding q p (hqc.trans hpc.symm)⟩

/-! ### P3: Shard verification implies recovery -/

/-- **P3**: If `k/l` shard proofs all verify against commitment `c`, there is a
    unique polynomial `p` committed to by `c` such that:
    - `proveShardEval p i = πs i` for each `i ∈ I`, and
    - `shardEval p i j = vs i j` for each `i ∈ I`, `j : Fin l`, and
    - `p` equals the Lagrange interpolant of all coset evaluation pairs.

    **Proof**: A7 (shard eval soundness) yields a candidate polynomial for each
    `i ∈ I` (with degree bound `≤ d` included). A6 (commitment binding) collapses
    all candidates to a unique `p`. S4 (`shard_recovery`) gives the interpolant
    identity. -/
theorem shard_verification_recovery
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (c : G1) (π_deg : G1)
    (vs : Fin s → Fin l → Fr)
    (πs : Fin s → G1)
    (hdeg : verifyDegree c d π_deg = true)
    (hverify : ∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true) :
    ∃! p : Poly, commit p = c ∧
                 (∀ i ∈ I, proveShardEval p i = πs i) ∧
                 (∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j) ∧
                 interpolate (cosetPoints I hI) (shardVals I hI vs) = p := by
  -- I is nonempty since |I| = k/l > 0
  have hkl_pos : 0 < k / l := Nat.div_pos (Nat.le_of_dvd k_pos l_dvd_k) l_pos
  have hI_nonempty : I.Nonempty := Finset.card_pos.mp (hI ▸ hkl_pos)
  obtain ⟨i0, hi0⟩ := hI_nonempty
  -- A7 applied to each i ∈ I: candidate polynomial and shard evaluations
  have hA7 : ∀ i ∈ I, ∃ q : Poly, commit q = c ∧ proveShardEval q i = πs i ∧
      ∀ j : Fin l, shardEval q i j = vs i j :=
    fun i hi => verifyShardEval_soundness c i (vs i) (πs i) (hverify i hi)
  -- Pick a witness from i0
  obtain ⟨p, hpc, _, _⟩ := hA7 i0 hi0
  -- A3: recover degree bound from the degree proof (mirrors P1)
  obtain ⟨p', hp'c, hp'deg, _⟩ := verifyDegree_soundness c π_deg d hdeg
  have hp_deg : p.natDegree ≤ d := commit_binding p p' (hpc.trans hp'c.symm) ▸ hp'deg
  -- All candidates equal p by A6; hence p satisfies proveShardEval and shardEval at every i
  have hall_prove : ∀ i ∈ I, proveShardEval p i = πs i := fun i hi => by
    obtain ⟨qi, hqc, hqprove, _⟩ := hA7 i hi
    rw [commit_binding p qi (hpc.trans hqc.symm)]
    exact hqprove
  have hall_eval : ∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j := fun i hi j => by
    obtain ⟨qi, hqc, _, hqeval⟩ := hA7 i hi
    rw [commit_binding p qi (hpc.trans hqc.symm)]
    exact hqeval j
  -- S4: the Lagrange interpolant through the collected coset points equals p
  have hint : interpolate (cosetPoints I hI) (shardVals I hI vs) = p :=
    (Dal.ReedSolomon.shard_recovery I hI p hp_deg vs hall_eval).symm
  -- Existence and uniqueness by A6
  exact ⟨p, ⟨hpc, hall_prove, hall_eval, hint⟩,
         fun q ⟨hqc, _, _, _⟩ => commit_binding q p (hqc.trans hpc.symm)⟩

/-! ### G13: End-to-end round-trip -/

/-- **G13 — Round-trip**: bytes → serialize → interpolate → commit →
    verify shards → interpolate → deserialize → bytes.

    If commitment `c` was made to the polynomial interpolating `serialize b` at
    distinct nodes `xs`, and `k/l` shard proofs all verify against `c`, then
    deserializing the recovered polynomial's evaluations at `xs` gives back `b`.

    **Proof**: P3 yields the unique `p` with `commit p = c`.  A6 identifies `p`
    with the interpolant of `serialize b` at `xs`.  A4 recovers the evaluations
    `eval p (xs i) = (serialize b) (Fin.cast d_succ_eq_k i)` at each node.
    Composing with `Fin.cast d_succ_eq_k.symm` and unfolding the cast gives
    `serialize b`, and `deserialize_left_inverse` closes the goal. -/
theorem round_trip
    (b : Bytes)
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (c : G1) (π_deg : G1)
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (vs : Fin s → Fin l → Fr) (πs : Fin s → G1)
    (hc : commit (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)) = c)
    (hdeg : verifyDegree c d π_deg = true)
    (hverify : ∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true) :
    deserialize (fun i : Fin k =>
        Polynomial.eval (xs (Fin.cast d_succ_eq_k.symm i))
          (interpolate (cosetPoints I hI) (shardVals I hI vs))) = b := by
  -- The polynomial committed to
  set q := interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k) with hq_def
  -- P3: extract the unique recovered polynomial
  obtain ⟨p, ⟨hpc, _, _, hint⟩, _⟩ :=
    shard_verification_recovery I hI c π_deg vs πs hdeg hverify
  -- A6: q = p (both committed to c)
  have hqp : q = p := commit_binding q p (hc.trans hpc.symm)
  -- The recovered interpolant equals q
  have hrec : interpolate (cosetPoints I hI) (shardVals I hI vs) =
      interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k) :=
    hint.trans (hqp.symm.trans hq_def)
  -- Rewrite the interpolant in the goal
  simp_rw [hrec]
  -- Evaluate using A4: interpolate xs ys at xs i = ys i
  have hfun : (fun i : Fin k =>
      Polynomial.eval (xs (Fin.cast d_succ_eq_k.symm i))
        (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k))) = serialize b := by
    funext i
    rw [interpolate_eval xs _ hxs (Fin.cast d_succ_eq_k.symm i)]
    simp only [Function.comp]
    congr 1
  rw [hfun]
  exact deserialize_left_inverse b

end Dal.Protocol
