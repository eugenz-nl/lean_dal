# Harness Validator

Meta-auditor: checks that the KB, the skills, CLAUDE.md, and CURSOR.md form a
coherent, self-consistent harness for working on this formalization project. Produces
a report at `kb/reports/harness-report.md`.

This auditor does not check Lean proofs — it checks whether the *methodology itself*
is sound and complete.

## What to check

**KB completeness**
- Does `kb/index.md` exist and link to every KB file that exists on disk?
- Does every linked file in `kb/index.md` actually exist?
- Do all KB files have valid YAML frontmatter (`title`, `last-updated`, `status`)?

**Auditor coverage**
- Is there an auditor skill for each major quality dimension?
  - Ambiguity in the KB → ambiguity-auditor
  - Open proof obligations → sorry-auditor
  - Spec faithfulness → spec-compliance-auditor
  - This meta check → harness-validator
- Does every property in `kb/properties.md` fall under at least one auditor's scope?

**Ralph Loop integrity**
- Does CLAUDE.md (or CURSOR.md) describe the Ralph Loop?
- Does it reference the auditor skills by name?
- Does it require `lake build` as the final validation gate?

**Skill consistency**
- Does `kb-update.md` reference the ambiguity-auditor?
- Do auditor skills all write to `kb/reports/` with consistent frontmatter format?
- Are there skills referenced in CLAUDE.md / CURSOR.md that don't exist in
  `.claude/skills/`?

**KB vs. docs alignment**
- Does `kb/spec.md` exist and reference `docs/protocol.md` as its source?
- Are there sections of `docs/protocol.md` with no corresponding KB coverage?
  (Use section headings as a proxy.)

**Gap tracking**
- If `sorry` occurrences exist in Lean files, is there a `kb/gaps.md` or equivalent
  tracking them?
- Does `kb/properties.md` have a section for open obligations?

## Output format

Write `kb/reports/harness-report.md`:

```
---
auditor: harness-validator
date: <today>
status: <pass / N issues found>
---

## Broken Links
- [ ] kb/index.md links to <file> which does not exist

## Missing Auditor Coverage
- [ ] Property "<name>" in kb/properties.md is not covered by any auditor

## Ralph Loop Gaps
- [ ] CLAUDE.md does not mention `lake build` as the final gate

## Skill Inconsistencies
- [ ] Skill referenced in CLAUDE.md not found: <name>

## KB / Docs Alignment Gaps
- [ ] docs/protocol.md section "<heading>" has no KB coverage

## All Clear
- [x] <item that passed>
```
