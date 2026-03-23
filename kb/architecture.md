---
title: Formalization Architecture
last-updated: 2026-03-23
status: draft
---

# Formalization Architecture

Describes how the Lean formalization is structured: modules, namespaces,
dependencies, and each module's responsibility.

See also: [spec.md](spec.md) for what is being formalized; [glossary.md](glossary.md)
for term definitions.

---

## Current state

The Lean project (`dal/`) is a blank slate. Only `Dal/Basic.lean` (a stub) and
`Dal.lean` (imports `Dal/Basic`) exist. The architecture below is the **plan** for
the formalization.

---

## Lake project

```
dal/
  lakefile.toml       # Project config: depends on Mathlib v4.29.0-rc1
  Dal.lean            # Top-level import of all modules
  Dal/
    Basic.lean        # (stub — to be repurposed or removed)
    Field.lean        # Scalar field 𝔽_r and its properties
    Poly.lean         # Polynomials, degree, eval, interpolate
    ReedSolomon.lean  # RS encoding/decoding, MDS property
    KZG.lean          # KZG commitment scheme: types, axioms, functions
    Sharding.lean     # Cosets, vanishing polynomials, shard structure
    Serialization.lean # byte ↔ scalar array conversion
    Protocol.lean     # Top-level assembly: slot → shards → verify
    Properties.lean   # Formal statements of P1, P2, S1–S4
```

---

## Module responsibilities

### `Dal/Field.lean`
- Declares `𝔽_r` as `ZMod r` for the BLS12-381 scalar field prime `r`.
- States and (if possible) proves existence of a primitive `n`-th root of unity `ω`
  in `𝔽_r` (condition: `n | r - 1`).
- Exports `ω`, basic field arithmetic.
- **Does not** contain elliptic curve definitions.

### `Dal/Poly.lean`
- Type alias: `Poly := Polynomial (ZMod r)`.
- Wraps Mathlib's `Polynomial.eval`.
- Defines `interpolate`: given `d+1` distinct points `xs` and values `ys`, returns
  the unique polynomial of degree `≤ d` with those evaluations. Use Mathlib's
  `Lagrange.interpolate` or `Polynomial.interpolate`.
- Proves A4 (interpolation correctness) and A5 (polynomial uniqueness) from Mathlib.
- **Key invariant**: interpolation is defined only when `xs` are distinct.

### `Dal/ReedSolomon.lean`
- Defines `rsEncode : Poly → Fin n → 𝔽_r` as evaluation at `ω^i`.
- Defines the `k/l` shard recovery condition: any `k` evaluations determine `p`.
- States S4 (shard recovery / MDS property).
- References: `Field.lean`, `Poly.lean`.

### `Dal/KZG.lean`
- Declares opaque types `G1`, `G2`, `GT` for BLS12-381 groups.
- Declares the pairing `e : G1 → G2 → GT` as an `opaque` or `axiom`.
- Declares `CK` (committing key) and `VK` (verifying key) as parameters.
- Defines `commit`, `proveEval`, `verifyEval`, `proveDegree`, `verifyDegree`.
- Asserts A1, A2, A3, A6 as `axiom`. Proves A4, A5 (or references `Poly.lean`).
- **Key design choice**: KZG functions operate on `Poly`, not raw byte arrays. See
  [decisions/002-kzg-over-poly.md](decisions/002-kzg-over-poly.md).

### `Dal/Sharding.lean`
- Defines `Ω : Fin s → Finset 𝔽_r` (the `s` cosets).
- Defines `Z : Fin s → Poly` (the vanishing polynomials `Z_i(x) = x^l - ω^{il}`).
- Defines `shard : Poly → Fin s → Fin l → 𝔽_r` as `eval p (coset_point i j)`.
- States and proves S2 (coset partition) and S3 (vanishing polynomial roots).
- References: `Field.lean`, `Poly.lean`.

### `Dal/Serialization.lean`
- Defines the bijection between `Bytes slot_size` and `Fin k → 𝔽_r`.
- Proves S1 (injectivity of serialization).
- The 31-bytes-per-scalar encoding is fixed in this module.

### `Dal/Protocol.lean`
- Defines the end-to-end pipeline: `slot → DATA → POLY → (commitment, shards, proofs)`.
- Defines `proveShardEval` and `verifyShardEval` (multi-reveal).
- Assembles P1 and P2 from the axioms and lemmas in other modules.
- This module imports all other modules.

### `Dal/Properties.lean`
- Contains only the formal statements of P1, P2, S1–S4 (and their proofs, once
  complete). Importing this file gives the full correctness guarantee.
- All theorems here must be proved without `sorry` before the project is complete.

---

## Dependency graph

```
Field ──────────────────────────────────────────┐
  │                                             │
  ▼                                             │
Poly ──────────────┬──────────────────────────  │
  │                │                            │
  ▼                ▼                            ▼
ReedSolomon    Sharding    Serialization      KZG
      │              │          │              │
      └──────────────┴──────────┴──────────────┘
                                               │
                                               ▼
                                           Protocol
                                               │
                                               ▼
                                          Properties
```

---

## Mathlib dependencies

| Need | Mathlib location |
|------|-----------------|
| Polynomial type and `eval` | `Mathlib.RingTheory.Polynomial.Basic` |
| Lagrange interpolation | `Mathlib.RingTheory.Polynomial.Lagrange` |
| Finite fields | `Mathlib.FieldTheory.Finite.Basic` |
| Roots of unity | `Mathlib.RingTheory.RootsOfUnity.Basic` |
| `ZMod` | `Mathlib.Data.ZMod.Basic` |
| Finset tools | `Mathlib.Data.Finset.Basic` |

---

## Lean version and toolchain

- Lean 4 (via Mathlib v4.29.0-rc1)
- `lakefile.toml` option `relaxedAutoImplicit = false` — all implicit arguments
  must be declared. Keep this enabled to prevent silent universe polymorphism bugs.
