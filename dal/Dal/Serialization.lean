import Dal.Field
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Fintype.EquivFin
import Mathlib.Data.ZMod.Basic

/-!
# Dal.Serialization

Byte-to-scalar serialization with page-interleaved layout, and its injectivity (S1).

## Contents

- `Bytes`                    — `Fin slot_size → Fin 256` (a slot as a byte array)
- `pages_per_slot`           — axiom: number of pages per slot
- `page_size`                — axiom: number of bytes per page
- `page_length`              — axiom: number of scalars per page
- `slot_size_le_pages`       — axiom: `slot_size ≤ pages_per_slot * page_size`
- `page_size_le_chunks`      — axiom: `page_size ≤ page_length * 31`
- `pages_per_slot_mul_page_length` — axiom: `pages_per_slot * page_length = k`
- `bytes31_lt_r`             — axiom: `256^31 < r`
- `slot_size_le`             — derived: `slot_size ≤ k * 31`
- `byteAt`                   — byte at position `m`, or 0 if `m ≥ slot_size` (padding)
- `byteChunk`                — 31-byte view of the chunk for scalar `i` (interleaved)
- `bytesToFr`                — encode a 31-byte chunk as a field element
- `serialize`                — split slot bytes into `k` field elements
- `serialize_injective`      — **S1**: serialization is injective

## Design

The real Tezos DAL uses a page-interleaved layout. A slot is divided into
`pages_per_slot` contiguous pages of `page_size` bytes each. Each page is split
into `page_length` chunks of up to 31 bytes (zero-padded at the end if needed).

The `k = pages_per_slot * page_length` scalars are stored in interleaved order:
scalar `i` encodes chunk `elt = i / pages_per_slot` of page `page = i % pages_per_slot`.
The byte address of the `j`-th byte of scalar `i` is:
  `page * page_size + elt * 31 + j`

This matches the OCaml implementation: `res[elt * pages_per_slot + page]` (see
`docs/protocol.md` §"Serialize a byte sequence to a scalar array").

The interleaving ensures that the `page_length` scalars for page `p`
(at positions `p, p+pages_per_slot, …, p+(page_length-1)*pages_per_slot`)
form a coset of the evaluation domain, enabling constant-time KZG multi-reveal
proofs for L1 page verification.

Injectivity (S1): for any byte `m < slot_size`, the page, element, and byte
position within the chunk are `page = m / page_size`, `elt = (m % page_size) / 31`,
`j = (m % page_size) % 31`, giving scalar index `elt * pages_per_slot + page`.
The composite map `m ↦ (elt * pages_per_slot + page, j)` is injective, so equal
serializations imply equal byte sequences.

See `docs/protocol.md` §"Serialize a byte sequence to a scalar array".
-/

namespace Dal.Serialization

open Dal.Field

/-! ### Type -/

/-- A slot is a byte sequence of length `slot_size`. -/
abbrev Bytes := Fin slot_size → Fin 256

/-! ### Page structure parameters -/

/-- Number of pages per slot. -/
axiom pages_per_slot : ℕ

/-- Number of bytes per page. -/
axiom page_size : ℕ

/-- Number of scalars per page (`= k / pages_per_slot`). -/
axiom page_length : ℕ

/-- `pages_per_slot` is positive. -/
axiom pages_per_slot_pos : 0 < pages_per_slot

/-- `page_size` is positive. -/
axiom page_size_pos : 0 < page_size

/-- `page_length` is positive. -/
axiom page_length_pos : 0 < page_length

/-- `pages_per_slot * page_length = k`: total scalars equal pages times scalars per page. -/
axiom pages_per_slot_mul_page_length : pages_per_slot * page_length = k

/-- `slot_size ≤ pages_per_slot * page_size`: all slot bytes fit in the page structure
    (the last page may be partially filled and zero-padded). -/
axiom slot_size_le_pages : slot_size ≤ pages_per_slot * page_size

/-- `page_size ≤ page_length * 31`: each page fits within `page_length` chunks of
    31 bytes (the last chunk may be partially filled and zero-padded). -/
axiom page_size_le_chunks : page_size ≤ page_length * 31

/-! ### Scalar field bound -/

/-- `256^31 < r`: a 31-byte little-endian integer is always strictly less than `r`.
    Holds for BLS12-381 since `r ≈ 2^255 > 2^248 = 256^31`. -/
axiom bytes31_lt_r : 256^31 < r

/-! ### Derived bound -/

/-- `slot_size ≤ k * 31`: follows from the page structure bounds. -/
lemma slot_size_le : slot_size ≤ k * 31 :=
  calc slot_size ≤ pages_per_slot * page_size      := slot_size_le_pages
    _ ≤ pages_per_slot * (page_length * 31)        := Nat.mul_le_mul_left _ page_size_le_chunks
    _ = (pages_per_slot * page_length) * 31        := by ring
    _ = k * 31                                     := by rw [pages_per_slot_mul_page_length]

/-! ### Byte access with padding -/

/-- Byte at position `m` in slot `b`; returns 0 for positions `≥ slot_size`.
    This zero-padding covers the partial last chunk of each page when
    `slot_size < pages_per_slot * page_size`. -/
noncomputable def byteAt (b : Bytes) (m : ℕ) : Fin 256 :=
  if h : m < slot_size then b ⟨m, h⟩ else ⟨0, by norm_num⟩

/-- `byteAt` returns the actual byte at in-bounds positions. -/
@[simp] lemma byteAt_eq (b : Bytes) {m : ℕ} (h : m < slot_size) : byteAt b m = b ⟨m, h⟩ :=
  dif_pos h

/-! ### Chunk extraction (interleaved layout) -/

/-- The `j`-th byte of the chunk for scalar `i` under the interleaved page layout.

    Scalar `i` belongs to page `page = i % pages_per_slot` at element position
    `elt = i / pages_per_slot` within that page.  Its `j`-th byte is at absolute
    address `page * page_size + elt * 31 + j`. -/
noncomputable def byteChunk (b : Bytes) (i : Fin k) (j : Fin 31) : Fin 256 :=
  byteAt b ((i.val % pages_per_slot) * page_size + (i.val / pages_per_slot) * 31 + j.val)

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

/-- Serialize a slot: encode each chunk as a field element.
    `serialize b i` is the `i`-th scalar in DATA under the interleaved layout. -/
noncomputable def serialize (b : Bytes) : Fin k → Fr :=
  fun i => bytesToFr (byteChunk b i)

/-! ### S1: Injectivity -/

/-- **S1**: Serialization is injective — equal scalar arrays imply equal byte sequences.

    **Proof**: For any byte `m < slot_size`, let `page = m / page_size`,
    `elt = (m % page_size) / 31`, `j = (m % page_size) % 31`.  The scalar at index
    `elt * pages_per_slot + page` encodes byte `m` at position `j`.  Equal
    serializations imply equal chunks (via `bytesToFr_injective`), which imply equal
    `byteAt` values at all positions `< slot_size`. -/
theorem serialize_injective : Function.Injective serialize := by
  intro b₁ b₂ h
  have hchunk : ∀ i : Fin k, byteChunk b₁ i = byteChunk b₂ i :=
    fun i => bytesToFr_injective (congr_fun h i)
  ext ⟨m, hm⟩
  -- Bound m within the page structure
  have hm_pg  : m < pages_per_slot * page_size := Nat.lt_of_lt_of_le hm slot_size_le_pages
  have hpage_lt : m / page_size < pages_per_slot :=
    Nat.div_lt_iff_lt_mul page_size_pos |>.mpr hm_pg
  have hmod_pg    : m % page_size < page_size    := Nat.mod_lt _ page_size_pos
  have hmod_chunk : m % page_size < page_length * 31 :=
    Nat.lt_of_lt_of_le hmod_pg page_size_le_chunks
  have helt_lt : (m % page_size) / 31 < page_length :=
    Nat.div_lt_iff_lt_mul (by norm_num) |>.mpr hmod_chunk
  -- Scalar index for byte m: elt * pages_per_slot + page
  -- (elt = (m % page_size) / 31, page = m / page_size)
  have hscalar_lt : (m % page_size) / 31 * pages_per_slot + m / page_size < k := by
    have hlt : (m % page_size) / 31 * pages_per_slot + m / page_size <
               page_length * pages_per_slot :=
      by nlinarith [helt_lt, hpage_lt, pages_per_slot_pos]
    linarith [show page_length * pages_per_slot = k from by
      rw [mul_comm]; exact pages_per_slot_mul_page_length]
  -- Recovering page index from scalar index
  have hpage_mod :
      ((m % page_size) / 31 * pages_per_slot + m / page_size) % pages_per_slot =
      m / page_size := by
    rw [show (m % page_size) / 31 * pages_per_slot + m / page_size =
            m / page_size + pages_per_slot * ((m % page_size) / 31) by ring]
    rw [Nat.add_mul_mod_self_left]
    exact Nat.mod_eq_of_lt hpage_lt
  -- Recovering element index from scalar index
  have helt_div :
      ((m % page_size) / 31 * pages_per_slot + m / page_size) / pages_per_slot =
      (m % page_size) / 31 := by
    rw [show (m % page_size) / 31 * pages_per_slot + m / page_size =
            m / page_size + pages_per_slot * ((m % page_size) / 31) by ring]
    rw [Nat.add_mul_div_left _ _ pages_per_slot_pos]
    simp [Nat.div_eq_of_lt hpage_lt]
  -- Byte address reconstructs m
  have haddr :
      m / page_size * page_size + (m % page_size) / 31 * 31 + (m % page_size) % 31 = m := by
    have h1 := Nat.div_add_mod m page_size
    have h2 := Nat.div_add_mod (m % page_size) 31
    linarith [mul_comm page_size (m / page_size), mul_comm 31 ((m % page_size) / 31)]
  -- The reindex lemma: chunk at scalar (elt*pages+page) at position j equals byte m
  have reindex : ∀ b : Bytes,
      byteChunk b ⟨(m % page_size) / 31 * pages_per_slot + m / page_size, hscalar_lt⟩
                  ⟨(m % page_size) % 31, Nat.mod_lt _ (by norm_num)⟩ =
      b ⟨m, hm⟩ := by
    intro b
    simp only [byteChunk, hpage_mod, helt_div]
    rw [haddr]
    exact byteAt_eq b hm
  rw [← reindex b₁, ← reindex b₂]
  exact congr_arg Fin.val
    (congr_fun
      (hchunk ⟨(m % page_size) / 31 * pages_per_slot + m / page_size, hscalar_lt⟩)
      ⟨(m % page_size) % 31, Nat.mod_lt _ (by norm_num)⟩)

end Dal.Serialization
