# Spec Compliance Auditor

Check that the Lean formalization faithfully represents the DAL protocol as described
in `kb/spec.md` (which is itself derived from `docs/protocol.md`). Produce a report
at `kb/reports/spec-compliance-report.md`.

## What to check

**Theorem statement coverage**
- For each protocol property or rule named in `kb/spec.md`, verify that a
  corresponding Lean theorem statement exists. A `sorry`-bodied theorem counts as
  "stated but not proved" — record it but do not fail on it.
- Flag properties that have neither a theorem statement nor a KB gap entry.

**Semantic faithfulness of theorem statements**
- Read the Lean statement and compare it to the KB description. Does the quantifier
  structure match? Are the types consistent with the protocol's semantic model?
- Flag statements that are technically provable but clearly weaker than the spec
  intends (e.g., proving a property only for a single slot when the spec requires
  it for all slots).

**Type definition alignment**
- For each core protocol concept in `kb/glossary.md`, verify that the corresponding
  Lean type exists in the expected namespace and that its fields/constructors match
  the KB description.
- Flag type definitions that add fields not mentioned in the KB (may indicate spec
  drift) or omit fields that are mentioned.

**Namespace and module alignment**
- Verify that the module structure mirrors `kb/architecture.md`. A Lean file that
  covers multiple KB concepts (or a KB concept split across multiple Lean files
  without documentation) is a flag.

**Protocol rule completeness**
- The DAL protocol defines specific rules for attestation, publishing, sharding, and
  reconstruction. Verify that each named rule in `kb/spec.md` maps to at least one
  Lean definition or theorem.

## Output format

Write `kb/reports/spec-compliance-report.md`:

```
---
auditor: spec-compliance-auditor
date: <today>
status: <N critical, M warnings, K info>
---

## Critical

### [C1] <short title>
- **KB location**: kb/spec.md#<section>
- **Lean location**: <file:line or "missing">
- **Issue**: <description>
- **Recommendation**: <action>

## Warnings
...

## Info
...

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem | Status |
|--------------------------|----------|--------------|--------|
| ...                      | ...      | ...          | stated / proved / missing |
```
