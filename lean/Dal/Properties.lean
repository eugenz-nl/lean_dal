import Dal.Protocol

/-!
# Dal.Properties

**Correctness certificate** for the Tezos DAL formalization.

Importing this file gives the complete set of proved invariants.  Every theorem
listed here is proved without `sorry`; the proofs are in the respective modules.

## Summary of properties

| ID  | Name                              | Module                | Status  |
|-----|-----------------------------------|-----------------------|---------|
| S1  | Serialization injectivity         | `Dal.Serialization`   | proved  |
| S2  | Coset partition                   | `Dal.Sharding`        | proved  |
| S3  | Vanishing polynomial roots        | `Dal.Sharding`        | proved  |
| S4  | Shard recovery (MDS)              | `Dal.ReedSolomon`     | proved  |
| P1  | RS decoding succeeds              | `Dal.Protocol`        | proved  |
| P2  | Page verification uniqueness      | `Dal.Protocol`        | proved  |
| P3  | Shard verification implies recovery | `Dal.Protocol`      | proved  |
| A1c | Eval completeness (verifier)      | `Dal.KZG`             | axiom   |
| A3c | Degree completeness               | `Dal.KZG`             | axiom   |
| A7c | Shard eval completeness           | `Dal.KZG`             | axiom   |
| G13 | End-to-end round-trip             | `Dal.Protocol`        | proved  |
| Sec1 | Slot binding                      | `Dal.Protocol`        | proved  |
| Sec2 | Decoder determinism               | `Dal.Protocol`        | proved  |
| Sec3 | Shard unforgeability (slot level) | `Dal.Protocol`        | proved  |
| Sec4 | Threshold robustness / DA liveness | `Dal.Protocol`       | proved  |
| Sec5 | Page-eval soundness (slot level)  | `Dal.Protocol`        | proved  |
| Sec6 | No fake commitments               | `Dal.Protocol`        | proved  |
| Sec7 | Proof non-malleability (eval / degree / shard) | `Dal.Protocol` | proved |

-/

namespace Dal.Properties

open Dal.Field Dal.Poly Dal.KZG Dal.Serialization Dal.Sharding Dal.ReedSolomon Dal.Protocol

/-! ### S1: Serialization injectivity -/

/-- **S1**: The byte-to-scalar serialization is injective: equal scalar arrays imply
    equal byte sequences. -/
theorem s1_serialize_injective : Function.Injective serialize :=
  Dal.Serialization.serialize_injective

/-! ### S2: Coset partition -/

/-- **S2 (union)**: The `n` roots of unity equal the union of all `s` cosets `Ω_i`. -/
theorem s2_coset_partition :
    Finset.image (fun m : Fin n => ω ^ m.val) Finset.univ =
    (Finset.univ : Finset (Fin s)).biUnion Ω :=
  Dal.Sharding.coset_partition

/-- **S2 (disjointness)**: Distinct cosets are disjoint. -/
theorem s2_cosets_disjoint (i j : Fin s) (h : i ≠ j) : Disjoint (Ω i) (Ω j) :=
  Dal.Sharding.cosets_disjoint i j h

/-! ### S3: Vanishing polynomial roots -/

/-- **S3**: The vanishing polynomial `Z_i = X^l − ω^(i·l)` vanishes exactly on `Ω_i`. -/
theorem s3_vanishing_poly_roots (i : Fin s) (x : Fr) :
    Polynomial.eval x (Z i) = 0 ↔ x ∈ Ω i :=
  Dal.Sharding.vanishing_poly_roots i x

/-! ### S4: Shard recovery -/

/-- **S4**: Any `k/l` cosets suffice to recover the polynomial via interpolation.

    If `p.natDegree ≤ d` and the evaluations of `p` at cosets `I` equal `vs`, then
    `p` equals the Lagrange interpolant through the `k = d+1` collected coset points. -/
theorem s4_shard_recovery
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (p : Poly) (hp : p.natDegree ≤ d)
    (vs : Fin s → Fin l → Fr)
    (heval : ∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j) :
    p = Dal.Poly.interpolate (cosetPoints I hI) (shardVals I hI vs) :=
  Dal.ReedSolomon.shard_recovery I hI p hp vs heval

/-! ### P2: Page verification uniqueness -/

/-- **P2**: If `d+1` evaluation proofs all verify against commitment `c`, there is a
    unique polynomial committed to by `c` whose proofs match. -/
theorem p2_page_verification_unique
    (c : G1) (xs : Fin (d + 1) → Fr) (ys : Fin (d + 1) → Fr)
    (πs : Fin (d + 1) → G1)
    (hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true) :
    ∃! p : Poly, commit p = c ∧
                 ∀ i, proveEval p (xs i) (ys i) = some (πs i) :=
  Dal.Protocol.page_verification_unique c xs ys πs hverify

/-! ### P1: RS decoding succeeds -/

/-- **P1**: If `d+1` distinct evaluation proofs and a degree-`d` proof all verify
    against `c`, there is a unique polynomial `p` committed to by `c` that:
    - has the claimed evaluation proofs, and
    - equals the Lagrange interpolant `interpolate xs ys`. -/
theorem p1_rs_decoding_succeeds
    (c : G1) (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (ys : Fin (d + 1) → Fr)
    (πs : Fin (d + 1) → G1) (π_deg : G1)
    (hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
    (hdeg : verifyDegree c d π_deg = true) :
    ∃! p : Poly, commit p = c ∧
                 (∀ i, proveEval p (xs i) (ys i) = some (πs i)) ∧
                 Dal.Poly.interpolate xs ys = p :=
  Dal.Protocol.rs_decoding_succeeds c xs hxs ys πs π_deg hverify hdeg

/-! ### P3: Shard verification implies recovery -/

/-- **P3**: If `k/l` shard proofs all verify against commitment `c`, there is a
    unique polynomial committed to by `c` whose shard evaluations match the
    claimed values and which equals the Lagrange interpolant of the collected
    coset evaluation pairs. -/
theorem p3_shard_verification_recovery
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (c : G1) (π_deg : G1)
    (vs : Fin s → Fin l → Fr)
    (πs : Fin s → G1)
    (hdeg : verifyDegree c d π_deg = true)
    (hverify : ∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true) :
    ∃! p : Poly, commit p = c ∧
                 (∀ i ∈ I, proveShardEval p i = πs i) ∧
                 (∀ i ∈ I, ∀ j : Fin l, shardEval p i j = vs i j) ∧
                 Dal.Poly.interpolate (cosetPoints I hI) (shardVals I hI vs) = p :=
  Dal.Protocol.shard_verification_recovery I hI c π_deg vs πs hdeg hverify

/-! ### G13: End-to-end round-trip -/

/-- **G13**: If `c` commits to the interpolant of `serialize b` at `xs`, and `k/l`
    shard proofs verify against `c`, then deserializing the recovered polynomial's
    evaluations at `xs` gives back `b`. -/
theorem g13_round_trip
    (b : Dal.Serialization.Bytes)
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (c : G1) (π_deg : G1)
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (vs : Fin s → Fin l → Fr) (πs : Fin s → G1)
    (hc : commit (Dal.Poly.interpolate xs
        (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k)) = c)
    (hdeg : verifyDegree c d π_deg = true)
    (hverify : ∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true) :
    Dal.Serialization.deserialize (fun i : Fin k =>
        Polynomial.eval (xs (Fin.cast d_succ_eq_k.symm i))
          (Dal.Poly.interpolate (cosetPoints I hI) (shardVals I hI vs))) = b :=
  Dal.Protocol.round_trip b xs hxs c π_deg I hI vs πs hc hdeg hverify

/-! ### Completeness axioms (A1c, A3c, A7c) -/

/-- **A1c**: An honest prover's evaluation proof always passes verification. -/
theorem a1c_verifyEval_complete (p : Poly) (x : Fr) (π : G1) :
    proveEval p x (Polynomial.eval x p) = some π →
    verifyEval x (Polynomial.eval x p) (commit p) π = true :=
  Dal.KZG.verifyEval_complete p x π

/-- **A3c**: If `p.natDegree ≤ bound`, the prover can produce a degree proof that
    verifies. -/
theorem a3c_proveDegree_complete (p : Poly) (bound : ℕ) :
    p.natDegree ≤ bound →
    ∃ π : G1, proveDegree p bound = some π ∧ verifyDegree (commit p) bound π = true :=
  Dal.KZG.proveDegree_complete p bound

/-- **A7c**: An honest prover's shard proof always passes verification. -/
theorem a7c_verifyShardEval_complete (p : Poly) (i : Fin s) :
    verifyShardEval (commit p) i (fun j => shardEval p i j) (proveShardEval p i) = true :=
  Dal.KZG.verifyShardEval_complete p i

/-! ### DAL-level security theorems (Sec1–Sec7) -/

/-- **Sec1**: Slot binding — equal slot-level commitments imply equal slots. -/
theorem sec1_slot_binding
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (b₁ b₂ : Dal.Serialization.Bytes)
    (hcommit : commit (Dal.Poly.interpolate xs
                 (Dal.Serialization.serialize b₁ ∘ Fin.cast d_succ_eq_k))
             = commit (Dal.Poly.interpolate xs
                 (Dal.Serialization.serialize b₂ ∘ Fin.cast d_succ_eq_k))) :
    b₁ = b₂ :=
  Dal.Protocol.slot_binding xs hxs b₁ b₂ hcommit

/-- **Sec2**: Decoder determinism — distinct verifying shard subsets under the
    same commitment recover equal interpolants. -/
theorem sec2_decoder_determinism
    (c π_deg : G1)
    (I : Finset (Fin s)) (hI : I.card = k / l)
    (I' : Finset (Fin s)) (hI' : I'.card = k / l)
    (vs : Fin s → Fin l → Fr) (πs : Fin s → G1)
    (vs' : Fin s → Fin l → Fr) (πs' : Fin s → G1)
    (hdeg : verifyDegree c d π_deg = true)
    (hverify : ∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = true)
    (hverify' : ∀ i ∈ I', verifyShardEval c i (vs' i) (πs' i) = true) :
    Dal.Poly.interpolate (cosetPoints I hI) (shardVals I hI vs) =
    Dal.Poly.interpolate (cosetPoints I' hI') (shardVals I' hI' vs') :=
  Dal.Protocol.decoder_determinism c π_deg I hI I' hI' vs πs vs' πs' hdeg hverify hverify'

/-- **Sec3**: Shard unforgeability at slot level — verifying shard values/proofs
    against a known-slot commitment match the slot's true coset evaluations
    and proof. -/
theorem sec3_shard_values_unforgeable
    (b : Dal.Serialization.Bytes) (xs : Fin (d + 1) → Fr)
    (i : Fin s) (vs : Fin l → Fr) (π : G1)
    (hverify : verifyShardEval
                 (commit (Dal.Poly.interpolate xs
                    (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k)))
                 i vs π = true) :
    (∀ j, vs j =
      shardEval (Dal.Poly.interpolate xs
                   (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k)) i j) ∧
    π = proveShardEval
          (Dal.Poly.interpolate xs
             (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k)) i :=
  Dal.Protocol.shard_values_unforgeable b xs i vs π hverify

/-- **Sec4**: Threshold robustness (DA liveness) — honest shard values on any
    `k/l`-subset `I` suffice to reconstruct the original slot. -/
theorem sec4_threshold_robustness
    (b : Dal.Serialization.Bytes)
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (I : Finset (Fin s)) (hI : I.card = k / l) :
    Dal.Serialization.deserialize (fun i : Fin k =>
        Polynomial.eval (xs (Fin.cast d_succ_eq_k.symm i))
          (Dal.Poly.interpolate (cosetPoints I hI)
            (shardVals I hI
              (fun i' j =>
                shardEval (Dal.Poly.interpolate xs
                   (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k)) i' j)))) = b :=
  Dal.Protocol.threshold_robustness b xs hxs I hI

/-- **Sec5**: Page-eval soundness at slot level — verifying evaluation proofs
    at `xs` against a slot's commitment force the alleged values to equal the
    slot's scalar sequence. -/
theorem sec5_page_values_sound
    (b : Dal.Serialization.Bytes)
    (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (ys : Fin (d + 1) → Fr) (πs : Fin (d + 1) → G1)
    (hverify : ∀ i,
        verifyEval (xs i) (ys i)
          (commit (Dal.Poly.interpolate xs
             (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k)))
          (πs i) = true) :
    ∀ i, ys i = (Dal.Serialization.serialize b ∘ Fin.cast d_succ_eq_k) i :=
  Dal.Protocol.page_values_sound b xs hxs ys πs hverify

/-- **Sec6**: No fake commitments — a commitment that passes the degree check
    is in the image of `commit` with a bounded-degree preimage. -/
theorem sec6_commitment_well_formed
    (c π : G1) (hverify : verifyDegree c d π = true) :
    ∃ p : Poly, commit p = c ∧ p.natDegree ≤ d :=
  Dal.Protocol.commitment_well_formed c π hverify

/-- **Sec7 (evaluation)**: the verifying evaluation proof for `(x, y, c)` is
    unique. -/
theorem sec7_eval_proof_unique
    (x y : Fr) (c π π' : G1)
    (hverify : verifyEval x y c π = true)
    (hverify' : verifyEval x y c π' = true) :
    π = π' :=
  Dal.Protocol.eval_proof_unique x y c π π' hverify hverify'

/-- **Sec7 (degree)**: the verifying degree-bound proof for `(c, bound)` is
    unique. -/
theorem sec7_degree_proof_unique
    (c : G1) (bound : ℕ) (π π' : G1)
    (hverify : verifyDegree c bound π = true)
    (hverify' : verifyDegree c bound π' = true) :
    π = π' :=
  Dal.Protocol.degree_proof_unique c bound π π' hverify hverify'

/-- **Sec7 (shard)**: the verifying multi-reveal proof for `(c, i, vs)` is
    unique. -/
theorem sec7_shard_proof_unique
    (c : G1) (i : Fin s) (vs : Fin l → Fr) (π π' : G1)
    (hverify : verifyShardEval c i vs π = true)
    (hverify' : verifyShardEval c i vs π' = true) :
    π = π' :=
  Dal.Protocol.shard_proof_unique c i vs π π' hverify hverify'

end Dal.Properties
