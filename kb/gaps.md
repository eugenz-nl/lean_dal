---
title: Open Proof Obligations and Gaps
last-updated: 2026-03-23
status: draft
---

# Open Proof Obligations (Gaps)

This file tracks every open obligation in the formalization: `sorry`-tagged
theorems, missing definitions, and areas not yet analyzed.

See also: [properties.md](properties.md) for the full invariant list;
[architecture.md](architecture.md) for module locations.

---

## Status key

| Symbol | Meaning |
|--------|---------|
| `unstarted` | No Lean file or theorem statement exists |
| `in-progress` | Lean statement exists; proof is `sorry` |
| `blocked` | Waiting on a dependency (note which) |
| `resolved` | Proof complete |

---

## Infrastructure gaps (no Lean code yet)

These are areas where no Lean code exists and no `sorry` placeholders exist yet.
They must be addressed before the formalization is useful.

### G1: Entire formalization is unstarted

- **Scope**: All modules in `Dal/` (`Field`, `Poly`, `KZG`, `Sharding`,
  `Serialization`, `Protocol`, `Properties`)
- **Status**: `unstarted`
- **Reason**: Project just initialized; `Dal/Basic.lean` is a stub.
- **First task**: Implement `Dal/Field.lean` and `Dal/Poly.lean`, establishing
  basic types and the interpolation axioms (A4, A5).

---

## Known non-provable obligations (computational axioms)

These will never be proved — they are asserted as Lean `axiom` declarations.

### G2: Commitment binding (A6)

- **Statement**: `commit p = commit q → p = q`
- **Lean target**: `Dal.KZG.commit_binding`
- **Status**: `unstarted` (will be `axiom`)
- **Reason**: Binding is computational (d-strong Diffie-Hellman assumption), not a
  theorem of pure mathematics. See [decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

### G3: Eval soundness (A1)

- **Statement**: `verifyEval x y c π = true → ∃ p, commit p = c ∧ …`
- **Lean target**: `Dal.KZG.verifyEval_soundness`
- **Status**: `unstarted` (will be `axiom`)
- **Reason**: KZG soundness rests on the hardness of the discrete logarithm problem.

### G4: Degree soundness (A3)

- **Statement**: `verifyDegree c d π = true → ∃ p, …`
- **Lean target**: `Dal.KZG.verifyDegree_soundness`
- **Status**: `unstarted` (will be `axiom`)

---

## Potentially provable obligations (to investigate)

These may be provable from Mathlib rather than assumed as axioms.

### G5: Interpolation correctness (A4)

- **Statement**: `interpolate xs ys = p → deg p ≤ d ∧ ∀ i, eval p (xs i) = ys i`
- **Lean target**: `Dal.Poly.interpolate_correct`
- **Status**: `unstarted`
- **Note**: Mathlib has `Polynomial.Lagrange` — likely provable. Investigate before
  asserting as axiom.

### G6: Polynomial uniqueness (A5)

- **Statement**: two degree-`≤d` polynomials agreeing on `d+1` points are equal
- **Lean target**: `Dal.Poly.poly_unique_of_eval`
- **Status**: `unstarted`
- **Note**: Follows from `Polynomial.funext` or degree/root counting in Mathlib.
  Almost certainly provable.

### G7: Serialization injectivity (S1)

- **Statement**: `serialize b₁ = serialize b₂ → b₁ = b₂`
- **Lean target**: `Dal.Serialization.serialize_injective`
- **Status**: `unstarted`
- **Note**: The OCaml reference implementation is given in `docs/protocol.md` §
  "Serialize a byte sequence". Provable by construction once the Lean encoding is
  defined.

---

## TODO: Areas not yet analyzed

These sections of `docs/protocol.md` have no KB coverage and no Lean code. They
are lower priority for the initial formalization.

- **Multi-reveal proof computation** (§Multiple multi-reveals): the efficient
  `O((n/l) log(n/l))` algorithm for computing all `s` shard proofs simultaneously.
  This is an algorithmic result; formalization may not be needed unless we want
  verified proof generation.
- **Degree bound proof protocol** (§Bound proof on the degree of committed
  polynomials, lines 371–428): the interactive/non-interactive protocol for
  `PK{f : C = g^{f(α)} ∧ deg f ≤ d}`. The internal structure of this proof
  (Fiat-Shamir heuristic, two-round protocol) is not needed because A3 is
  axiomatized. Acceptable gap.
- **BLS12-381 curve definition**: the concrete curve equation and group law. The
  formalization treats `𝔾_1`, `𝔾_2` as opaque types with axiomatized operations.
- **FFT / DFT algorithms** (§Fast Fourier Transform, §Prime factor algorithm):
  These are the algorithmic building blocks for RS encoding and multi-reveal proofs.
  Out of scope — the formalization axiomatizes the mathematical properties of these
  operations rather than verifying the algorithm implementations.
