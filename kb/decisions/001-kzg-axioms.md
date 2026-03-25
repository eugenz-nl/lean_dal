---
title: "Decision 001: KZG security properties are axioms"
last-updated: 2026-03-24
status: implemented
---

# Decision 001: KZG Security Properties Are Lean Axioms

## Context

The KZG polynomial commitment scheme has three security properties that underpin
the main theorems (P1 and P2):

- **A1** (eval soundness): a valid evaluation proof implies the existence of a
  committed polynomial with that evaluation.
- **A3** (degree soundness): a valid degree proof implies the committed polynomial
  has degree ≤ d.
- **A6** (commitment binding): two polynomials with the same commitment are equal.

These properties follow from the `d`-strong Diffie-Hellman (`d`-SDH) assumption
over the BLS12-381 curve — a computational hardness assumption. They cannot be
derived from the algebraic axioms of `𝔾_1`, `𝔾_2`, `𝔾_T` alone.

The document `docs/protocol.md` explicitly notes that A6 is "technically false, but
computationally infeasible to violate."

## Decision

Assert A1, A3, and A6 as Lean `axiom` declarations. Do not attempt to prove them
from first principles in Lean.

## Rationale

- The goal of this formalization is to prove that the DAL protocol is correct
  **given** the security of KZG. The cryptographic hardness assumptions are
  well-studied and out of scope for a protocol-level formalization.
- Assigning them as axioms makes the dependency explicit: readers can see exactly
  which assumptions P1 and P2 rely on.
- Attempting to prove them would require formalizing the BLS12-381 discrete
  logarithm hardness, which is a research-level effort in its own right.

## Consequences

- The `Dal/KZG.lean` module contains four `axiom` declarations: A1, A2, A3, A6.
  *(Note: the original decision text said "exactly three"; A2 was overlooked.
  Since `proveEval` is opaque, A2 cannot be proved and must also be an axiom.)*
- A fifth axiom A7 (`verifyShardEval_soundness`) is approved and planned for
  `Dal/KZG.lean` as part of gaps G8–G10.
- The soundness of P1 and P2 is conditional on A1–A3, A6. P3 will additionally
  require A7.
- Any future work that eliminates these axioms (e.g., by importing a verified
  cryptography library) can do so by replacing the axiom declarations with theorems.

## What NOT to do

- Do not assert additional axioms beyond A1, A2, A3, A6, A7 without explicit human approval.
- A4 (interpolation correctness) and A5 (polynomial uniqueness) are provable from
  Mathlib and must not be axiomatized.

## Extension: A7 (shard eval soundness) — approved 2026-03-25

- **A7** (shard eval soundness): `verifyShardEval c i vs π = true → ∃ p, commit p = c ∧ proveShardEval p i = π ∧ ∀ j, shardEval p i j = vs j`

This is the multi-reveal analogue of A1, underpinning P3 (shard verification implies
recovery). Like A1/A3/A6, it rests on the `d`-SDH assumption. It is approved for
declaration as a Lean `axiom` in `Dal/KZG.lean`. See gaps G8–G10 in `kb/gaps.md`.

## KB changes (required for `implemented` status)

- [x] `kb/properties.md`: A1, A3, A6 listed under **Axioms**; A4 and A5 moved to
  a separate **Provable lemmas** section (not axioms). *(Applied 2026-03-24.)*
