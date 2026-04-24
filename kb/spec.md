---
title: Protocol Specification
last-updated: 2026-04-24
status: draft
---

# DAL Protocol Specification

Source: `docs/protocol.md`. This file distills the protocol's mathematical content
into the form needed to drive the Lean formalization.

See also: [glossary.md](glossary.md) for term definitions; [properties.md](properties.md)
for the invariants to prove; [architecture.md](architecture.md) for Lean locations.

---

## Purpose

The Tezos Data Availability Layer (DAL) decouples data availability from the L1
blockchain. Block producers publish large data blobs (slots) to the DAL instead of
on-chain. The DAL:

1. **Encodes** each slot with Reed-Solomon erasure coding.
2. **Commits** to it with a KZG polynomial commitment (stored on L1).
3. **Shards** the encoded slot and distributes shards to DAL nodes.
4. **Attests** availability: if enough nodes hold valid shards, the slot is declared available.
5. **Reconstructs**: any `k/l` valid shards suffice to recover the original slot.

The formalization targets the cryptographic core: the correctness of the encode/
commit/shard/verify pipeline.

---

## Parameters

| Name | Type | Meaning |
|------|------|---------|
| `r` | prime | Order of the scalar field `𝔽_r` (BLS12-381, `r ≈ 2^255`) |
| `slot_size` | `ℕ` | Byte length of a slot |
| `k` | `ℕ` | Number of scalars encoding a slot (`k ≈ slot_size / 31`) |
| `n` | `ℕ` | RS codeword length (`n = α * k`, `n | r - 1`) |
| `α` | `ℕ` | Redundancy factor (`α ≥ 2`) |
| `d` | `ℕ` | Degree bound of the committed polynomial (`d = k - 1`) |
| `s` | `ℕ` | Number of shards (`s | n`) |
| `l` | `ℕ` | Shard length in evaluations (`l = n / s`) |
| `ω` | `𝔽_r` | Primitive `n`-th root of unity (exists since `n | r - 1`) |

Constraints:
- `d ≥ 2l` (required by the multi-reveal proof construction; see
  `docs/protocol.md` §Multiple multi-reveals)
- `l ∣ k` (so that `k / l` shards suffice for reconstruction; needed for S4)
- `slot_size ≤ k * 31` (serialization constraint: `k` chunks cover all bytes, with at most
  30 zero-padding bytes in the last chunk; the actual Tezos DAL deployment has
  `slot_size = 380832 = 31 × 12284 + 28`, so `k = 12285` with a 28-byte last chunk)
- `256^31 < r` (BLS12-381 guarantee: a 31-byte chunk fits in one field element without
  wrap-around; `r ≈ 2^255 > 256^31 = 2^248`)

**Page parameters** (used for L1 verification; out of scope for the initial
formalization but included for completeness):

| Name | Type | Meaning |
|------|------|---------|
| `page_length` | `ℕ` | Number of scalars per page |
| `pages_per_slot` | `ℕ` | `pages_per_slot = k / page_length` (requires `page_length ∣ k`) |

---

## Data flow

```
RAW BYTES (slot_size bytes)
  │
  │  serialize: 31 bytes → 1 scalar; pad to k scalars
  ▼
DATA  ∈  𝔽_r^k
  │
  │  interpolate on domain {1, ω^s, ω^{2s}, …, ω^{(k-1)s}} of size k
  ▼
POLY  p ∈ 𝔽_r[x],  deg p < k
  │              │
  │  commit      │  evaluate at Ω = {ω^i : i = 0, …, n-1}
  ▼              ▼
  C ∈ 𝔾_1     CODEWORD  ∈  𝔽_r^n
                 │
                 │  split into s cosets  Ω_i = ω^i · Ω_0,  |Ω_i| = l
                 ▼
               SHARDS  (shard_i, proof_i)_{i=0}^{s-1}
```

---

## Types

| Name | Lean target | Notes |
|------|-------------|-------|
| `N` | `ℕ` | Natural numbers |
| `X` | `𝔽_r` | Scalar field element; evaluation point |
| `Y` | `𝔽_r` | Evaluation value (same type as `X`) |
| `P` | `Polynomial 𝔽_r` | Polynomial over the scalar field |
| `C` | `G1` | KZG commitment (element of `𝔾_1`) |
| `Π` | `G1` | KZG proof (element of `𝔾_1`) |
| `B` | `Bool` | Verification result |
| `⊥` | `Option` / `Except` | Failure / invalid input |

---

## Functions

### Polynomial operations

- **`deg : P → N`** — degree of a polynomial
- **`eval : P → X → Y`** — evaluate polynomial at a point: `eval p x = p(x)`
- **`interpolate : (Fin (d+1) → X) → (Fin (d+1) → Y) → P`** — Lagrange
  interpolation: given `d+1` distinct points and values, returns the unique
  polynomial of degree `≤ d` passing through them

### Reed-Solomon

- **`rsEncode : P → (Fin n → Y)`** — evaluate `p` at all `n` roots of unity
  `{ω^i : i = 0, …, n-1}`: `rsEncode p i = eval p (ω^i)`
- **`rsDecode : (Fin (d+1) → X) → (Fin (d+1) → Y) → P`** — alias for
  `interpolate`; recovers `p` from any `d+1` evaluation point/value pairs

### KZG commitment scheme

- **`commit : P → C`** — `commit p = [p(τ)]_1 = Σ_i p_i · [τ^i]_1`
- **`proveEval : P → X → Y → Π ⊕ ⊥`** — produces proof `π = [(p(x)-p(z))/(x-z)](τ)]_1`
  when `eval p z = y`; returns `⊥` otherwise
- **`verifyEval : X → Y → C → Π → B`** — checks `e(c - [y]_1, g_2) = e(π, [τ]_2 - [z]_2)`
- **`proveDegree : P → N → Π ⊕ ⊥`** — produces proof that `deg p ≤ d`
- **`verifyDegree : C → N → Π → B`** — checks `e(c, [τ^{n-d}]_2) = e(c_d, g_2)`

### Sharding

- **`cosetPoint : Fin s → Fin l → X`** — the `j`-th point of coset `i`:
  `cosetPoint i j = ω^(i + s*j)` (i.e., `ω^i · (ω^s)^j`)
- **`shardEval : P → Fin s → (Fin l → Y)`** — evaluations of `p` at coset `Ω_i`:
  `shardEval p i j = eval p (cosetPoint i j)`
- **`shardRemainder : P → Fin s → P`** — the remainder `r_i` of degree `< l` such
  that `p = Z_i · q_i + r_i` (euclidean division by `Z_i`). Equivalently, `r_i` is
  the unique polynomial of degree `< l` agreeing with `p` on `Ω_i`.
  **Lean status**: declared as `axiom` in `Dal/KZG.lean` (gap G8 resolved).
- **`proveShardEval : P → Fin s → Π`** — multi-reveal proof for coset `Ω_i`:
  `π_i = [q_i(τ)]_1` where `q_i = (p - shardRemainder p i) / Z_i`.
  **Lean status**: declared as `axiom` in `Dal/KZG.lean` (gap G8 resolved).
- **`verifyShardEval : C → Fin s → (Fin l → Y) → Π → B`** — checks
  `e(c - [r_i(τ)]_1, g_2) = e(π_i, [τ^l]_2 - [ω^{il}]_2)`
  where `r_i` is reconstructed from the given evaluations by inverse DFT on `Ω_i`.
  **Lean status**: declared as `axiom` in `Dal/KZG.lean` (gap G8 resolved).

**Shard soundness axiom**:
- **(A7 — Shard eval soundness)**: `verifyShardEval c i vs π = true → ∃ p, commit p = c ∧ proveShardEval p i = π ∧ ∀ j, shardEval p i j = vs j`
  This is the multi-reveal analogue of A1. Like A1/A3/A6, it rests on the `d`-SDH
  assumption and is declared as an `axiom`. The degree bound is **not** included:
  the multi-reveal verification equation does not enforce a degree bound; P3 instead
  requires an explicit `verifyDegree` hypothesis. Approved 2026-03-25. See gap G9.

### S4 helper functions

These helpers appear in the statement of S4 (shard recovery) in `kb/properties.md`.
They are defined in `Dal/ReedSolomon.lean`.

- **`cosetPoints : Finset (Fin s) → Fin (d+1) → X`** — given an index set
  `I` with `|I| = k / l`, enumerates (in a fixed order) all `cosetPoint i j` for
  `i ∈ I`, `j : Fin l`. The domain is `Fin (d+1)` rather than `Fin (k/l*l)` since
  `d+1 = k = (k/l)*l` (from `l ∣ k` and `d = k-1`), and `Fin (d+1)` matches the
  argument type of `Dal.Poly.interpolate` directly.
- **`shardVals : Finset (Fin s) → (Fin s → Fin l → Y) → Fin (d+1) → Y`** —
  collects the corresponding evaluation values in the same order as `cosetPoints`.
  Point `m` maps to coset `I[⌊m/l⌋]` at position `m % l`, using `Finset.orderIsoOfFin`
  to sort `I`.

The exact enumeration order is a Lean implementation choice; any fixed total order
on `(i, j)` pairs satisfying `i ∈ I`, `j : Fin l` is acceptable, provided
`cosetPoints` and `shardVals` use the same order.

---

## Specifications

These are numbered S1–S6 here (following `docs/protocol.md`); in `properties.md`
they are labelled A1–A6. They are grouped by their Lean status.

**Soundness axioms** (A1, A2, A3, A6, A7) — KZG security rests on computational
hardness; these cannot be proved in pure Lean. See
[decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

1. **(A1 — Eval soundness)** `verifyEval x y c π = true → ∃ p, commit p = c ∧ π = proveEval p x y`
2. **(A2 — Eval completeness)** `proveEval p x y = some π ↔ eval p x = y`
   *(Note: `docs/protocol.md` Spec 2 writes the arguments as `proveEval(x,y,p)`,
   reversing the polynomial to last position. This KB standardizes to polynomial-first
   `(p, x, y)` to match the function signature above.)*
3. **(A3 — Degree soundness)** `verifyDegree c d π = true → ∃ p, commit p = c ∧ deg p ≤ d ∧ π = proveDegree p d`
6. **(A6 — Commitment binding)** `commit p = commit p̃ → p = p̃`
   ⚠ Technically false in pure math; true under the `d`-SDH assumption.
7. **(A7 — Shard eval soundness)** See shard soundness axiom above.

**Completeness axioms** (A1c, A3c, A7c) — algebraic correctness of honest provers;
axiomatized because KZG functions are opaque (gap G12 resolved).

- **(A1c — Eval completeness, verifier)** `proveEval p x (eval p x) = some π → verifyEval x (eval p x) (commit p) π = true`
- **(A3c — Degree completeness)** `p.natDegree ≤ d → ∃ π, proveDegree p d = some π ∧ verifyDegree (commit p) d π = true`
- **(A7c — Shard eval completeness)** `verifyShardEval (commit p) i (fun j => shardEval p i j) (proveShardEval p i) = true`

**Provable lemmas** (A4, A5) — follow from polynomial arithmetic; provable from
Mathlib, not axiomatized. See [decisions/001-kzg-axioms.md](decisions/001-kzg-axioms.md).

4. **(A4 — Interpolation correctness)** `interpolate xs ys = p → deg p ≤ d ∧ ∀ i, eval p (xs i) = ys i`
5. **(A5 — Polynomial uniqueness)** `deg p ≤ d → deg p̃ ≤ d → (∀ i, eval p (xs i) = eval p̃ (xs i)) → p = p̃`

---

## Properties (theorems to prove)

These are the top-level correctness statements derived from the axioms above. They
are **theorems**, not axioms — proofs exist and are given in `docs/protocol.md`.
See [properties.md](properties.md) for the complete list and proof status.

### Property 1: RS decoding succeeds

Given a commitment `c`, `d+1` distinct evaluation points `x_0, …, x_d`, their
alleged evaluations `y_0, …, y_d`, corresponding evaluation proofs `π_0, …, π_d`,
and a degree proof `π`:

```
(∀ i ∈ [0,d], verifyEval(x_i, y_i, c, π_i) = 1)
∧ verifyDegree(c, d, π) = 1
⟹
∃! p,  commit(p) = c
     ∧ (∀ i, π_i = proveEval(p, x_i, y_i))
     ∧ interpolate((x_0,…,x_d), (y_0,…,y_d)) = p
```

### Property 2: Page verification uniqueness

Given a commitment `c`, `d+1` evaluation points and proofs:

```
(∀ i ∈ [0,d], verifyEval(x_i, y_i, c, π_i) = 1)
⟹
∃! p,  commit(p) = c
     ∧ (∀ i, π_i = proveEval(p, x_i, y_i))
```

**Proof sketch (from `docs/protocol.md`):**
Apply Spec 1 for each `i` (eval soundness). Apply Spec 6 (binding) for uniqueness.
Prop 1 additionally uses Spec 3 (degree soundness), Spec 4 (interpolation), and
Spec 2 + 5 to conclude `interpolate(...) = p`.

### Property 3: Shard verification implies recovery

Given a commitment `c`, a degree proof `π_deg`, an index set `I` with `|I| = k/l`,
shard evaluation values `vs : Fin s → Fin l → Y`, and shard proofs `πs : Fin s → Π`:

```
verifyDegree(c, d, π_deg) = 1
∧ (∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = 1)
⟹
∃! p,  commit(p) = c
     ∧ (∀ i ∈ I, proveShardEval p i = πs i)
     ∧ (∀ i ∈ I, ∀ j, shardEval p i j = vs i j)
     ∧ interpolate(cosetPoints I, shardVals I vs) = p
```

**Proof sketch**: Apply A7 for each `i ∈ I` to obtain candidates. Apply A3 with
`π_deg` to obtain the degree bound `p.natDegree ≤ d`. Apply A6 to collapse to a
unique `p`. Apply S4 to conclude `interpolate(cosetPoints I, shardVals I vs) = p`.
Lean status: `proved` (gap G10 resolved).

### Property 4: End-to-end round-trip (G13)

Given `b : Bytes`, distinct nodes `xs : Fin (d+1) → Fr`, commitment `c` to the
interpolant of `serialize b` at `xs`, a degree proof `π_deg`, index set `I` with
`|I| = k/l`, shard values and proofs:

```
commit(interpolate(xs, serialize b ∘ Fin.cast d_succ_eq_k)) = c
∧ verifyDegree(c, d, π_deg) = 1
∧ (∀ i ∈ I, verifyShardEval c i (vs i) (πs i) = 1)
⟹
deserialize(fun i => eval(xs(Fin.cast d_succ_eq_k.symm i),
                          interpolate(cosetPoints I, shardVals I vs))) = b
```

**Proof sketch**: P3 gives the unique recovered `p`. A6 identifies `p` with the
interpolant of `serialize b`. A4 recovers the evaluations. Cast cancellation gives
`serialize b`, and `deserialize_left_inverse` closes.
Lean status: `proved` (gap G13 resolved).

### Security theorems (DAL-level corollaries)

On top of the functional-correctness theorems above, the formalization tracks a
set of **DAL-level security theorems** (Sec1–Sec7) that restate the cryptographic
guarantees in attacker-relevant form at the `Bytes` / slot level. They introduce
no new axioms and follow as corollaries of the KZG axioms (A1, A3, A6, A7), the
structural lemmas (S1, S4), and the main theorems (P1, P2, P3, G13).

| ID | Name | Informal statement |
|----|------|--------------------|
| Sec1 | Slot binding | Equal slot-level commitments imply equal slots |
| Sec2 | Decoder determinism | Different verifying shard subsets recover the same interpolant |
| Sec3 | Shard unforgeability | Verifying shard values/proofs for a known slot are the true ones |
| Sec4 | Threshold robustness | k/l honest shards suffice for reconstruction (DA liveness) |
| Sec5 | Page-eval soundness | Verifying evaluation proofs force `ys` to be the true byte values |
| Sec6 | No fake commitments | `verifyDegree` acceptance implies the commitment is real |
| Sec7 | Proof non-malleability | Evaluation / degree / shard proofs are unique given `(c, query)` |

Full statements, Lean targets, proof sketches, and threat-model notes are in
[properties.md § Security theorems](properties.md#security-theorems-dal-level-corollaries).
Open obligation tracked as [gaps.md § G14](gaps.md#g14-security-theorems-sec1sec7).
