class_name WangSheet
extends RefCounted
## Builds look sheets on the corner-Wang contract (architecture/biome-tilesets, "Sheet contract"): from the legacy 8-neighbour sheet,
## or as flat placeholders. Every tile is 32 px; masks use GroundAutotile's corner bits; a cell edge is a tile's midline.

const TILE := 32
const HALF := 16
## Legacy sheet tiles per quarter, by case: outer corner, open vertically, open horizontally, inner corner, fill.
const _BLOB := {
	"nw": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(4, 3), Vector2i(1, 1)],
	"ne": [Vector2i(2, 0), Vector2i(1, 0), Vector2i(2, 1), Vector2i(5, 3), Vector2i(1, 1)],
	"sw": [Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 1), Vector2i(8, 0), Vector2i(1, 1)],
	"se": [Vector2i(2, 2), Vector2i(1, 2), Vector2i(2, 1), Vector2i(6, 0), Vector2i(1, 1)],
}
## The legacy ledge strip: left, middle, right; the single piece reuses the left end.
const _BLOB_LEDGE: Array[Vector2i] = [Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(6, 5)]
const _QUADRANTS: Array[int] = [GroundAutotile.NW, GroundAutotile.NE, GroundAutotile.SW, GroundAutotile.SE]


## The 16 tiles (index = mask; mask 0 is empty) of one band, cut from the legacy sheet's block at `column0`.
static func tiles_from_blob(sheet: Image, column0: int, band: int) -> Array[Image]:
	var tiles: Array[Image] = []
	for mask: int in 16:
		var tile := _empty()
		# A display quadrant shows the quarter of its corner cell nearest the tile centre; that cell's
		# horizontal, vertical and diagonal neighbours are the tile's other corners.
		_blob_quarter(tile, sheet, column0, band, mask, GroundAutotile.NW, "se", GroundAutotile.NE, GroundAutotile.SW, GroundAutotile.SE)
		_blob_quarter(tile, sheet, column0, band, mask, GroundAutotile.NE, "sw", GroundAutotile.NW, GroundAutotile.SE, GroundAutotile.SW)
		_blob_quarter(tile, sheet, column0, band, mask, GroundAutotile.SW, "ne", GroundAutotile.SE, GroundAutotile.NW, GroundAutotile.NE)
		_blob_quarter(tile, sheet, column0, band, mask, GroundAutotile.SE, "nw", GroundAutotile.SW, GroundAutotile.NE, GroundAutotile.NW)
		tiles.append(tile)
	return tiles

## The four ledge pieces (left, middle, right, single) of one band of the legacy sheet.
static func ledge_from_blob(sheet: Image, column0: int, band: int) -> Array[Image]:
	var pieces: Array[Image] = []
	for at: Vector2i in _BLOB_LEDGE:
		pieces.append(sheet.get_region(Rect2i((at + Vector2i(column0, band * GroundAutotile.BAND_ROWS)) * TILE, Vector2i(TILE, TILE))))
	return pieces

## Flat placeholder tiles: `fill`, a 1 px darker edge where a solid quadrant meets air, and a 4 px `lip` on exposed tops.
static func placeholder_tiles(fill: Color, lip: Color) -> Array[Image]:
	var edge := fill.darkened(0.45)
	var tiles: Array[Image] = []
	for mask: int in 16:
		var tile := _empty()
		for quadrant: int in _QUADRANTS:
			if mask & quadrant == 0:
				continue
			var at := _origin(quadrant)
			var bottom := quadrant in [GroundAutotile.SW, GroundAutotile.SE]
			var left := quadrant in [GroundAutotile.NW, GroundAutotile.SW]
			tile.fill_rect(Rect2i(at, Vector2i(HALF, HALF)), fill)
			if mask & _vertical_partner(quadrant) == 0:
				if bottom:
					tile.fill_rect(Rect2i(at, Vector2i(HALF, 4)), lip)
				else:
					tile.fill_rect(Rect2i(at + Vector2i(0, HALF - 1), Vector2i(HALF, 1)), edge)
			if mask & _horizontal_partner(quadrant) == 0:
				tile.fill_rect(Rect2i(at + Vector2i(HALF - 1 if left else 0, 0), Vector2i(1, HALF)), edge)
		tiles.append(tile)
	return tiles

## Thin placeholder ledge pieces in the top 8 px of the cell, with a `lip` top.
static func placeholder_ledge(fill: Color, lip: Color) -> Array[Image]:
	var pieces: Array[Image] = []
	for piece: int in 4:
		var tile := _empty()
		tile.fill_rect(Rect2i(0, 0, TILE, 8), fill)
		tile.fill_rect(Rect2i(0, 0, TILE, 2), lip)
		pieces.append(tile)
	return pieces

## A 128x576 sheet from three bands (spring, autumn, winter), each {"tiles": 16, "variants": up to 4, "ledge": 4 or none}.
static func pack(bands: Array[Dictionary]) -> Image:
	var sheet := Image.create_empty(BiomeTileset.SHEET_SIZE.x, BiomeTileset.SHEET_SIZE.y, false, Image.FORMAT_RGBA8)
	for band: int in bands.size():
		var row0 := band * GroundAutotile.BAND_ROWS
		var tiles: Array = bands[band].get("tiles", [])
		for mask: int in tiles.size():
			_blit(sheet, tiles[mask], GroundAutotile.wang_coords(mask) + Vector2i(0, row0))
		var variants: Array = bands[band].get("variants", [])
		for v: int in variants.size():
			_blit(sheet, variants[v], GroundAutotile.variant_coords(v + 1) + Vector2i(0, row0))
		var ledge: Array = bands[band].get("ledge", [])
		for piece: int in ledge.size():
			_blit(sheet, ledge[piece], Vector2i(piece, GroundAutotile.LEDGE_ROW + row0))
	return sheet

static func _blob_quarter(tile: Image, sheet: Image, column0: int, band: int, mask: int, corner: int, quarter: String, h_bit: int, v_bit: int, d_bit: int) -> void:
	if mask & corner == 0:
		return
	var h := mask & h_bit != 0
	var v := mask & v_bit != 0
	var d := mask & d_bit != 0
	var case := 4
	if not h and not v:
		case = 0
	elif not v:
		case = 1
	elif not h:
		case = 2
	elif not d:
		case = 3
	var source: Vector2i = _BLOB[quarter][case] + Vector2i(column0, band * GroundAutotile.BAND_ROWS)
	var offset := Vector2i(HALF if quarter.ends_with("e") else 0, HALF if quarter.begins_with("s") else 0)
	tile.blit_rect(sheet, Rect2i(source * TILE + offset, Vector2i(HALF, HALF)), _origin(corner))

static func _vertical_partner(quadrant: int) -> int:
	match quadrant:
		GroundAutotile.NW:
			return GroundAutotile.SW
		GroundAutotile.SW:
			return GroundAutotile.NW
		GroundAutotile.NE:
			return GroundAutotile.SE
	return GroundAutotile.NE

static func _horizontal_partner(quadrant: int) -> int:
	match quadrant:
		GroundAutotile.NW:
			return GroundAutotile.NE
		GroundAutotile.NE:
			return GroundAutotile.NW
		GroundAutotile.SW:
			return GroundAutotile.SE
	return GroundAutotile.SW

static func _origin(quadrant: int) -> Vector2i:
	return Vector2i(HALF if quadrant in [GroundAutotile.NE, GroundAutotile.SE] else 0, HALF if quadrant in [GroundAutotile.SW, GroundAutotile.SE] else 0)

static func _blit(sheet: Image, tile: Image, at: Vector2i) -> void:
	sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(TILE, TILE)), at * TILE)

static func _empty() -> Image:
	return Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
