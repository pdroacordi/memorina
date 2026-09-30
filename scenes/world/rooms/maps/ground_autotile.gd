class_name GroundAutotile extends RefCounted

## Which floor_tiles.png tile a ground cell draws with, decided by its
## neighbours. Pure: a room map is resolved to atlas coordinates once, at
## import, so a room's load is a plain set_cell per cell.
##
## The sheet's band 0, per material (earth at column 0, stone at column 9):
##   (0..2, 0..2)  a 3x3 block: grassy top row, sides, rounded bottom row
##   (3, 1)        a one-tile-wide wall piece (edges on both sides)
##   (4, 3) (5, 3) a step's inner corner: solid, with the grass of the ledge
##                 above-left / above-right tufting over its top corner
##   (6, 0) (8, 0) inner corners opening below-right / below-left (a cave's rim)
##   (6, 3) (6, 4) a one-tile-wide pillar's top and bottom
##   (6..8, 5)     a one-tile-high platform: left end, middle, right end
## Everything a cell's shape depends on is whether each of its eight
## neighbours is solid; the material only picks the column block.

## The `ground` custom data layer of floor_tileset.tres.
const GROUND_DATA := "ground"
const SOURCE_ID := 1
const ONE_WAY_ALTERNATIVE := 1
const STONE_COLUMN := 9

const PLATFORM_LEFT := Vector2i(6, 5)
const PLATFORM_MIDDLE := Vector2i(7, 5)
const PLATFORM_RIGHT := Vector2i(8, 5)

## Bits of the neighbourhood mask.
const N := 1
const E := 2
const S := 4
const W := 8
const NE := 16
const SE := 32
const SW := 64
const NW := 128

## The earth tile for a solid cell whose solid neighbours are `mask`.
static func tile_for(mask: int) -> Vector2i:
	var n := mask & N != 0
	var e := mask & E != 0
	var s := mask & S != 0
	var w := mask & W != 0
	if not n:
		if not s:
			return platform_tile(w, e)
		return _row(w, e, Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(6, 3))
	if not s:
		return _row(w, e, Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(6, 4))
	if w and e:
		# Surrounded on all four sides: an inner corner shows where a diagonal
		# opens. Above, it is a step, and the ledge's grass tufts over the
		# corner (what the rooms were painted with); below, a cave's rim.
		if mask & NW == 0:
			return Vector2i(4, 3)
		if mask & NE == 0:
			return Vector2i(5, 3)
		if mask & SE == 0:
			return Vector2i(6, 0)
		if mask & SW == 0:
			return Vector2i(8, 0)
		return Vector2i(1, 1)
	return _row(w, e, Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1))

## A one-tile-high run: ends where the run ends. A lone cell takes the left
## end - the sheet has no single-tile piece.
static func platform_tile(west: bool, east: bool) -> Vector2i:
	if west and east:
		return PLATFORM_MIDDLE
	if west:
		return PLATFORM_RIGHT
	return PLATFORM_LEFT

## The same shape in the given material's column block.
static func in_material(tile: Vector2i, ground: Enums.Ground) -> Vector2i:
	return tile + Vector2i(STONE_COLUMN, 0) if ground == Enums.Ground.STONE else tile

static func is_platform_piece(coords: Vector2i) -> bool:
	var earth := Vector2i(coords.x % STONE_COLUMN, coords.y)
	return earth == PLATFORM_LEFT or earth == PLATFORM_MIDDLE or earth == PLATFORM_RIGHT

static func _row(w: bool, e: bool, left: Vector2i, middle: Vector2i, right: Vector2i, alone: Vector2i) -> Vector2i:
	if w and e:
		return middle
	if e:
		return left
	if w:
		return right
	return alone
