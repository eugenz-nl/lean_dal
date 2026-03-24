---
title: Glossary
last-updated: 2026-03-23
status: draft
---

# Glossary

Precise definitions of every term used in this KB and in the Lean formalization.
When in doubt, use the definition here — not an informal intuition.

See also: [spec.md](spec.md) for how these concepts relate; [architecture.md](architecture.md) for Lean locations.

---

## Notation

This section fixes the symbols used throughout the KB and the Lean formalization.
Symbols fall into four categories: **deployment parameters**, **derived quantities**,
**cryptographic constants**, and **mathematical notation**.

### Deployment parameters

These are fixed for a given DAL deployment. They appear as Lean `variable` or
`constant` declarations, not as universally-quantified variables in theorem
statements. The full table with constraints is in [spec.md § Parameters](spec.md).

| Symbol | Type | Meaning |
|--------|------|---------|
| `r` | prime | Order of the scalar field `𝔽_r` (BLS12-381, `r ≈ 2^255`) |
| `slot_size` | `ℕ` | Byte size of a slot |
| `k` | `ℕ` | Dimension of the RS code; number of scalars encoding a slot (`k ≈ slot_size / 31`) |
| `n` | `ℕ` | Length of the RS codeword (`n = α · k`, `n ∣ r − 1`) |
| `α` | `ℕ` | Redundancy factor (`α = n / k ≥ 2`) |
| `s` | `ℕ` | Number of shards (`s ∣ n`) |

### Derived quantities

These are uniquely determined by the deployment parameters above. They are **not**
independent parameters.

| Symbol | Definition | Meaning |
|--------|-----------|---------|
| `d` | `d = k − 1` | Degree bound of the committed polynomial. A polynomial encoding a valid slot has degree **exactly** `d`; the degree bound `≤ d` is used in theorem statements. `d` is not a free variable. |
| `l` | `l = n / s` | Shard length: number of evaluations per shard (requires `s ∣ n`) |

> **On `d`**: `d` is a derived constant (`d = k − 1`), not a universally-quantified
> variable. When theorem statements write `deg p ≤ d`, `d` refers to this fixed value.
> It is explicit in the axiom statements for readability, but it is not an extra degree
> of freedom.

### Cryptographic constants

These are part of the trusted setup and the elliptic curve. They are fixed but
secret (in the case of `τ`) or public-but-opaque (in the case of generators).

| Symbol | Type | Meaning |
|--------|------|---------|
| `τ` | `𝔽_r` | Trusted setup secret. **Never appears in Lean proofs** — only the SRS values `[τ^i]_1` and `[τ]_2` are available. Destroyed after setup. |
| `ω` | `𝔽_r` | Primitive `n`-th root of unity. Exists because `n ∣ r − 1`. Fixed but public. The evaluation domain is `{ω^i : i = 0, …, n−1}`. |
| `g_1` | `𝔾_1` | Generator of the first elliptic curve group. |
| `g_2` | `𝔾_2` | Generator of the second elliptic curve group. |
| `g_T` | `𝔾_T` | Generator of the target group; `e(g_1, g_2) = g_T`. |

### Mathematical notation

| Notation | Meaning |
|----------|---------|
| `[a]_1` | Scalar multiplication `a · g_1 ∈ 𝔾_1` |
| `[a]_2` | Scalar multiplication `a · g_2 ∈ 𝔾_2` |
| `𝔽_r` | Prime field of order `r` (scalar field of BLS12-381); modelled as `ZMod r` in Lean |
| `𝔾_1`, `𝔾_2`, `𝔾_T` | Elliptic curve groups of prime order `r`; opaque types in Lean |
| `e` | Pairing `𝔾_1 × 𝔾_2 → 𝔾_T` |
| `𝔽_r[x]` | Ring of polynomials over `𝔽_r`; `Polynomial (ZMod r)` in Lean |
| `Ω_i` | `i`-th coset: `{ω^{i + s·j} : j = 0, …, l−1}` |
| `Z_i` | Vanishing polynomial for `Ω_i`: `Z_i(x) = x^l − ω^{i·l}` |
| `CK` | Committing key: `([τ^i]_1)_{i=0}^{n-1}` |
| `VK` | Verifying key: `[τ]_2` |

---

## Protocol-level terms

**Slot**
A raw byte sequence of fixed size `slot_size` (in bytes). The unit of data stored
by the DAL. A slot is encoded, committed, sharded, and distributed to DAL nodes.

**Scalar / Field element**
An element of the prime field `𝔽_r`, the scalar field of the BLS12-381 elliptic
curve. `r` is a ~255-bit prime. In Lean: a type `Scalar` with field operations.

**DATA**
A vector of `k` scalars obtained by serializing a slot (31 bytes per scalar,
since `r < 2^255`). The semantic content of a slot in field-element form.

**POLY** (polynomial)
The unique polynomial `p ∈ 𝔽_r[x]` of degree `< k` whose coefficient vector equals
DATA (i.e., `p(x) = Σ data_i · x^i`). Also the result of interpolating `d+1`
evaluations. In Lean: `Polynomial 𝔽_r` or a type alias `Poly`.

**Commitment (C)**
An element of `𝔾_1` (the first elliptic curve group of BLS12-381). The KZG
commitment to a polynomial `p` is `commit(p) = [p(τ)]_1 = Σ p_i · [τ^i]_1`.
Constant-size (one group element). In Lean: a type alias `Commitment := G1`.

**Proof (Π)**
A KZG proof: an element of `𝔾_1`. Used both as an evaluation proof (`proveEval`)
and a degree proof (`proveDegree`).

**Evaluation point (X)**
A scalar `x ∈ 𝔽_r` at which a polynomial is evaluated.

**Evaluation (Y)**
The value `y = p(x) ∈ 𝔽_r`. In the RS context, evaluations are grouped into
vectors of length `d+1` (pages) or `l` (shards).

**Reed-Solomon (RS) code**
An MDS linear code. RS(n, k, ω) is the set of vectors `(p(ω^i))_{i=0}^{n-1}` for
polynomials `p` of degree `< k`. The DAL uses RS to encode a slot into `n`
evaluation points, providing redundancy factor `α = n/k`. See [spec.md](spec.md).

**Shard**
A contiguous block of `l = n/s` evaluations of the encoded polynomial, at the
coset `Ω_i = ω^i · Ω_0` of the evaluation domain. There are `s = n/l` shards per
slot. Each shard is paired with a KZG multi-reveal proof. In Lean: a type `Shard`.

**Shard index**
An integer `i ∈ [0, s)` identifying which coset `Ω_i` a shard belongs to.

**Page**
A sub-segment of the slot for L1 verification: `page_length` consecutive scalars
(and their KZG evaluation proof). Not the primary focus of the formalization (which
focuses on shard-level properties).

**Coset**
`Ω_i = ω^i · Ω_0` where `Ω_0 = {ω^{sj} : j = 0, …, l-1}` is the subgroup of
`n`-th roots of unity generated by `ω^s`. The evaluation domain is the disjoint
union of the `s` cosets.

**Vanishing polynomial**
`Z_i(x) = x^l - ω^{il}`. Its roots are exactly `Ω_i`. Used in multi-reveal proofs.

**Trusted Setup / SRS**
The committing key `CK = ([τ^i]_1)_{i=0}^{n-1}` and verifying key `VK = [τ]_2`,
for a secret scalar `τ`. The security of KZG relies on the assumption that `τ` is
unknown (destroyed after setup). `τ` must never appear in Lean proofs — only its
commitments are available.

**KZG commitment scheme**
The polynomial commitment scheme (Kate–Zaverucha–Goldberg). Provides `commit`,
`proveEval`, `verifyEval`, `proveDegree`, `verifyDegree`. See [spec.md](spec.md).

**Pairing**
A bilinear map `e : 𝔾_1 × 𝔾_2 → 𝔾_T` satisfying `e(g_1, g_2) = g_T` and
non-degeneracy. Used in KZG verification equations.

**MDS code**
Maximum Distance Separable: a linear code achieving the Singleton bound. Reed-Solomon
codes are MDS. The MDS property guarantees that any `k` out of `n` evaluation points
uniquely determine the polynomial.

**Redundancy factor (α)**
`α = n/k`. The ratio of codeword length to message length. Also written as
`MDS.redundancy_factor`. Determines how many shards must be lost before recovery
is impossible: recovery requires any `n/α = k` evaluations across `k/l` cosets.

---

## Lean / Mathlib terms

**`Polynomial R`**
Mathlib type for polynomials over a ring `R`. Used as the type for POLY.

**`ZMod p`**
Mathlib type for integers modulo `p`. The scalar field `𝔽_r` is `ZMod r` (for
prime `r`).

**`sorry`**
A Lean tactic that closes any goal without proof. Marks an open obligation.
Every `sorry` in this project must have a `-- TODO: <reason>` comment and a
corresponding entry in [gaps.md](gaps.md).

**`#check`**
A Lean command to verify that an expression type-checks. Not a proof.

**`lake build`**
The build command for the `dal` Lean project. Must succeed with zero errors and
zero `sorry` occurrences for any completed task.
