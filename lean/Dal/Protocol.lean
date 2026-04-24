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

/-! ### Security theorems (DAL-level corollaries)

These lift the KZG axioms and main theorems to attacker-relevant guarantees at
the `Bytes` / slot level.  None of them introduces a new cryptographic assumption;
each follows from the existing axioms A1–A7 (plus A1c, A3c, A7c) and the main
theorems P1, P2, P3, G13.
-/

/-- **Sec1 — Slot binding**: two slots whose interpolants commit to the same L1
    value (at the same distinct evaluation nodes) are equal.

    **Proof**: A6 gives equal interpolants.  A4 pushes the equality to the
    serialized scalar sequences (pointwise).  Cast cancellation lifts it to
    `serialize b₁ = serialize b₂`, and S1 closes. -/
theorem slot_binding
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (b₁ b₂ : Bytes)
    (hcommit : commit (interpolate xs (serialize b₁ ∘ Fin.cast d_succ_eq_k))
             = commit (interpolate xs (serialize b₂ ∘ Fin.cast d_succ_eq_k))) :
    b₁ = b₂ := by
  -- A6: equal interpolants
  have hint_eq : interpolate xs (serialize b₁ ∘ Fin.cast d_succ_eq_k) =
                 interpolate xs (serialize b₂ ∘ Fin.cast d_succ_eq_k) :=
    commit_binding _ _ hcommit
  -- A4: evaluations at every xs i agree
  have heval : ∀ i : Fin (d + 1),
      (serialize b₁ ∘ Fin.cast d_succ_eq_k) i =
      (serialize b₂ ∘ Fin.cast d_succ_eq_k) i := by
    intro i
    have h1 := interpolate_eval xs (serialize b₁ ∘ Fin.cast d_succ_eq_k) hxs i
    have h2 := interpolate_eval xs (serialize b₂ ∘ Fin.cast d_succ_eq_k) hxs i
    rw [hint_eq] at h1
    exact h1.symm.trans h2
  -- Cast cancellation: lift to equality of `serialize b_i` on all of `Fin k`
  have hser : serialize b₁ = serialize b₂ := by
    funext j
    have hcast : Fin.cast d_succ_eq_k (Fin.cast d_succ_eq_k.symm j) = j := by
      apply Fin.ext; rfl
    have hj := heval (Fin.cast d_succ_eq_k.symm j)
    simp only [Function.comp_apply, hcast] at hj
    exact hj
  -- S1
  exact serialize_injective hser

/-- **Sec2 — Decoder determinism**: two distinct verifying shard subsets under
    the same commitment produce equal interpolants — an adversary cannot split
    the reconstruction outcome across honest verifiers.

    **Proof**: P3 applied to `I` gives a unique `p` with `commit p = c` and the
    interpolant identity.  P3 applied to `I'` gives `p'`.  A6 collapses
    `p = p'`; chain the two interpolant identities. -/
theorem decoder_determinism
    (c π_deg : G1)
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (I' : Finset (Fin s)) (hI' : I'.card = k / l)
    (vs : Fin s → Fin l → Fr) (πs : Fin s → G1)
    (vs' : Fin s → Fin l → Fr) (πs' : Fin s → G1)
    (hdeg : verifyDegree c d π_deg = true)
    (hverify : ∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true)
    (hverify' : ∀ i ∈ I', verifyShardEval c i (vs' i) (πs' i) = true) :
    interpolate (cosetPoints I hI) (shardVals I hI vs) =
    interpolate (cosetPoints I' hI') (shardVals I' hI' vs') := by
  obtain ⟨p, ⟨hpc, _, _, hint⟩, _⟩ :=
    shard_verification_recovery I hI c π_deg vs πs hdeg hverify
  obtain ⟨p', ⟨hp'c, _, _, hint'⟩, _⟩ :=
    shard_verification_recovery I' hI' c π_deg vs' πs' hdeg hverify'
  have hpp' : p = p' := commit_binding p p' (hpc.trans hp'c.symm)
  exact hint.trans (hpp'.trans hint'.symm)

/-- **Sec3 — Shard unforgeability (slot level)**: a verifying shard proof/values
    pair against a known slot's commitment matches the slot's true coset
    evaluations and proof.

    **Proof**: A7 extracts a witness `p` with `commit p = c`; A6 identifies
    `p` with the slot's interpolant; substitute. -/
theorem shard_values_unforgeable
    (b : Bytes) (xs : Fin (d + 1) → Fr)
    (i : Fin s) (vs : Fin l → Fr) (π : G1)
    (hverify : verifyShardEval
                 (commit (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)))
                 i vs π = true) :
    (∀ j, vs j =
      shardEval (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)) i j) ∧
    π = proveShardEval (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)) i := by
  obtain ⟨p, hpc, hpprove, hpeval⟩ :=
    verifyShardEval_soundness _ i vs π hverify
  have hp_eq : p = interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k) :=
    commit_binding _ _ hpc
  rw [hp_eq] at hpeval hpprove
  exact ⟨fun j => (hpeval j).symm, hpprove.symm⟩

/-- **Sec4 — Threshold robustness / DA liveness**: given honest shard values
    (and proofs) at any `k/l`-subset `I` of cosets, reconstruction recovers the
    original slot `b`.

    The "honest" assumption is expressed by feeding `round_trip` with
    `vs i j := shardEval p_b i j` and `πs i := proveShardEval p_b i`, where
    `p_b` is the slot interpolant.  Adversarial framing: if ≥ `k/l` shards are
    held honestly (out of `s`), pick any `k/l`-subset `I` among them to invoke
    this theorem; the adversary's withheld/corrupted shards (< `s − k/l`) cannot
    prevent reconstruction.

    **Proof**: A4 gives `p_b.natDegree ≤ d`, and A3c yields a verifying degree
    proof.  A7c makes every honest shard proof verify.  G13 closes. -/
theorem threshold_robustness
    (b : Bytes)
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (I : Finset (Fin s)) (hI : I.card = k / l) :
    deserialize (fun i : Fin k =>
        Polynomial.eval (xs (Fin.cast d_succ_eq_k.symm i))
          (interpolate (cosetPoints I hI)
            (shardVals I hI
              (fun i' j =>
                shardEval (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)) i' j)))) = b := by
  set p_b := interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)
  -- A4 (degree) + A3c: honest degree proof exists and verifies
  have hp_deg : p_b.natDegree ≤ d := interpolate_natDegree xs _ hxs
  obtain ⟨π_deg, _, hdeg_verify⟩ := proveDegree_complete p_b d hp_deg
  -- A7c: honest shard proofs verify
  have hverify : ∀ i ∈ I,
      verifyShardEval (commit p_b) i
        (fun j => shardEval p_b i j) (proveShardEval p_b i) = true :=
    fun i _ => verifyShardEval_complete p_b i
  -- G13 closes the goal
  exact round_trip b xs hxs (commit p_b) π_deg I hI
    (fun i j => shardEval p_b i j)
    (fun i => proveShardEval p_b i)
    rfl hdeg_verify hverify

/-- **Sec5 — Page-eval soundness (slot level)**: verifying evaluation proofs at
    nodes `xs` against a slot's commitment force the alleged values to equal
    the slot's scalar sequence.  A verifier cannot be convinced of incorrect
    scalar values at the committed evaluation points.

    **Proof**: P2 yields the unique `p` with `commit p = commit(slot interp)`.
    A6 identifies `p` with the slot interpolant.  A2 gives `eval p (xs i) = ys i`;
    A4 gives `eval (slot interp) (xs i) = (serialize b ∘ cast) i`.  Chain. -/
theorem page_values_sound
    (b : Bytes)
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (ys : Fin (d + 1) → Fr) (πs : Fin (d + 1) → G1)
    (hverify : ∀ i,
        verifyEval (xs i) (ys i)
          (commit (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k)))
          (πs i) = true) :
    ∀ i, ys i = (serialize b ∘ Fin.cast d_succ_eq_k) i := by
  obtain ⟨p, ⟨hpc, hpprove⟩, _⟩ :=
    page_verification_unique
      (commit (interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k))) xs ys πs hverify
  have hp_eq : p = interpolate xs (serialize b ∘ Fin.cast d_succ_eq_k) :=
    commit_binding _ _ hpc
  intro i
  have hys : Polynomial.eval (xs i) p = ys i :=
    (proveEval_complete p (xs i) (ys i)).mp ⟨πs i, hpprove i⟩
  rw [hp_eq] at hys
  have hser := interpolate_eval xs (serialize b ∘ Fin.cast d_succ_eq_k) hxs i
  exact hys.symm.trans hser

/-- **Sec6 — No fake commitments**: any commitment that passes the degree check
    lies in the image of `commit` (with a bounded-degree preimage).
    Rules out arbitrary group elements posing as commitments on L1.

    **Proof**: Weakening of A3 (drop the `proveDegree` conjunct). -/
theorem commitment_well_formed
    (c π : G1) (hverify : verifyDegree c d π = true) :
    ∃ p : Poly, commit p = c ∧ p.natDegree ≤ d := by
  obtain ⟨p, hpc, hpdeg, _⟩ := verifyDegree_soundness c π d hverify
  exact ⟨p, hpc, hpdeg⟩

/-! #### Sec7: Proof non-malleability

Three variants: the verifying proof for each KZG statement (evaluation, degree,
shard-eval) is unique given `(commitment, query)`.  Relevant to protocols that
identify proofs by their bit-level content (e.g. hash-as-transcript-input).
-/

/-- **Sec7 (evaluation)**: the verifying evaluation proof for `(x, y, c)` is
    unique.

    **Proof**: A1 twice gives `p, p'` with `commit p = c = commit p'` and
    `proveEval p x y = some π`, `proveEval p' x y = some π'`.  A6 → `p = p'`,
    so `some π = some π'`, hence `π = π'` by constructor injectivity. -/
theorem eval_proof_unique
    (x y : Fr) (c π π' : G1)
    (hverify : verifyEval x y c π = true)
    (hverify' : verifyEval x y c π' = true) :
    π = π' := by
  obtain ⟨p, hpc, hpprove⟩ := verifyEval_soundness x y c π hverify
  obtain ⟨p', hp'c, hp'prove⟩ := verifyEval_soundness x y c π' hverify'
  have hp_eq : p = p' := commit_binding p p' (hpc.trans hp'c.symm)
  rw [hp_eq] at hpprove
  exact Option.some.inj (hpprove.symm.trans hp'prove)

/-- **Sec7 (degree)**: the verifying degree-bound proof for `(c, bound)` is
    unique.  Stated parametrically in `bound`; specializing to `bound = d`
    recovers the DAL statement.

    **Proof**: A3 twice + A6 + constructor injectivity on `Option`. -/
theorem degree_proof_unique
    (c : G1) (bound : ℕ) (π π' : G1)
    (hverify : verifyDegree c bound π = true)
    (hverify' : verifyDegree c bound π' = true) :
    π = π' := by
  obtain ⟨p, hpc, _, hpprove⟩ := verifyDegree_soundness c π bound hverify
  obtain ⟨p', hp'c, _, hp'prove⟩ := verifyDegree_soundness c π' bound hverify'
  have hp_eq : p = p' := commit_binding p p' (hpc.trans hp'c.symm)
  rw [hp_eq] at hpprove
  exact Option.some.inj (hpprove.symm.trans hp'prove)

/-- **Sec7 (shard)**: the verifying multi-reveal proof for `(c, i, vs)` is
    unique.

    **Proof**: A7 twice + A6.  `proveShardEval` returns `G1` directly (not
    `Option`), so no constructor injectivity is needed. -/
theorem shard_proof_unique
    (c : G1) (i : Fin s) (vs : Fin l → Fr) (π π' : G1)
    (hverify : verifyShardEval c i vs π = true)
    (hverify' : verifyShardEval c i vs π' = true) :
    π = π' := by
  obtain ⟨p, hpc, hpprove, _⟩ := verifyShardEval_soundness c i vs π hverify
  obtain ⟨p', hp'c, hp'prove, _⟩ := verifyShardEval_soundness c i vs π' hverify'
  have hp_eq : p = p' := commit_binding p p' (hpc.trans hp'c.symm)
  rw [hp_eq] at hpprove
  exact hpprove.symm.trans hp'prove

end Dal.Protocol
