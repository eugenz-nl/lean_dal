---
title: Design Decisions Index
last-updated: 2026-03-24
status: draft
---

# Formalization Design Decisions

Each file records a significant choice made in the formalization and its rationale.
Check here before re-opening a settled question.

## Decision status lifecycle

Every decision goes through the following states:

| Status | Meaning |
|--------|---------|
| `proposed` | Under discussion; no KB files updated yet |
| `accepted` | Decision is settled, but **the KB has not yet been updated** to reflect it |
| `implemented` | Decision is settled **and** all KB files listed in the decision's "KB changes" section have been updated accordingly |
| `superseded` | Replaced by a later decision (link provided) |

**A decision is only `implemented` when its "KB changes" section is fully applied.**
If `properties.md` still contradicts a decision marked `implemented`, the decision
status is wrong — fix it by updating the KB or reverting the status to `accepted`.

When creating a new decision:
1. Write the file with `status: proposed`.
2. Discuss/settle it with the human.
3. Change to `accepted` once the decision is settled.
4. Apply all KB changes listed in the "Consequences / KB changes" section.
5. Change to `implemented` only after step 4 is complete.

## Decision log

| File | Status | Decision |
|------|--------|----------|
| [001-kzg-axioms.md](001-kzg-axioms.md) | `implemented` | KZG security properties A1, A3, A6 are `axiom`; A4 and A5 are theorems to be proved |
| [002-kzg-over-poly.md](002-kzg-over-poly.md) | `implemented` | KZG functions operate on `Polynomial 𝔽_r`, not raw bytes |
| [003-field-parameters-as-axioms.md](003-field-parameters-as-axioms.md) | `implemented` | All deployment parameters are `axiom` declarations in `Dal/Field.lean` |
