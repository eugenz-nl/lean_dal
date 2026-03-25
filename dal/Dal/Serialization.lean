import Dal.Field
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.ZMod.Basic

/-!
# Dal.Serialization

Byte-to-scalar serialization and its injectivity (S1).

## Contents

- `Bytes`                    — `Fin slot_size → Fin 256` (a slot as a byte array)
- `slot_size_le`             — axiom: `slot_size ≤ k * 31`
- `bytes31_lt_r`             — axiom: `256^31 < r`
- `byteAt`                  — byte at position `m`, or 0 if `m ≥ slot_size` (padding)
- `byteChunk`               — 31-byte view of chunk `i` (partial last chunk is 0-padded)
- `bytesToFr`               — encode a 31-byte chunk as a field element
- `serialize`               — split slot bytes into `k` field elements
- `serialize_injective`     — **S1**: serialization is injective

## Design

`serialize` assigns each of the `k` chunks a 31-byte window of the slot, encoding it
as a field element via `Fintype.equivFin`.  When `slot_size < k * 31`, the final
chunk is shorter than 31 bytes and positions `≥ slot_size` within it are treated as 0.

The actual Tezos DAL deployment has `slot_size = 380832 = 31 × 12284 + 28`, so `k = 12285`
and the last chunk encodes only 28 real bytes.  The earlier `slot_size = k * 31`
restriction has been removed; we only require `slot_size ≤ k * 31`.

Injectivity: every byte position `m < slot_size` satisfies `m / 31 < k` (from
`slot_size ≤ k * 31`), so byte `b m` appears as position `m % 31` of chunk `m / 31`.
Equal serializations → equal chunk functions → equal `byteAt` values at all positions
`< slot_size` → equal byte sequences.

See `docs/protocol.md` §"Serialize a byte sequence to a scalar array".
-/

namespace Dal.Serialization

open Dal.Field

/-! ### Type -/

/-- A slot is a byte sequence of length `slot_size`. -/
abbrev Bytes := Fin slot_size → Fin 256

/-! ### Parameter constraints -/

/-- `slot_size ≤ k * 31`: the `k` chunks together cover all `slot_size` bytes, with
    at most 30 zero-padding bytes in the last chunk.  The actual Tezos DAL deployment
    has `slot_size = 380832 ≤ 12285 * 31 = 380835`. -/
axiom slot_size_le : slot_size ≤ k * 31

/-- `256^31 < r`: a 31-byte little-endian integer is always strictly less than `r`.
    Holds for BLS12-381 since `r ≈ 2^255 > 2^248 = 256^31`. -/
axiom bytes31_lt_r : 256^31 < r

/-! ### Byte access with padding -/

/-- Byte at position `m` in slot `b`; returns 0 for positions `≥ slot_size`.
    This zero-padding is used by the last chunk when `slot_size < k * 31`. -/
noncomputable def byteAt (b : Bytes) (m : ℕ) : Fin 256 :=
  if h : m < slot_size then b ⟨m, h⟩ else ⟨0, by norm_num⟩

/-- `byteAt` returns the actual byte at in-bounds positions. -/
@[simp] lemma byteAt_eq (b : Bytes) {m : ℕ} (h : m < slot_size) : byteAt b m = b ⟨m, h⟩ :=
  dif_pos h

/-! ### Chunk extraction -/

/-- The `j`-th byte of the `i`-th 31-byte chunk of slot `b`.
    For the last chunk when `slot_size < k * 31`, positions beyond `slot_size` return 0. -/
noncomputable def byteChunk (b : Bytes) (i : Fin k) (j : Fin 31) : Fin 256 :=
  byteAt b (31 * i.val + j.val)

/-! ### Chunk encoding -/

/-- Encode a 31-byte chunk as a field element via `Fintype.equivFin`.
    The encoded value is < `256^31 < r`, so the cast to `Fr` is injective. -/
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

/-- Serialize a slot: encode each 31-byte chunk as a field element.
    `serialize b i` is the `i`-th scalar in DATA. -/
noncomputable def serialize (b : Bytes) : Fin k → Fr :=
  fun i => bytesToFr (byteChunk b i)

/-! ### S1: Injectivity -/

/-- **S1**: Serialization is injective — equal scalar arrays imply equal byte sequences.

    **Proof**: For any byte index `m < slot_size`, we have `m / 31 < k` (since
    `m < slot_size ≤ k * 31`), so byte `b m` is the `(m % 31)`-th entry of chunk
    `m / 31`.  Equal serializations imply equal chunks (via `bytesToFr_injective`),
    which imply equal `byteAt` values, which imply equal bytes at all positions
    `< slot_size` (where padding is never in play). -/
theorem serialize_injective : Function.Injective serialize := by
  intro b₁ b₂ h
  have hchunk : ∀ i : Fin k, byteChunk b₁ i = byteChunk b₂ i :=
    fun i => bytesToFr_injective (congr_fun h i)
  ext ⟨m, hm⟩
  have hm_lt : m < k * 31 := Nat.lt_of_lt_of_le hm slot_size_le
  have hi  : m / 31 < k  := by omega
  have hj  : m % 31 < 31 := Nat.mod_lt _ (by norm_num)
  -- byteChunk b ⟨m/31, hi⟩ ⟨m%31, hj⟩ = byteAt b m = b ⟨m, hm⟩
  -- Use `show` to expose the concrete byteAt form (byteChunk is definitionally byteAt),
  -- then use Euclidean division (31*(m/31)+m%31 = m) and byteAt_eq.
  have reindex : ∀ b : Bytes, byteChunk b ⟨m / 31, hi⟩ ⟨m % 31, hj⟩ = b ⟨m, hm⟩ :=
    fun b => show byteAt b (31 * (m / 31) + m % 31) = b ⟨m, hm⟩ from
      (congr_arg (byteAt b) (show 31 * (m / 31) + m % 31 = m from by omega)).trans
        (byteAt_eq b hm)
  rw [← reindex b₁, ← reindex b₂]
  -- ext on (Fin slot_size → Fin 256) inserts Fin.val; bridge with congr_arg
  exact congr_arg Fin.val (congr_fun (hchunk ⟨m / 31, hi⟩) ⟨m % 31, hj⟩)

end Dal.Serialization
