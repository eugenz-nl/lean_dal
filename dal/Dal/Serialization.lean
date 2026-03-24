import Dal.Field
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.ZMod.Basic

/-!
# Dal.Serialization

Byte-to-scalar serialization and its injectivity (S1).

## Contents

- `Bytes`                    — `Fin slot_size → Fin 256` (a slot as a byte array)
- `slot_size_eq`             — axiom: `slot_size = k * 31`
- `bytes31_lt_r`             — axiom: `256^31 < r`
- `byteChunk`               — extract the `j`-th byte of the `i`-th 31-byte chunk
- `bytesToFr`               — encode a 31-byte chunk as a field element
- `serialize`               — split slot bytes into `k` field elements
- `serialize_injective`     — **S1**: serialization is injective

## Design

`serialize` splits the `slot_size = k * 31` bytes into `k` consecutive 31-byte
chunks and encodes each chunk as a field element via `Fintype.equivFin`.  The
encoding is injective because (a) `Fintype.equivFin` is a bijection (hence
injective) and (b) the encoded values are all less than `256^31 < r`, so the
cast to `ZMod r` does not wrap around.

The permutation used in the OCaml reference implementation (`res.((elt * pages_per_slot) + page)`)
is a bijection on indices and does not affect injectivity. This module formalizes
the mathematical essence: bytes → chunks → field elements is injective.

See `kb/architecture.md` §`Dal/Serialization.lean` and `docs/protocol.md`
§"Serialize a byte sequence to a scalar array".
-/

namespace Dal.Serialization

open Dal.Field

/-! ### Type -/

/-- A slot is a byte sequence of length `slot_size`. -/
abbrev Bytes := Fin slot_size → Fin 256

/-! ### New parameter constraints -/

/-- `slot_size = k * 31`: each of the `k` scalars encodes exactly 31 bytes.
    Consistent with `k ≈ slot_size / 31` from `kb/spec.md` Parameters. -/
axiom slot_size_eq : slot_size = k * 31

/-- `256^31 < r`: a 31-byte little-endian integer is always strictly less than `r`.
    Holds for BLS12-381 since `r ≈ 2^255 > 2^248 = 256^31`. -/
axiom bytes31_lt_r : 256^31 < r

/-! ### Chunk extraction -/

/-- Extract the `j`-th byte of the `i`-th 31-byte chunk from byte array `b`.
    The `i`-th chunk occupies positions `31*i … 31*i+30`. -/
def byteChunk (b : Bytes) (i : Fin k) (j : Fin 31) : Fin 256 :=
  b ⟨31 * i.val + j.val,
    by have := i.isLt; have := j.isLt; rw [slot_size_eq]; omega⟩

/-! ### Chunk encoding -/

/-- Encode a 31-byte chunk as a field element.  Uses `Fintype.equivFin` to map
    `(Fin 31 → Fin 256)` bijectively into `Fin (256^31)`, then casts the index
    to `Fr`.  The cast is injective because the index is < `256^31 < r`. -/
noncomputable def bytesToFr (chunk : Fin 31 → Fin 256) : Fr :=
  ((Fintype.equivFin (Fin 31 → Fin 256) chunk).val : Fr)

/-! ### Supporting lemmas -/

private lemma card_byte_chunk : Fintype.card (Fin 31 → Fin 256) = 256^31 := by
  simp [Fintype.card_pi, Fintype.card_fin, Finset.prod_const, Finset.card_univ]

private lemma chunk_val_lt (chunk : Fin 31 → Fin 256) :
    (Fintype.equivFin (Fin 31 → Fin 256) chunk).val < r :=
  calc (Fintype.equivFin _ chunk).val
      < Fintype.card (Fin 31 → Fin 256) := (Fintype.equivFin _ chunk).isLt
    _ = 256^31                           := card_byte_chunk
    _ < r                                := bytes31_lt_r

/-- `Nat.cast : ℕ → Fr` is injective on `{n | n < r}`. -/
private lemma natCast_inj {m n : ℕ} (hm : m < r) (hn : n < r)
    (h : (m : Fr) = (n : Fr)) : m = n := by
  have hval := congr_arg ZMod.val h
  rwa [ZMod.val_cast_of_lt hm, ZMod.val_cast_of_lt hn] at hval

/-- `bytesToFr` is injective. -/
lemma bytesToFr_injective : Function.Injective bytesToFr := by
  intro a b h
  apply (Fintype.equivFin _).injective
  apply Fin.ext
  exact natCast_inj (chunk_val_lt a) (chunk_val_lt b) h

/-! ### Serialization -/

/-- Serialize a slot: split into `k` consecutive 31-byte chunks and encode each
    as a field element.  `serialize b i` is the `i`-th scalar in DATA. -/
noncomputable def serialize (b : Bytes) : Fin k → Fr :=
  fun i => bytesToFr (byteChunk b i)

/-! ### S1: Injectivity -/

/-- **S1**: Serialization is injective — equal scalar arrays imply equal byte sequences.

    **Proof sketch**: Injectivity flows through two steps:
    - `byteChunk` extracts bytes by index, so `serialize b₁ = serialize b₂` implies
      `byteChunk b₁ i = byteChunk b₂ i` for every chunk `i` (via `bytesToFr_injective`).
    - Every byte `b₁ m` equals `b₂ m` because `m` lies in some chunk `m / 31` at
      position `m % 31`, and `31 * (m/31) + m%31 = m` (Euclidean division). -/
theorem serialize_injective : Function.Injective serialize := by
  intro b₁ b₂ h
  have hchunk : ∀ i : Fin k, byteChunk b₁ i = byteChunk b₂ i :=
    fun i => bytesToFr_injective (congr_fun h i)
  ext ⟨m, hm⟩
  have hm' : m < k * 31 := slot_size_eq ▸ hm
  have hi  : m / 31 < k := by omega
  have hj  : m % 31 < 31 := Nat.mod_lt _ (by norm_num)
  -- byteChunk b ⟨m/31, hi⟩ ⟨m%31, hj⟩  definitionally equals  b ⟨31*(m/31)+m%31, _⟩
  -- and  31*(m/31)+m%31 = m  (Euclidean division), so it equals  b ⟨m, hm⟩.
  -- byteChunk b ⟨m/31, hi⟩ ⟨m%31, hj⟩  definitionally equals  b ⟨31*(m/31)+m%31, _⟩.
  -- Use `show` to make the concrete form explicit, then congr_arg + Fin.ext + omega.
  have reindex : ∀ b : Bytes,
      byteChunk b ⟨m / 31, hi⟩ ⟨m % 31, hj⟩ = b ⟨m, hm⟩ :=
    fun b => show b ⟨31 * (m / 31) + m % 31, by rw [slot_size_eq]; omega⟩ = b ⟨m, hm⟩
               from congr_arg b (Fin.ext (show 31 * (m / 31) + m % 31 = m from by omega))
  rw [← reindex b₁, ← reindex b₂]
  -- ext on (Fin slot_size → Fin 256) inserts Fin.val; bridge with congr_arg
  exact congr_arg Fin.val (congr_fun (hchunk ⟨m / 31, hi⟩) ⟨m % 31, hj⟩)

end Dal.Serialization
