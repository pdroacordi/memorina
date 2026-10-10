class_name WangSheet
extends RefCounted
## Builds look sheets on the corner-Wang contract (architecture/biome-tilesets, "Sheet contract"): composed from a body and a lip,
## from the legacy 8-neighbour sheet, or as flat placeholders. Masks use GroundAutotile's corner bits; a cell edge is a tile's midline.

## The contract's tile, px; a sheet is composed at `tile_px` and scaled up to it (systems/art-pipeline, art scale).
const TILE := 32
const HALF := 16
## Rows per season band in the legacy 8-neighbour sheet; not the Wang sheet's GroundAutotile.BAND_ROWS.
const _BLOB_BAND_ROWS := 6
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
## PixelLab's corner names and our mask bits.
const _CORNER_KEYS := {"NW": GroundAutotile.NW, "NE": GroundAutotile.NE, "SW": GroundAutotile.SW, "SE": GroundAutotile.SE}

## The tile size every function composes at, px: TILE / the art scale.
static var tile_px := TILE
static var half_px := HALF


## Composes at TILE / `scale` px per tile, so one art pixel is `scale` game pixels (2: the same as Ivo).
static func use_scale(scale: int) -> void:
	tile_px = TILE / scale
	half_px = tile_px / 2


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
		pieces.append(sheet.get_region(Rect2i((at + Vector2i(column0, band * _BLOB_BAND_ROWS)) * tile_px, Vector2i(tile_px, tile_px))))
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
			tile.fill_rect(Rect2i(at, Vector2i(half_px, half_px)), fill)
			if mask & _vertical_partner(quadrant) == 0:
				if bottom:
					tile.fill_rect(Rect2i(at, Vector2i(half_px, 4)), lip)
				else:
					tile.fill_rect(Rect2i(at + Vector2i(0, half_px - 1), Vector2i(half_px, 1)), edge)
			if mask & _horizontal_partner(quadrant) == 0:
				tile.fill_rect(Rect2i(at + Vector2i(half_px - 1 if left else 0, 0), Vector2i(1, half_px)), edge)
		tiles.append(tile)
	return tiles

## Thin placeholder ledge pieces in the top 8 px of the cell, with a `lip` top.
static func placeholder_ledge(fill: Color, lip: Color) -> Array[Image]:
	var pieces: Array[Image] = []
	for piece: int in 4:
		var tile := _empty()
		tile.fill_rect(Rect2i(0, 0, tile_px, 8), fill)
		tile.fill_rect(Rect2i(0, 0, tile_px, 2), lip)
		pieces.append(tile)
	return pieces

## The 16 tiles (index = mask) of a PixelLab v2 sidescroller tileset result; a corner is solid where it is `lower`.
static func tiles_from_pixellab(result: Dictionary) -> Array[Image]:
	var tiles: Array[Image] = []
	tiles.resize(16)
	for entry: Dictionary in result["tileset"]["tiles"]:
		var corners: Dictionary = entry["corners"]
		var mask := 0
		for key: String in _CORNER_KEYS:
			if corners[key] == "lower":
				mask |= _CORNER_KEYS[key]
		var image := Image.new()
		image.load_png_from_buffer(Marshalls.base64_to_raw(entry["image"]["base64"]))
		image.convert(Image.FORMAT_RGBA8)
		tiles[mask] = image
	return tiles

## Tiles composed from a seamless 32 px `body`: exposed faces get `radius` px rounded outer corners, an `edge`
## outline and a `rim` px darker band; every exposed top gets `lip`, a 32 px wide strip whose walk line is its row `spill`.
static func compose(body: Image, lip: Image, spill: int, radius: int, rim: int, edge: Color, rim_dark: float = 0.35) -> Array[Image]:
	var tiles: Array[Image] = []
	for mask: int in 16:
		var tile := _empty()
		for y: int in tile_px:
			for x: int in tile_px:
				var quadrant := _quadrant_at(x, y)
				if mask & quadrant == 0:
					continue
				var d := _edge_distance(mask, quadrant, x, y, radius)
				if d < 0:
					continue
				var color := body.get_pixel(x, y)
				# A transparent edge means no outline ("no outlines", user, 2026-10-10): the rim's shade alone marks the face.
				if d == 0 and edge.a > 0.0:
					color = edge
				elif d < rim:
					color = color.darkened(rim_dark * (1.0 - float(d) / rim))
				tile.set_pixel(x, y, color)
		_lay_lip(tile, mask, lip, spill)
		tiles.append(tile)
	return tiles

## Ledge pieces (left, middle, right, single): the body's top `height` rows, rounded and rimmed at open ends, with `lip` on top.
static func compose_ledge(body: Image, lip: Image, spill: int, height: int, radius: int, rim: int, edge: Color) -> Array[Image]:
	var pieces: Array[Image] = []
	for piece: int in 4:
		var open_left := piece in [GroundAutotile.LEDGE_LEFT, GroundAutotile.LEDGE_SINGLE]
		var open_right := piece in [GroundAutotile.LEDGE_RIGHT, GroundAutotile.LEDGE_SINGLE]
		var tile := _empty()
		for y: int in height:
			for x: int in tile_px:
				var dx := 99
				if open_left:
					dx = mini(dx, x)
				if open_right:
					dx = mini(dx, tile_px - 1 - x)
				var dy := height - 1 - y
				var d := mini(dx, dy)
				if dx < radius and dy < radius:
					var cx := radius - dx - 0.5
					var cy := radius - dy - 0.5
					var arc := sqrt(cx * cx + cy * cy)
					if arc > radius:
						continue
					d = int(radius - arc)
				var color := body.get_pixel(x, y)
				if d == 0 and edge.a > 0.0:
					color = edge
				elif d < rim:
					color = color.darkened(0.35 * (1.0 - float(d) / rim))
				tile.set_pixel(x, y, color)
		for x: int in tile_px:
			if tile.get_pixel(x, 0).a > 0.0:
				_lip_column(tile, lip, spill, x, 0)
		pieces.append(tile)
	return pieces

## A 32 px strip of grass blades over a thin mat: the walk line is row `spill`, blades rise up to `spill` px above it.
## Seamless sideways; `rng_seed` fixes it.
## `density` (0..1) is the share of columns with a blade; `ferns` is how many fern fronds rise from the mat.
static func blade_strip(rng_seed: int, greens: PackedColorArray, flowers: PackedColorArray, spill: int, depth: int,
		density: float = 0.85, ferns: int = 0) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var strip := Image.create_empty(tile_px, spill + depth, false, Image.FORMAT_RGBA8)
	var tufts := _periodic_curve(rng, 4)
	var top := greens.size() - 1
	for x: int in tile_px:
		# The mat: a lit top row, a darker one, then sparse roots of green into the soil. A sparse fringe
		# (density under 0.5, moss on cobbles) has none, so what it grows on shows.
		for r: int in depth if density >= 0.5 else 0:
			var color := greens[mini(2, top)] if r == 0 else greens[1] if r == 1 else greens[0]
			if r < 2 or rng.randf() < 0.6 - r * 0.15:
				strip.set_pixel(x, spill + r, color)
		if rng.randf() < density:
			# Tufts: heights follow a smooth periodic curve, so the top reads as clumps, not a comb.
			var blade := clampi(int(round(spill * tufts[x])) + rng.randi_range(-1, 0), 1, spill)
			# Some blades are two px wide, the second a shade darker, so a tuft has body; every tip is lit.
			var wide := rng.randf() < 0.4
			for h: int in blade:
				var color := greens[clampi(1 + h * top / maxi(blade, 1), 1, top)]
				if h == blade - 1:
					color = color.lightened(0.12)
				strip.set_pixel(x, spill - 1 - h, color)
				if wide and h < blade - 1:
					strip.set_pixel((x + 1) % tile_px, spill - 1 - h, color.darkened(0.2))
			if not flowers.is_empty() and blade >= spill - 2 and rng.randf() < 0.18:
				strip.set_pixel(x, spill - blade, flowers[rng.randi() % flowers.size()])
	for i: int in ferns:
		_fern(strip, rng.randi() % tile_px, spill, greens)
	return strip

## A fern frond rising from the mat at x: a stem leaning sideways with leaflets on both sides, seamless around x.
static func _fern(strip: Image, x: int, spill: int, greens: PackedColorArray) -> void:
	var lean := 1 if x % 2 == 0 else -1
	for h: int in spill:
		var sx := posmod(x + lean * (h / 3), tile_px)
		var y := spill - 1 - h
		var color := greens[clampi(1 + h * (greens.size() - 1) / spill, 1, greens.size() - 1)]
		strip.set_pixel(sx, y, color)
		if h % 2 == 0 and h < spill - 1:
			strip.set_pixel(posmod(sx - 1, tile_px), y, color.darkened(0.15))
			strip.set_pixel(posmod(sx + 1, tile_px), y, color.darkened(0.15))
			if h < spill - 3:
				strip.set_pixel(posmod(sx - 2, tile_px), y + 1, color.darkened(0.3))
				strip.set_pixel(posmod(sx + 2, tile_px), y + 1, color.darkened(0.3))

## A 32 px strip of small laid cobbles on the walk line `spill`: ovals 4-6 px wide and 3 px tall in `stones`
## (light to dark), dark joints; it covers the top `depth` px of the body.
static func cobble_strip(rng_seed: int, stones: PackedColorArray, joint: Color, spill: int, depth: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var strip := Image.create_empty(tile_px, spill + depth, false, Image.FORMAT_RGBA8)
	for row: int in maxi(1, depth / 3):
		var top := spill + row * 3
		var x := rng.randi_range(0, 3)
		while x < tile_px + 4:
			var width := rng.randi_range(5, 8)
			var base := rng.randi_range(0, stones.size() - 2)
			for dx: int in width:
				for dy: int in 3:
					var px := (x + dx) % tile_px
					var corner := (dx == 0 or dx == width - 1) and dy != 1
					# The walk's top row is bumpy: its stones' upper corners are air, not joint.
					if corner and dy == 0 and row == 0:
						continue
					var color := joint if dx == width - 1 or corner else stones[clampi(base + dy, 0, stones.size() - 1)]
					strip.set_pixel(px, top + dy, color)
			x += width
	return strip

## `strips` blended in order: a cobble walk under a fringe of moss, say.
static func layered(strips: Array[Image]) -> Image:
	var out := Image.create_empty(tile_px, strips[0].get_height(), false, Image.FORMAT_RGBA8)
	for strip: Image in strips:
		for y: int in mini(strip.get_height(), out.get_height()):
			for x: int in tile_px:
				var color := strip.get_pixel(x, y)
				if color.a > 0.0:
					out.set_pixel(x, y, out.get_pixel(x, y).blend(color))
	return out

## A 32 px strip of leaf litter (2 px leaves) around the walk line `spill`, a few loose leaves above it.
static func litter_strip(rng_seed: int, leaves: PackedColorArray, spill: int, depth: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var strip := Image.create_empty(tile_px, spill + depth, false, Image.FORMAT_RGBA8)
	for i: int in 70:
		var x := rng.randi() % tile_px
		var y := spill - 2 + rng.randi_range(0, depth + 1)
		if rng.randf() < 0.12:
			y = rng.randi_range(0, spill - 2)
		var color := leaves[rng.randi() % leaves.size()]
		for dx: int in 2:
			var px := (x + dx) % tile_px
			if y >= 0 and y < strip.get_height():
				strip.set_pixel(px, y, color)
	return strip

## A 32 px strip of snow crust: a soft white top that rises up to `spill` px over the walk line, shaded blue below.
static func snow_strip(rng_seed: int, whites: PackedColorArray, shades: PackedColorArray, spill: int, depth: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var strip := Image.create_empty(tile_px, spill + depth, false, Image.FORMAT_RGBA8)
	var drifts := _periodic_curve(rng, 2)
	for x: int in tile_px:
		# The crust's height follows a smooth periodic curve, so it is seamless sideways and never a regular wave.
		var rise := clampi(int(round(spill * drifts[x])) - 1, 1, spill)
		for y: int in range(spill - rise, spill + depth):
			var under := y - spill
			var color := whites[0] if y == spill - rise else whites[mini(1, whites.size() - 1)]
			if under >= depth - 2:
				color = shades[mini(under - (depth - 2), shades.size() - 1)]
			strip.set_pixel(x, y, color)
	return strip

## A 128x960 sheet from three bands (spring, autumn, winter), each {"tiles": 16, "variants": up to 4 sets of 16, "ledge": 4 or none}.
## A variant set fills its column of the fill row and of every edge row (GroundAutotile.takes_variant).
static func pack(bands: Array[Dictionary]) -> Image:
	var sheet := Image.create_empty(BiomeTileset.SHEET_SIZE.x * tile_px / TILE, BiomeTileset.SHEET_SIZE.y * tile_px / TILE, false, Image.FORMAT_RGBA8)
	for band: int in bands.size():
		var row0 := band * GroundAutotile.BAND_ROWS
		var tiles: Array = bands[band].get("tiles", [])
		for mask: int in tiles.size():
			_blit(sheet, tiles[mask], GroundAutotile.wang_coords(mask) + Vector2i(0, row0))
		var variants: Array = bands[band].get("variants", [])
		for v: int in variants.size():
			var variant_tiles: Array = variants[v]
			for mask: int in [GroundAutotile.FULL] + GroundAutotile.EDGE_MASKS:
				_blit(sheet, variant_tiles[mask], GroundAutotile.varied_coords(mask, v + 1) + Vector2i(0, row0))
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
	var source: Vector2i = _BLOB[quarter][case] + Vector2i(column0, band * _BLOB_BAND_ROWS)
	var offset := Vector2i(half_px if quarter.ends_with("e") else 0, half_px if quarter.begins_with("s") else 0)
	tile.blit_rect(sheet, Rect2i(source * tile_px + offset, Vector2i(half_px, half_px)), _origin(corner))

## Px from (x, y) to its quadrant's exposed edge on the tile midlines (0 = the edge pixel); -1 where a rounded corner cuts.
static func _edge_distance(mask: int, quadrant: int, x: int, y: int, radius: int) -> int:
	var left := x < half_px
	var top := y < half_px
	var h_open := mask & _horizontal_partner(quadrant) == 0
	var v_open := mask & _vertical_partner(quadrant) == 0
	var dx := half_px - 1 - x if left else x - half_px
	var dy := half_px - 1 - y if top else y - half_px
	if h_open and v_open and dx < radius and dy < radius:
		var cx := radius - dx - 0.5
		var cy := radius - dy - 0.5
		var arc := sqrt(cx * cx + cy * cy)
		if arc > radius:
			return -1
		return int(radius - arc)
	var d := 99
	if h_open:
		d = mini(d, dx)
	# A bottom quadrant open above is a top face: its lip draws the edge.
	if v_open and top:
		d = mini(d, dy)
	return d

## Lays `lip` along every exposed top of `tile`, following a rounded corner's curve.
static func _lay_lip(tile: Image, mask: int, lip: Image, spill: int) -> void:
	for x: int in tile_px:
		var quadrant := GroundAutotile.SW if x < half_px else GroundAutotile.SE
		if mask & quadrant == 0 or mask & _vertical_partner(quadrant) != 0:
			continue
		for y: int in range(half_px, tile_px):
			if tile.get_pixel(x, y).a > 0.0:
				_lip_column(tile, lip, spill, x, y)
				break

## Blends `lip`'s column x over `tile` with the lip's walk line at `surface`.
static func _lip_column(tile: Image, lip: Image, spill: int, x: int, surface: int) -> void:
	for r: int in lip.get_height():
		var y := surface - spill + r
		if y < 0 or y >= tile_px:
			continue
		var color := lip.get_pixel(x, r)
		if color.a > 0.0:
			tile.set_pixel(x, y, tile.get_pixel(x, y).blend(color))

## 32 values in 0.35..1 along a smooth curve with `bumps` bumps, wrapping at 32.
static func _periodic_curve(rng: RandomNumberGenerator, bumps: int) -> PackedFloat32Array:
	var phases := [rng.randf() * TAU, rng.randf() * TAU]
	var values := PackedFloat32Array()
	for x: int in tile_px:
		var t := TAU * x / tile_px
		var v := 0.5 + 0.3 * sin(bumps * t + phases[0]) + 0.2 * sin((bumps * 2 + 1) * t + phases[1])
		values.append(clampf(0.35 + 0.65 * v, 0.35, 1.0))
	return values

static func _quadrant_at(x: int, y: int) -> int:
	if y < half_px:
		return GroundAutotile.NW if x < half_px else GroundAutotile.NE
	return GroundAutotile.SW if x < half_px else GroundAutotile.SE

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
	return Vector2i(half_px if quadrant in [GroundAutotile.NE, GroundAutotile.SE] else 0, half_px if quadrant in [GroundAutotile.SW, GroundAutotile.SE] else 0)

static func _blit(sheet: Image, tile: Image, at: Vector2i) -> void:
	sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, Vector2i(tile_px, tile_px)), at * tile_px)

static func _empty() -> Image:
	return Image.create_empty(tile_px, tile_px, false, Image.FORMAT_RGBA8)
