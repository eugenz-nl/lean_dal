---
title: "Decision 003: All deployment parameters are axioms in Dal/Field.lean"
last-updated: 2026-03-24
status: implemented
---

# Decision 003: All Deployment Parameters Are Lean Axioms in `Dal/Field.lean`

## Context

The DAL protocol has several deployment parameters (`r`, `n`, `k`, `s`, `l`, `α`,
`slot_size`, `d`) and associated constraints (`n ∣ r-1`, `s ∣ n`, `l = n/s`,
`d = k-1`, `α = n/k ≥ 2`, `d ≥ 2l`, `l ∣ k`).

These parameters are global constants for a fixed DAL deployment. They need to be
in scope in every module. Two approaches were possible:

1. **`variable` declarations**: thread parameters through every function signature
   implicitly. Lean resolves them from context.
2. **`axiom` declarations in `Dal/Field.lean`**: declare them once as named axioms;
   every downstream module simply imports `Dal.Field`.

## Decision

All deployment parameters and their constraints are declared as `axiom` in
`Dal/Field.lean`. Downstream modules import `Dal.Field` and use the names directly.

## Rationale

- **Readability**: function signatures in `Dal/Poly.lean`, `Dal/KZG.lean`, etc. are
  not cluttered with parameter lists. The field-theoretic context is implicit.
- **Consistency**: KZG security properties (A1, A3, A6) are already axioms (Decision
  001). The cryptographic constants (`ω`, `τ`-derived SRS values) are also axioms.
  Treating deployment parameters the same way maintains a uniform style.
- **Single source of truth**: all global constants live in one file. Any future
  concrete instantiation (e.g., with the actual BLS12-381 prime) replaces only
  `Dal/Field.lean`.

## What NOT to do

- Do not re-declare parameters as `variable` in other modules — import `Dal.Field`.
- Do not add constraints as `axiom` in modules other than `Dal/Field.lean`; keep all
  global constraints co-located with the parameters they constrain.

## Consequences

- `Dal/Field.lean` is the sole file that axiomatizes deployment parameters.
- All other modules (`Poly`, `KZG`, `Sharding`, `Serialization`, `Protocol`,
  `Properties`) begin with `import Dal.Field` and use the axiom names directly.
- The dependency graph remains as specified in `kb/architecture.md`.

## KB changes (required for `implemented` status)

- [x] `kb/architecture.md` § Implementation notes for `Dal/Field.lean`: documents
  the axiom-not-variable choice. *(Applied 2026-03-24.)*
- [x] `kb/decisions/index.md`: this ADR added. *(Applied 2026-03-24.)*
- [x] `Dal/Field.lean`: all deployment parameters (`r`, `n`, `k`, `s`, `l`, `α`,
  `slot_size`, `d`) and constraints axiomatized. *(Applied 2026-03-24.)*
