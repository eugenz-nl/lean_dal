# Review of the Lean DAL Formalization

Review of the formalization in `dal/Dal/` against `docs/protocol.md`.

## Overall Assessment

The formalization is faithful and complete with respect to the protocol
document's formal specification section (§"Formalization of the cryptography
for the DAL"). Every numbered specification (Specs 1–6) and property (P1, P2)
has a direct Lean counterpart with the correct logical structure. The
formalization extends the document with shard-level properties (S2–S4, A7, P3)
that the document describes algorithmically but does not state as formal
properties. The project builds with zero errors, zero warnings, and zero
`sorry` occurrences.

## Findings

### 1. Simplified serialization model

The protocol document describes a page-based serialization with byte
interleaving (`res[elt * pages_per_slot + page]`). The Lean formalization uses
a simpler model: contiguous 31-byte chunks without page structure or
permutation.

The interleaving in the real Tezos implementation ensures each page's scalar
elements form a coset of the interpolation domain, enabling constant-time KZG
multi-reveal proofs for L1 page verification. The simplified model does not
capture this structure.

**Impact**: S1 (serialization injectivity) holds for both layouts, so no
downstream theorem is invalidated. However, a future page-level verification
property (analogous to P3 but for pages) would require modeling the
interleaving.

### 2. Missing completeness properties

P1–P3 all have the form "if verification succeeds, then ...". The
formalization never states that an honest prover can produce proofs that will
pass verification. Concretely:

- There is no axiom stating that if `commit p = c` and
  `proveEval p x (eval p x) = some π`, then `verifyEval x (eval p x) c π = true`.
- Similarly, there are no completeness axioms for `verifyDegree` or
  `verifyShardEval`.

**Impact**: The formalization proves the scheme is *secure* (soundness +
binding) but not that it *works* for honest participants (completeness).

### 3. Missing end-to-end round-trip theorem

The full DAL pipeline is: bytes → serialize → scalars → interpolate → poly →
commit → ... → verify shards → interpolate → poly → evaluate → scalars →
deserialize → bytes. The formalization proves individual links (S1, P1, P3) but
does not compose them into a single theorem stating that the recovered bytes
equal the original bytes.

**Impact**: The chain of reasoning is present but implicit. An explicit
end-to-end theorem would require modeling deserialization (the inverse of
`serialize`) and composing all results.

### 4. A7 is stronger than the cryptographic primitive warrants

Axiom A7 (`verifyShardEval_soundness`) includes `p.natDegree ≤ d` in its
conclusion:

```lean
axiom verifyShardEval_soundness (c : G1) (i : Fin s) (vs : Fin l → Fr) (π : G1) :
    verifyShardEval c i vs π = true →
    ∃ p : Poly, commit p = c ∧ proveShardEval p i = π ∧ p.natDegree ≤ d ∧
                ∀ j : Fin l, shardEval p i j = vs j
```

The real multi-reveal verification equation only checks that evaluations are
consistent with the commitment — it does not enforce a degree bound. In the
actual protocol, the degree bound is established separately by an on-chain
degree proof (via `verifyDegree` / A3).

This causes an asymmetry: P1 explicitly requires a degree-proof hypothesis
(`hdeg : verifyDegree c d π_deg = true`), while P3 gets the degree bound for
free from A7.

**Recommended fix**: Remove `p.natDegree ≤ d` from A7's conclusion, and add a
separate `verifyDegree c d π_deg = true` hypothesis to P3, mirroring P1's
structure.
