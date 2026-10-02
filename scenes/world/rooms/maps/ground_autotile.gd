class_name GroundAutotile extends RefCounted

## Resolves a ground cell's atlas tile from its eight solid neighbours; material selects its column block.

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
		# Diagonal openings determine inner corners for steps and cave rims.
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

## Selects a tile for a one-tile-high run; a lone cell uses the left end because the sheet has no single-cell tile.
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
