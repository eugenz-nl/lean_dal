---
title: KB Index — Lean DAL Formalization
last-updated: 2026-03-23
status: draft
---

# Knowledge Base: Lean Formalization of Tezos DAL

This KB is the source of truth for the formalization project. The Lean files in
`dal/` are the implementation of what is described here. If a Lean file contradicts
this KB, the Lean file is wrong.

## Source material

- `docs/protocol.md` — primary source: the DAL protocol specification. The KB
  distills and formalizes this document's intent.

## Files in this KB

| File | What it contains |
|------|-----------------|
| [spec.md](spec.md) | What the DAL protocol is: data types, functions, specifications (axioms), and the two main properties to prove |
| [architecture.md](architecture.md) | How the formalization is structured: planned Lean modules, namespaces, and their responsibilities |
| [properties.md](properties.md) | Exhaustive list of mathematical invariants to prove, with proof status and expected Lean signatures |
| [glossary.md](glossary.md) | Precise definitions of every protocol and Lean term used in the KB |
| [gaps.md](gaps.md) | Open proof obligations: `sorry`-tagged theorems and missing formalization areas |
| [decisions/index.md](decisions/index.md) | Index of formalization design decisions (ADRs) |

## Navigation guide

- Start here when picking up any task.
- Load `spec.md` for protocol semantics and the top-level correctness statements.
- Load `glossary.md` to resolve any term before using it in Lean.
- Load `properties.md` to check which invariants your change must preserve.
- Load `architecture.md` to decide where in the module hierarchy a new definition belongs.
- Check `gaps.md` before adding a `sorry` — it may already be tracked, or the obligation may already exist elsewhere.
- Check `decisions/` before choosing between two formalization approaches.

## Deterministic validation gate

`lake build` in `dal/` must succeed with zero errors, zero warnings, and zero
`sorry` occurrences before any task is considered complete.
