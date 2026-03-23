# Ambiguity Auditor

Examine all files in `kb/` and identify issues that would prevent an agent from
formalizing the protocol unambiguously. Output a structured report to
`kb/reports/ambiguity-report.md`.

## What to check

**Undefined or inconsistently used terms**
- Every protocol term used in `kb/spec.md` or `kb/architecture.md` must be defined
  in `kb/glossary.md`. Flag any term that appears without a glossary entry.
- Flag terms used in different senses across files (e.g., "slot" meaning two
  different things in spec vs. architecture).

**Vague protocol requirements**
- Flag requirements that are not precise enough to produce a unique Lean type or
  theorem statement. Examples: "nodes should eventually attest", "data is available
  with high probability". These need quantification or a precise formal criterion.

**Contradictions between files**
- Check whether `kb/spec.md` and `kb/architecture.md` make incompatible claims
  about the same concept.
- Check whether `kb/properties.md` states invariants that contradict the protocol
  description in `kb/spec.md`.

**Missing cross-references**
- Concepts mentioned in one KB file but not linked to their defining KB file.

**Stale content**
- KB files whose `last-updated` frontmatter is more than 30 days old.
- References to Lean definitions, modules, or namespaces that no longer exist.

**Proof obligation gaps**
- Properties listed in `kb/properties.md` with no corresponding Lean theorem
  identifier (even a `sorry`-tagged placeholder). These are invisible obligations.

## Output format

Write `kb/reports/ambiguity-report.md` with this structure:

```
---
auditor: ambiguity-auditor
date: <today>
status: <N critical, M warnings, K info>
---

## Critical

### [C1] <short title>
- **Location**: kb/spec.md, line <N>
- **Issue**: <precise description>
- **Recommendation**: <what to do>

## Warnings

### [W1] <short title>
- **Location**: ...
- **Issue**: ...
- **Recommendation**: ...

## Info

### [I1] <short title>
...
```

Severity guide:
- **Critical**: blocks formalization — a Lean definition cannot be written without
  resolving this
- **Warning**: formalization is possible but likely to diverge from intent
- **Info**: minor quality issue, stale metadata, or missing convenience link
