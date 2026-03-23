# KB Update

Maintain the KB as the formalization progresses. The KB is the source of truth —
Lean files must conform to the KB, not the other way around.

## Trigger

Run this after any change to:
- Lean module structure or namespace boundaries
- Type definitions or theorem statement interfaces
- Formalization design decisions or proof strategies
- Protocol terminology or Lean naming conventions
- Any addition of `sorry`-tagged gaps that require a KB TODO entry

## Process

1. Read `kb/index.md` to understand current KB structure
2. Compare the current changes against the relevant KB files
3. If the formalization contradicts a KB specification file (`spec.md`,
   `architecture.md`, `properties.md`, `glossary.md`, `decisions/`):
   - This is a formalization error. Flag it. Do NOT update the KB to match the Lean.
   - Fix the Lean to match the KB, or ask the user if the spec should be refined.
4. If the formalization introduces new concepts that EXTEND the KB without
   contradicting it:
   - Add new KB entries (new file or new section in an existing file)
   - Add the entry to the relevant `index.md`
   - Keep frontmatter `last-updated` current
   - Preserve cross-references; add new ones if needed
5. If new `sorry` placeholders were introduced, add corresponding TODO entries in
   `kb/properties.md` or a dedicated `kb/gaps.md` so the open obligations are
   tracked
6. Run the ambiguity auditor on modified KB files
7. Verify all links in modified files resolve correctly

## What NOT to do

- Never weaken a property in `kb/properties.md` because the proof is hard
- Never change `kb/spec.md` to match what the Lean happens to define
- Never remove an invariant because a theorem admits a `sorry` — fix the proof
  or escalate to the user
