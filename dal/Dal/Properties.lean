import Dal.Protocol

/-!
# Dal.Properties

**Correctness certificate** for the Tezos DAL formalization.

Importing this file gives the complete set of proved invariants.  Every theorem
listed here is proved without `sorry`; the proofs are in the respective modules.

## Summary of properties

| ID | Name                          | Module                | Status  |
|----|-------------------------------|-----------------------|---------|
| S1 | Serialization injectivity     | `Dal.Serialization`   | proved  |
| S2 | Coset partition               | `Dal.Sharding`        | proved  |
| S3 | Vanishing polynomial roots    | `Dal.Sharding`        | proved  |
| S4 | Shard recovery (MDS)          | `Dal.ReedSolomon`     | proved  |
| P1 | RS decoding succeeds          | `Dal.Protocol`        | proved  |
| P2 | Page verification uniqueness  | `Dal.Protocol`        | proved  |

See `kb/properties.md` for the full invariant statements and proof sketches.
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

end Dal.Properties
