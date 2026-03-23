## Knowledge Base

- The `kb/` directory is the **source of truth** for this project. It defines what
  the formalization should be. The Lean files are an implementation of that definition.
- Read `kb/index.md` before starting any task to orient yourself.
- If your formalization contradicts `kb/spec.md`, `kb/architecture.md`, or
  `kb/properties.md`, your formalization is wrong. Fix the Lean files, not the KB.
- KB specification files (spec, architecture, properties, glossary, decisions) are
  only updated when the human explicitly refines the intent — never to accommodate
  formalization shortcuts.
- When creating new Lean modules or theorems that EXTEND the spec without contradicting
  it, add a corresponding KB entry and run the kb-update skill.
- After significant changes, run the kb-update skill to verify KB consistency.

## Working With the Knowledge Base

- Before working on any task, read `kb/index.md` and load the relevant KB files.
- The KB is the specification. Your Lean formalization must conform to it.
- Use `kb/properties.md` as your correctness checklist — every change must preserve
  listed invariants. If you cannot satisfy a property, stop and ask — do not
  silently drop, weaken, or `sorry` it.
- Use `kb/glossary.md` for terminology — use the exact terms defined there, both in
  KB prose and in Lean identifiers.
- When the task is ambiguous, check `kb/spec.md` and `kb/architecture.md` before
  asking the user. The answer is often already documented.
- If you find a contradiction between your formalization and the KB, the
  formalization is wrong. Fix the Lean to match the spec.
- Reference KB files in commit messages when a change is driven by a KB property
  or design decision.

## Lean-Specific Conventions

- A `sorry` or `admit` in a proof is a **known gap**, not a solution. Every `sorry`
  must be either (a) tagged `-- TODO: <reason>` with a corresponding KB TODO entry,
  or (b) removed before the task is marked complete.
- Theorem statements are part of the spec interface. Changing a statement is a
  spec change and requires updating the KB.
- Type definitions establish the semantic model of the protocol. Changing a type
  definition must be reflected in `kb/architecture.md`.
- Use namespaces and module paths that mirror the KB structure so agents can
  navigate between them.
- `lake build` with zero errors, zero warnings, and zero `sorry` occurrences is
  the binary pass/fail criterion for any completed task.

## Formalization Loop (Ralph Loop)

For every formalization task:
1. Write or modify Lean definitions, types, and theorem statements
2. Run all relevant auditor skills: `ambiguity-auditor`, `sorry-auditor`,
   `spec-compliance-auditor`, `harness-validator`
3. Read the audit reports in `kb/reports/`
4. Fix every issue found
5. Repeat steps 2–4 until all auditors pass clean
6. Run `lake build` — it must succeed with zero `sorry` before the task is done

Never skip the audit step. Never mark a task complete with unresolved audit findings
or outstanding `sorry` occurrences.
