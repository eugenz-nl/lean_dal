---
auditor: spec-compliance-auditor
date: 2026-03-24
run: 9
status: 3 warnings, 1 info
---

# Spec Compliance Report

## Changes since last run

One resolved issue from run 8:

- **W1 resolved** (from run 8): `kb/gaps.md` G7 note still referenced the stale axiom
  name `slot_size_eq`; that stale reference is tracked as a carried-forward item by
  the harness-validator — it is not re-raised as a new finding here.

Three new issues identified due to the addition of `Dal/ReedSolomon.lean`:

- **[W1] NEW** — `shard_recovery` is proved in `Dal.ReedSolomon` but
  `kb/properties.md` lists its Lean target as `Dal.Protocol.shard_recovery`.
- **[W2] NEW** — `kb/architecture.md` "Current state" does not list
  `Dal/ReedSolomon.lean` as implemented.
- **[W3] NEW** — `kb/spec.md` § S4 helper functions specifies `cosetPoints` with
  domain `Fin (k / l * l)`, but the Lean implementation uses `Fin (d + 1)`.
- **[I1]** carried forward from run 8: P1 and P2 still `not started`.

---

## Warnings

### [W1] `shard_recovery` namespace: `Dal.ReedSolomon` vs `Dal.Protocol`

- **KB location**: `kb/properties.md` § S4: Shard recovery (MDS property), Lean
  target field: `Dal.Protocol.shard_recovery`; status field: `not started`
- **Lean location**: `dal/Dal/ReedSolomon.lean` lines 144–161:
  `theorem shard_recovery` in `namespace Dal.ReedSolomon`
- **Issue**: `properties.md` lists the target namespace as `Dal.Protocol`, implying
  `shard_recovery` belongs in `Dal/Protocol.lean`. The actual theorem lives in
  `Dal.ReedSolomon`. The KB status `not started` is also wrong — the theorem is
  fully proved.
- **Impact**: An agent consulting `properties.md` would conclude S4 is unproved and
  would attempt to write it again in `Dal/Protocol.lean`, creating a duplicate.
- **Action required**: Update `kb/properties.md` S4 entry:
  - Change Lean target to `Dal.ReedSolomon.shard_recovery`
  - Change status to `proved`

### [W2] `kb/architecture.md` "Current state" does not include `Dal/ReedSolomon.lean`

- **KB location**: `kb/architecture.md` § Current state, first paragraph:
  "`Dal/Field.lean`, `Dal/Poly.lean`, `Dal/KZG.lean`, `Dal/Sharding.lean`, and
  `Dal/Serialization.lean` are implemented and build clean. All other modules are
  unstarted."
- **Lean location**: `dal/Dal/ReedSolomon.lean` — file exists and is complete.
  `dal/Dal.lean` line 6: `import Dal.ReedSolomon`.
- **Issue**: The "Current state" paragraph does not mention `Dal/ReedSolomon.lean`,
  and "All other modules are unstarted" is now false.
- **Action required**: Update the "Current state" sentence to include
  `Dal/ReedSolomon.lean` in the list of implemented modules, and add an
  `### Implementation notes for Dal/ReedSolomon.lean` section documenting the
  key design choices (`d_succ_eq_k`, `kl_eq_d_succ`, `cosetPoints` using
  `Finset.orderIsoOfFin`, proof strategy for `cosetPoints_injective` via
  `cosets_disjoint` and `ω_pow_inj`).

### [W3] `cosetPoints` domain type: spec says `Fin (k / l * l)`, Lean uses `Fin (d + 1)`

- **KB location**: `kb/spec.md` § S4 helper functions:
  "`cosetPoints : Finset (Fin s) → Fin (k / l * l) → X`"
- **Lean location**: `dal/Dal/ReedSolomon.lean` line 68:
  `noncomputable def cosetPoints (I : Finset (Fin s)) (hI : I.card = k / l) (m : Fin (d + 1)) : Fr`
- **Analysis**: The Lean file uses `Fin (d + 1)` as the domain index type rather
  than `Fin (k / l * l)`. These are propositionally equal by the lemma
  `kl_eq_d_succ : k / l * l = d + 1` (proved on line 45–46 of ReedSolomon.lean),
  so the two types are definitionally distinct but mathematically equivalent.
  The choice to use `Fin (d + 1)` is deliberate (noted in `Dal.Poly.interpolate`
  which uses `Fin (d+1)`), but the spec text uses a different expression.
- **Impact**: Low — the difference is cosmetic and mathematically trivial. However,
  an agent generating code from the spec signature would produce a type mismatch.
- **Action required**: Update `kb/spec.md` § S4 helper functions to use `Fin (d + 1)`
  as the domain (or add a note that `k / l * l = d + 1` and `Fin (d + 1)` is
  the Lean implementation choice), and do the same for `shardVals`.

---

## Info

### [I1] P1, P2 still `not started`; all other properties resolved or proved

- **KB location**: `kb/properties.md`
- **Lean location**: missing (`Dal/Protocol.lean` not yet written)
- **Status**: Expected at this stage. S4 is now proved (in `Dal.ReedSolomon`).
  P1 and P2 require `Dal/Protocol.lean`.

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
| `shardRemainder` function | spec.md § Sharding | missing | not started |
| `proveShardEval` function | spec.md § Sharding | missing | not started |
| `verifyShardEval` function | spec.md § Sharding | missing | not started |
| `rsDecode` function | spec.md § Reed-Solomon | missing | not started |
| P1: RS decoding succeeds | properties.md | missing | not started |
| P2: Page verification uniqueness | properties.md | missing | not started |
