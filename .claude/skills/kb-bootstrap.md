# KB Bootstrap

Build the initial `kb/` for this Lean formalization of the Tezos DAL protocol.
Work incrementally but be THOROUGH — quality matters more than speed. It is normal
and expected for this process to take a long time. Do not cut corners to finish faster.

The goal: an agent reading only the KB (without reading `docs/protocol.md` or the
Lean source) should be able to understand what needs to be formalized, why, and how
the formalization is structured.

## Step 1: Reconnaissance (read, don't write yet)

Understand the shape of the project:
- Read `docs/protocol.md` in full — this is the primary source for the formalization
- Read `README.md` and any existing `.lean` files (entry points, core type definitions)
- Read `lakefile.lean` or `lakefile.toml` to understand module structure and dependencies
- Read `CLAUDE.md` for methodology constraints
- Skim any existing `kb/` files to avoid duplicating work

Do NOT try to formalize anything yet. You are building a map, not a proof.

## Step 2: Assess scope and choose KB structure

Based on reconnaissance, identify:
- The core protocol concepts that must be formalized (types, rules, invariants)
- The main sections of `docs/protocol.md` and how they map to formalization modules
- Any existing Lean definitions and how far the formalization has progressed

The KB structure for this project:

```
kb/
  index.md              # Top-level map: what's in the KB, how to navigate it
  spec.md               # What the DAL protocol is and does (derived from docs/protocol.md)
  architecture.md       # How the formalization is structured (Lean modules, namespaces)
  properties.md         # Mathematical invariants to prove, with proof status
  glossary.md           # Protocol and Lean terminology with precise definitions
  gaps.md               # Open proof obligations (sorry-tagged theorems, missing cases)
  decisions/
    index.md
    # One file per significant formalization choice (e.g., how to model availability)
  reports/              # Written by auditors — do not create manually
```

Write `kb/index.md` FIRST as the skeleton — fill in the other files next.

## Step 3: Build the KB iteratively

For each file listed in `kb/index.md`:

1. Read the relevant sections of `docs/protocol.md` and any existing Lean source
   needed to write that KB file (targeted reads — not everything)
2. Write the KB file with:
   - YAML frontmatter: `title`, `last-updated` (today), `status: draft`
   - Cross-references to related KB files using relative markdown links
   - One concept per file — if a section grows beyond 200 lines, split it
   - Written for an agent reader: explicit, unambiguous, complete
   - Concrete formal criteria over vague prose (prefer "∀ slot s, …" over
     "slots are eventually attested")
3. Move to the next file

Priority order: `spec.md` → `glossary.md` → `properties.md` → `architecture.md`
→ `gaps.md` → `decisions/`

For `properties.md`, every invariant must include:
- A plain-English statement
- A sketch of the expected Lean type signature (even if not yet written)
- Current proof status: `not started` / `stated` / `sorry` / `proved`

## Step 4: Validate

- Read `kb/index.md` and verify every link resolves to an existing file
- Check that every KB file has valid YAML frontmatter
- Check for contradictions between files (e.g., a type in `spec.md` described
  differently in `glossary.md`)
- Run the ambiguity auditor: `/ambiguity-auditor`
- Run the harness validator: `/harness-validator`
- Fix every critical and warning finding before declaring the bootstrap complete

## Step 5: Declare bootstrap complete

The bootstrap is complete when:
- All files listed in `kb/index.md` exist and have `status: draft` or better
- The ambiguity auditor reports zero critical findings
- The harness validator reports no broken links
- Every property in `kb/properties.md` has a proof status field

## What NOT to do

- Do not write Lean during the bootstrap — KB first, formalization second
- Do not copy-paste `docs/protocol.md` sections verbatim — distill and formalize
  the intent; the KB should be shorter and more precise than the source docs
- Do not create empty KB files to fill the structure — every file must contain
  knowledge an agent actually needs
- Do not mark the bootstrap complete while critical ambiguity-auditor findings remain
