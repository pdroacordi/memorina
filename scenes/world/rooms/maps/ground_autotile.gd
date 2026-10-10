class_name GroundAutotile
extends RefCounted
## Where a look sheet keeps each dual-grid tile, and which tile a display cell takes (architecture/biome-tilesets, "Sheet contract").

## Bits of a display tile's solid-corner mask; each corner is one map cell.
const NW := 1
const NE := 2
const SW := 4
const SE := 8
const FULL := 15
## Rows per season band; band 0 is spring.
const BAND_ROWS := 10
const VARIANT_ROW := 4
const LEDGE_ROW := 5
## The first of the edge-variant rows: one row per EDGE_MASKS entry, variant v in column v - 1.
const EDGE_ROW := 6
## The straight edges (top, underside, west face, east face) that take variants like the fill.
const EDGE_MASKS: Array[int] = [SW | SE, NW | NE, NE | SE, NW | SW]
const MAX_VARIANTS := 4
## Ledge pieces, in LEDGE_ROW order.
const LEDGE_LEFT := 0
const LEDGE_MIDDLE := 1
const LEDGE_RIGHT := 2
const LEDGE_SINGLE := 3

const _BITS: Array[int] = [NW, NE, SW, SE]
## The corners sharing a tile edge with each corner, in NW, NE, SW, SE order.
const _EDGE_NEIGHBOURS: Array[Array] = [[1, 2], [0, 3], [0, 3], [1, 2]]
## The corner directly above each corner in the tile, -1 for a top corner.
const _ABOVE: Array[int] = [-1, -1, 0, 1]


## The band-0 slot of the tile for solid-corner `mask` (1..15).
static func wang_coords(mask: int) -> Vector2i:
	return Vector2i(mask % 4, mask / 4)

## The band-0 slot of fill variant `variant` (1..MAX_VARIANTS).
static func variant_coords(variant: int) -> Vector2i:
	return Vector2i(variant - 1, VARIANT_ROW)

## True for the full tile and the straight edges, the tiles a sheet draws variants of.
static func takes_variant(mask: int) -> bool:
	return mask == FULL or mask in EDGE_MASKS

## The band-0 slot of `mask` drawn from variant `variant` (1..MAX_VARIANTS); `mask` must take variants.
static func varied_coords(mask: int, variant: int) -> Vector2i:
	assert(takes_variant(mask), "mask %d has no variants" % mask)
	if mask == FULL:
		return variant_coords(variant)
	return Vector2i(variant - 1, EDGE_ROW + EDGE_MASKS.find(mask))

## The band-0 slot of a ledge cell whose west and east cells are ledges of the same look.
static func ledge_coords(west: bool, east: bool) -> Vector2i:
	var piece := LEDGE_SINGLE
	if west and east:
		piece = LEDGE_MIDDLE
	elif east:
		piece = LEDGE_LEFT
	elif west:
		piece = LEDGE_RIGHT
	return Vector2i(piece, LEDGE_ROW)

## 0 for the plain fill or 1..MAX_VARIANTS; stable for a cell on every platform (integer hash).
static func fill_variant(cell: Vector2i) -> int:
	var h := (cell.x * 73856093) ^ (cell.y * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	var pick := posmod(h, 10)
	return pick - 5 if pick > 5 else 0

## 0 for the plain edge or 1..MAX_VARIANTS, varied 4 cells in 5 so a one-row street does not repeat.
static func edge_variant(cell: Vector2i) -> int:
	var h := (cell.x * 83492791) ^ (cell.y * 2971215073)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return posmod(h, MAX_VARIANTS + 1)

## The variant a sheet with `count` variants draws for `variant`: higher numbers fold onto the ones it has.
static func drawn_variant(variant: int, count: int) -> int:
	if variant <= 0 or count <= 0:
		return 0
	return (variant - 1) % count + 1

## The solid-corner mask `look` draws, from the looks at the corners (NW, NE, SW, SE; -1 for air).
## A later look counts for an earlier one only beside one of its corners: the edge-adjacent underlay.
## A corner under an earlier look is left to that look's underlay, so a buried top never draws its lip
## (bugs/stone-under-earth-draws-a-seasonal-lip-inside-the-ground). In a tile with no air where `look`
## appears, every later corner counts: no inner corner draws inside the ground (bugs/an-earth-cell-boxed-in-by-stone-grows-a-corner-tuft).
static func corner_mask(corners: PackedInt32Array, look: int) -> int:
	var buried := not corners.has(-1) and corners.has(look)
	var mask := 0
	for i: int in 4:
		var at := corners[i]
		if at == look:
			var above := corners[_ABOVE[i]] if _ABOVE[i] >= 0 else -1
			if above < 0 or above >= look:
				mask |= _BITS[i]
		elif at > look:
			if buried:
				mask |= _BITS[i]
				continue
			for j: int in _EDGE_NEIGHBOURS[i]:
				if corners[j] == look:
					mask |= _BITS[i]
					break
	return mask
