# Sorry Auditor

Scan all `.lean` files for `sorry` and `admit` occurrences and produce a structured
report at `kb/reports/sorry-report.md`. Every `sorry` is an open proof obligation
that must be tracked and eventually discharged.

## What to check

**Locate all `sorry` / `admit` usages**
- Search every `.lean` file under the project root for `sorry` and `admit`.
- Record: file path, line number, enclosing theorem/definition name, and any
  `-- TODO:` comment on the same or adjacent line.

**Classify each occurrence**

| Class | Meaning |
|-------|---------|
| `tracked` | Has a `-- TODO: <reason>` comment AND a corresponding entry in `kb/properties.md` or `kb/gaps.md` |
| `untracked` | No TODO comment and/or no KB entry — this is a silent gap |
| `structural` | `sorry` used as a type hole in a definition (not a proof) — flag separately |

**Cross-check with KB**
- Every `tracked` sorry should map to a named open obligation in `kb/properties.md`
  or `kb/gaps.md`. Flag any KB obligation that has no sorry counterpart (it may be
  missing from the formalization entirely).

**Trend**
- If a previous sorry-report exists, compare counts and flag regressions (new
  sorries added since last audit).

## Output format

Write `kb/reports/sorry-report.md`:

```
---
auditor: sorry-auditor
date: <today>
status: <N untracked, M tracked, K structural>
---

## Summary

| File | Untracked | Tracked | Structural |
|------|-----------|---------|------------|
| ...  | ...       | ...     | ...        |

## Untracked Sorries (must be resolved before task is complete)

### [U1] <File>:<line> — <theorem name>
- **Lean**: `<snippet>`
- **Recommendation**: add `-- TODO: <reason>` and create KB gap entry, or discharge
  the proof

## Tracked Sorries (known open obligations)

### [T1] <File>:<line> — <theorem name>
- **KB entry**: kb/properties.md#<anchor>
- **TODO comment**: <text>

## Structural Holes

### [S1] <File>:<line> — <definition name>
- **Lean**: `<snippet>`
- **Recommendation**: <fill in type or escalate>
```
