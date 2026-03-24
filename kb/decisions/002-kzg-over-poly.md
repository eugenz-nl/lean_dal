---
title: "Decision 002: KZG operates on Polynomial 𝔽_r"
last-updated: 2026-03-24
status: implemented
---

# Decision 002: KZG Functions Operate on `Polynomial 𝔽_r`

## Context

The KZG `commit`, `proveEval`, `verifyEval` functions can be typed at different
levels of abstraction:

1. **Raw bytes** (`ByteArray → G1`): closest to the implementation, but mixes
   serialization concerns with cryptographic correctness.
2. **Scalar vectors** (`Fin k → 𝔽_r → G1`): the DATA representation; still tied
   to a fixed slot size.
3. **Polynomials** (`Polynomial 𝔽_r → G1`): the mathematical objects that KZG
   actually commits to.

## Decision

KZG functions in `Dal/KZG.lean` operate on `Polynomial 𝔽_r` (Mathlib's polynomial
type). The conversion from bytes to polynomials is handled in `Dal/Serialization.lean`
and `Dal/ReedSolomon.lean`.

## Rationale

- The KZG correctness properties (A1–A6) are naturally stated in terms of
  polynomials. Lifting them to byte-level would add irrelevant complexity.
- `Polynomial 𝔽_r` integrates with Mathlib's polynomial library (degree, eval,
  interpolation lemmas).
- The separation of concerns makes each module independently verifiable.
- The top-level properties P1 and P2 are cleanly stated at the polynomial level.

## Consequences

- `Dal/KZG.lean` does not import `Dal/Serialization.lean`.
- The data flow `bytes → scalars → poly → commitment` is made explicit in
  `Dal/Protocol.lean`.
- Shard operations work on evaluations (`𝔽_r`) not on the polynomial directly, but
  the polynomial is the shared object that links commitment to shards.

## KB changes (required for `implemented` status)

- [x] `kb/architecture.md`: `Dal/KZG.lean` module description states it operates
  on `Polynomial 𝔽_r` and does not import `Serialization`. *(Present from initial
  bootstrap 2026-03-23.)*
