---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 10
status: 4 warnings, 1 info
---

# Spec Compliance Report

## Changes since last run

Three open issues from run 9 (W1, W2, W3) are carried forward — they were not
resolved between run 9 and run 10. One info item (I1 — P1, P2 still `not
started`) is now partially resolved: `Dal/Protocol.lean` has been written and
both theorems are proved. However, the KB metadata for P1 and P2 in
`kb/properties.md` still reads `not started`, which is now stale and raises new
warnings.

New findings due to `Dal/Protocol.lean`:

- **[W4] NEW** — `kb/properties.md` P1 status is `not started` but
  `Dal.Protocol.rs_decoding_succeeds` is now fully proved.
- **[W5] NEW** — `kb/properties.md` P2 status is `not started` but
  `Dal.Protocol.page_verification_unique` is now fully proved.
- **[W6] NEW** — `kb/architecture.md` "Current state" still does not list
  `Dal/Protocol.lean` as implemented (it was missing before, and remains missing
  after the addition of `Dal/Protocol.lean`).
- **[W7] NEW** — `kb/gaps.md` G1 "Next task" bullet still reads "Implement
  `Dal/Protocol.lean`" — now stale, since Protocol.lean is complete.
- **[I1]** The proof statements require close review against the spec (see below).

---

## Statement Compliance Review

### P2: `page_verification_unique`

**Spec statement** (`kb/properties.md` §P2):
```
(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
→ ∃! p,  commit p = c
       ∧ (∀ i, πs i = proveEval p (xs i) (ys i))
```

**Lean statement** (`Dal/Protocol.lean` lines 45–50):
```lean
theorem page_verification_unique
    (c : G1) (xs : Fin (d + 1) → Fr) (ys : Fin (d + 1) → Fr)
    (πs : Fin (d + 1) → G1)
    (hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true) :
    ∃! p : Poly, commit p = c ∧
                 ∀ i, proveEval p (xs i) (ys i) = some (πs i)
```

**Analysis**: The spec uses `πs i = proveEval p (xs i) (ys i)` (proof equality
in `G1`) while the Lean statement uses `proveEval p (xs i) (ys i) = some (πs i)`
(option equality, since `proveEval` returns `Option G1`). The Lean form is
strictly stronger and more precise: it asserts that `proveEval` succeeds and
returns exactly `πs i`. The spec notation `πs i = proveEval p (xs i) (ys i)` was
written informally assuming `proveEval` returns `G1` directly rather than
`Option G1`. The Lean statement is correct and conformant with the actual types
declared in `Dal/KZG.lean`. This is an acceptable strengthening; the spec prose
should be updated for clarity.

**Verdict**: Conformant. Minor terminology gap noted as [I1] below.

### P1: `rs_decoding_succeeds`

**Spec statement** (`kb/properties.md` §P1):
```
(∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
→ verifyDegree c d π_deg = true
→ ∃! p,  commit p = c
       ∧ (∀ i, πs i = proveEval p (xs i) (ys i))
       ∧ interpolate xs ys = p
```

**Lean statement** (`Dal/Protocol.lean` lines 77–85):
```lean
theorem rs_decoding_succeeds
    (c : G1) (xs : Fin (d + 1) → Fr) (hxs : Function.Injective xs)
    (ys : Fin (d + 1) → Fr)
    (πs : Fin (d + 1) → G1) (π_deg : G1)
    (hverify : ∀ i, verifyEval (xs i) (ys i) c (πs i) = true)
    (hdeg : verifyDegree c d π_deg = true) :
    ∃! p : Poly, commit p = c ∧
                 (∀ i, proveEval p (xs i) (ys i) = some (πs i)) ∧
                 interpolate xs ys = p
```

**Analysis**: Same `Option G1` strengthening as P2. Additionally, the Lean
statement includes the explicit hypothesis `hxs : Function.Injective xs`
(distinct evaluation points). The spec statement omits this but the proof plan
(§P1) notes that A5 requires distinct evaluation points. Adding `hxs` as an
explicit hypothesis is correct: the distinctness precondition is part of the true
mathematical statement. The spec prose should be updated to include this
precondition explicitly.

**Verdict**: Conformant. The `hxs` precondition is a spec clarification, not a
weakening. Noted as [I1] below.

---

## Warnings

### [W1] `shard_recovery` namespace: `Dal.ReedSolomon` vs `Dal.Protocol`

*(Carried forward from run 9.)*

- **KB location**: `kb/properties.md` § S4, Lean target `Dal.Protocol.shard_recovery`;
  status `not started`
- **Lean location**: `dal/Dal/ReedSolomon.lean`, `namespace Dal.ReedSolomon`
- **Action required**: Update `kb/properties.md` S4:
  - Lean target → `Dal.ReedSolomon.shard_recovery`
  - Status → `proved`

### [W2] `kb/architecture.md` "Current state" does not include `Dal/ReedSolomon.lean`

*(Carried forward from run 9.)*

- **KB location**: `kb/architecture.md` § Current state
- **Note**: `Dal/ReedSolomon.lean` is implemented; the "Current state" sentence still
  reads as if it ends at `Dal/Serialization.lean`.
- **Action required**: Update "Current state" to include `Dal/ReedSolomon.lean`.

### [W3] `cosetPoints` domain type: spec says `Fin (k / l * l)`, Lean uses `Fin (d + 1)`

*(Carried forward from run 9.)*

- **Action required**: Update `kb/spec.md` § S4 helper functions to use `Fin (d + 1)`
  or add a note documenting the equivalence.

### [W4] `kb/properties.md` P2 status is `not started` — theorem is now proved

- **KB location**: `kb/properties.md` § P2: Page verification uniqueness, status field
- **Reality**: `Dal/Protocol.lean` contains `theorem page_verification_unique` in
  `namespace Dal.Protocol`, proved without `sorry`.
- **Impact**: An agent consulting `properties.md` would conclude P2 is unimplemented
  and attempt to write it again.
- **Action required**: Update `kb/properties.md` P2 entry:
  - Status → `proved`

### [W5] `kb/properties.md` P1 status is `not started` — theorem is now proved

- **KB location**: `kb/properties.md` § P1: RS decoding succeeds, status field
- **Reality**: `Dal/Protocol.lean` contains `theorem rs_decoding_succeeds` in
  `namespace Dal.Protocol`, proved without `sorry`.
- **Impact**: Same as W4 — stale `not started` would mislead agents.
- **Action required**: Update `kb/properties.md` P1 entry:
  - Status → `proved`
  - Note: add `hxs : Function.Injective xs` to the formal statement to match Lean.

### [W6] `kb/architecture.md` "Current state" does not include `Dal/Protocol.lean`

- **KB location**: `kb/architecture.md` § Current state, first paragraph
- **Reality**: `Dal/Protocol.lean` is now implemented. `Dal.lean` imports it on
  line 7 (`import Dal.Protocol`).
- **Issue**: The "Current state" paragraph lists modules up through `Dal/ReedSolomon.lean`
  (which itself is already a carried-forward gap from W2) and states "All other modules
  are unstarted." Both `Dal/ReedSolomon.lean` and `Dal/Protocol.lean` contradict this.
- **Action required**: Update "Current state" to add `Dal/Protocol.lean` to the list of
  implemented modules; add an implementation notes section `### Implementation notes for
  Dal/Protocol.lean` documenting the proof strategy (A1+A6 for P2; A1+A6+A2+A3+A4+A5
  for P1) and the `Option G1` / `Function.Injective` strengthening vs the spec prose.

### [W7] `kb/gaps.md` G1 "Next task" pointer is stale after `Dal/Protocol.lean` completion

- **KB location**: `kb/gaps.md` § G1, "Next task" bullet
- **Current text**: "Next task: Implement `Dal/Protocol.lean` — assemble P1 (RS decoding
  succeeds) and P2 (page verification uniqueness) from the existing axioms A1–A6."
- **Reality**: `Dal/Protocol.lean` is now complete with P1 and P2 proved.
- **Action required**: Update G1:
  - Add "Completed" bullet for `Dal/Protocol.lean` listing `page_verification_unique`
    (P2) and `rs_decoding_succeeds` (P1). Both proved without `sorry`.
  - Update "Next task" to reflect remaining work (KB metadata updates, or
    `Dal/Properties.lean` if desired).

---

## Info

### [I1] Lean statements are strictly stronger than spec prose in two ways

- **`proveEval` returns `Option G1`**: The spec prose writes
  `πs i = proveEval p (xs i) (ys i)` as if `proveEval` returns `G1` directly.
  The Lean form `proveEval p (xs i) (ys i) = some (πs i)` is more precise.
  `kb/properties.md` P1 and P2 spec statements should be updated to use
  `proveEval p (xs i) (ys i) = some (πs i)`.
- **`hxs : Function.Injective xs` in P1**: The spec proof plan mentions distinctness
  but does not list it as a hypothesis in the formal statement box.
  `kb/properties.md` P1 statement block should add `hxs : Function.Injective xs`
  as an explicit precondition.

---

## Coverage Matrix

| Protocol Rule / Property | KB Entry | Lean Theorem/Def | Status |
|--------------------------|----------|------------------|--------|
| Field `𝔽_r` type | spec.md § Types | `Dal.Field.Fr` | proved |
| All deployment parameters & constraints | spec.md § Parameters | `Dal.Field.*` | axiom |
| `ω` primitive root | spec.md § Parameters | `Dal.Field.ω`, `ω_isPrimitiveRoot` | axiom |
| `Poly` type | spec.md § Types | `Dal.Poly.Poly` | proved |
| `interpolate` function | spec.md § Functions | `Dal.Poly.interpolate` | proved |
| A4: Interpolation correctness (eval) | properties.md | `Dal.Poly.interpolate_eval` | proved |
| A4: Interpolation correctness (degree) | properties.md | `Dal.Poly.interpolate_natDegree` | proved |
| A5: Polynomial uniqueness | properties.md | `Dal.Poly.poly_unique_of_eval` | proved |
| `G1`, `G2`, `GT` types | spec.md § Types | `Dal.KZG.G1/G2/GT` | axiom |
| `commit` function | spec.md § Functions | `Dal.KZG.commit` | axiom |
| `proveEval` function | spec.md § Functions | `Dal.KZG.proveEval` | axiom |
| `verifyEval` function | spec.md § Functions | `Dal.KZG.verifyEval` | axiom |
| `proveDegree` function | spec.md § Functions | `Dal.KZG.proveDegree` | axiom |
| `verifyDegree` function | spec.md § Functions | `Dal.KZG.verifyDegree` | axiom |
| A1: Eval soundness | properties.md | `Dal.KZG.verifyEval_soundness` | axiom |
| A2: Eval completeness | properties.md | `Dal.KZG.proveEval_complete` | axiom |
| A3: Degree soundness | properties.md | `Dal.KZG.verifyDegree_soundness` | axiom |
| A6: Commitment binding | properties.md | `Dal.KZG.commit_binding` | axiom |
| `cosetPoint` function | spec.md § Sharding | `Dal.Sharding.cosetPoint` | proved |
| `Ω` (coset finset) | spec.md § Sharding, glossary.md | `Dal.Sharding.Ω` | proved |
| `Z` (vanishing polynomial) | spec.md § Sharding, glossary.md | `Dal.Sharding.Z` | proved |
| `shardEval` function | spec.md § Sharding | `Dal.Sharding.shardEval` | proved |
| S2: Coset partition (union) | properties.md | `Dal.Sharding.coset_partition` | proved |
| S2: Coset partition (disjoint) | properties.md | `Dal.Sharding.cosets_disjoint` | proved |
| S3: Vanishing polynomial roots | properties.md | `Dal.Sharding.vanishing_poly_roots` | proved |
| `Bytes` type | architecture.md § Serialization | `Dal.Serialization.Bytes` | proved |
| `slot_size ≤ k * 31` constraint | spec.md § Parameters | `Dal.Serialization.slot_size_le` | axiom |
| `256^31 < r` constraint | spec.md § Parameters | `Dal.Serialization.bytes31_lt_r` | axiom |
| `serialize` function | spec.md § Data flow | `Dal.Serialization.serialize` | proved |
| S1: Serialization injectivity | properties.md | `Dal.Serialization.serialize_injective` | proved |
| `rsEncode` function | spec.md § Reed-Solomon | `Dal.ReedSolomon.rsEncode` | proved |
| `cosetPoints` helper | spec.md § S4 helpers | `Dal.ReedSolomon.cosetPoints` | proved (see W3 re: domain type) |
| `shardVals` helper | spec.md § S4 helpers | `Dal.ReedSolomon.shardVals` | proved (see W3 re: domain type) |
| S4: Shard recovery (MDS) | properties.md | `Dal.ReedSolomon.shard_recovery` | proved (see W1 re: namespace) |
| P2: Page verification uniqueness | properties.md | `Dal.Protocol.page_verification_unique` | **proved** |
| P1: RS decoding succeeds | properties.md | `Dal.Protocol.rs_decoding_succeeds` | **proved** |
| `shardRemainder` function | spec.md § Sharding | missing | not started |
| `proveShardEval` function | spec.md § Sharding | missing | not started |
| `verifyShardEval` function | spec.md § Sharding | missing | not started |
| `rsDecode` function | spec.md § Reed-Solomon | missing | not started |
