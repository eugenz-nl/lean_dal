# Foundation for Implementation Verification

The current formalization verifies the *protocol design* but not the
*implementation*. The gap between them could be bridged in stages, each
shrinking the trust boundary without changing the top-level properties.

## Stage 1: OCaml serialization

The Lean `byteChunk` now mirrors the OCaml `polynomial_from_bytes'`
interleaving. Scalar `i` belongs to page `i % pages_per_slot` at element
position `i / pages_per_slot`, with byte address
`page * page_size + elt * 31 + j`.

One could:
- Write a test harness that checks the Lean and OCaml functions agree on
  concrete inputs (property-based testing across the language boundary).
- Go further and formally verify the OCaml code against the Lean spec, either
  via extraction or a cross-language verification framework.

**Trust reduced**: the serialization model is no longer an abstraction — it is
verified to match the deployed code.

## Stage 2: FFT and polynomial arithmetic

The encoding and decoding algorithms (FFT-based RS encoding, Lagrange
interpolation) could be formalized as executable Lean functions and proved
correct against the abstract `interpolate` / `rsEncode` definitions. This
would replace the reliance on Mathlib's `Lagrange.interpolate` as the sole
computational model with a verified algorithm that matches what the
implementation actually computes (radix-2 DIT FFT, inverse FFT).

Concretely:
- Define an iterative radix-2 FFT in Lean over `ZMod r`.
- Prove it equals `DFT_ω` (the Vandermonde matrix-vector product).
- Prove that RS encoding via `FFT_n(IFFT_k(m) ‖ 0^{n−k})` equals
  `rsEncode` (evaluation at roots of unity).

**Trust reduced**: the algebraic properties A4 (interpolation correctness) and
A5 (polynomial uniqueness) remain proved from Mathlib, but the *computational
path* from bytes to codeword is also verified.

## Stage 3: KZG proof generation

The amortized multi-reveal algorithm (§"Multiple multi-reveals" in
`docs/protocol.md`) computes all `s` shard proofs in O(n log n) using the
Toeplitz-matrix-via-circulant-FFT trick. This could be formalized and proved to
produce the same proofs as the naive per-coset euclidean division.

This is where the `d ≥ 2l` constraint would finally appear in a proof: the
amortized algorithm's derivation of `q_i(x) = ⌊f(x) / (x^l − ω^{il})⌋` as a
DFT of the vector `(h_1, …, h_{s})` requires `d ≥ 2l` for the powers of
`φ = ω^l` to be present in the quotient.

Concretely:
- Define the naive per-coset proof: euclidean division of `p` by `Z_i`,
  commitment of the quotient.
- Define the amortized proof: Toeplitz multiplication via FFT, EC-DFT.
- Prove they produce identical `π_i` values.

**Trust reduced**: the proof generation algorithm is verified, not just
axiomatized. A7 (shard eval soundness) would still rest on the d-SDH
assumption, but the *computation* of the proofs would be machine-checked.

## Stage 4: Pairing and elliptic curve arithmetic

The deepest layer: formalize BLS12-381 curve arithmetic, the pairing
`e : G1 × G2 → GT`, and prove that the KZG verification equations are
algebraically correct. This would allow deriving A1 (eval soundness), A3
(degree soundness), and A7 (shard eval soundness) from the d-SDH assumption
rather than axiomatizing them individually.

This is a major undertaking — verified elliptic curve libraries are
multi-year research projects — but it would reduce the trust boundary to a
single cryptographic hardness assumption.

**Trust reduced**: the five KZG axioms (A1–A3, A6–A7) are proved from the
d-SDH assumption rather than trusted individually.

## Summary

| Stage | What is verified | Axioms removed | Effort |
|-------|-----------------|----------------|--------|
| 1. Serialization | Byte layout matches OCaml | (none, but model validated) | Low |
| 2. FFT / RS | Encoding/decoding algorithms | (none, but computational path verified) | Medium |
| 3. KZG proof gen | Amortized multi-reveal algorithm | (none, but `d ≥ 2l` used in proof) | Medium |
| 4. Pairings | BLS12-381 + KZG equations | A1, A3, A7 derived from d-SDH | High |

Each stage is independently valuable and does not require the subsequent stages.
The top-level properties (P1–P3, G13) remain unchanged throughout — only the
trust boundary shrinks.
