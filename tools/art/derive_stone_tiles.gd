extends SceneTree

## Derives the STONE half of floor_tiles.png from its EARTH half.
##
## Enraizar only links earth to earth (docs/design/02_mecanicas.md section
## 7.1), so the player must be able to read the material at a glance. The
## earth tiles (columns 0-8 of every seasonal band) are the authored source;
## this script writes columns 9-17 as the same shapes in cut stone: the soil
## turns to cool masonry with 1 px mortar courses, the rim pebbles to grey
## rock, and the season's top (grass, leaves, frost) is muted to moss, lichen
## and snow so the season still reads on stone.
##
## Idempotent: it reads only columns 0-8, so rerun it whenever the earth art
## changes. The TileSet (resources/world/tiles/floor_tileset.tres) marks
## columns 9-17 as material STONE.
##
## Run from the project root:
##   "<godot>" --headless --path . -s res://tools/art/derive_stone_tiles.gd

const SHEET := "res://assets/sprites/world/tilesets/floor_tiles.png"
const TILE := 32
const EARTH_COLUMNS := 9
## A season's top is anything this saturated and bright, or simply this bright
## (winter's frost is nearly white); everything else is soil or rim.
const TOP_SATURATION := 0.35
const TOP_VALUE := 0.3
const FROST_VALUE := 0.7
## Soil luminance spans roughly this range; it is stretched onto the stone's.
const SOIL_LUMA := Vector2(0.06, 0.5)
const STONE_LUMA := Vector2(0.2, 0.56)
const STONE_DARK := Color(0.16, 0.17, 0.21)
const STONE_LIGHT := Color(0.66, 0.68, 0.72)
## Masonry courses: bricks COURSE px high, BRICK px long, every other course
## offset by half a brick. Both divide TILE, so courses run seamlessly across
## neighbouring tiles.
const COURSE := 16
const BRICK := 32
## Pixels this close to a transparent pixel are rim, and get no mortar.
const RIM_DEPTH := 4

func _init() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	assert(source != null, "Could not read %s" % SHEET)
	source.convert(Image.FORMAT_RGBA8)
	var earth_width := EARTH_COLUMNS * TILE
	var out := Image.create(earth_width * 2, source.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(source, Rect2i(0, 0, earth_width, source.get_height()), Vector2i.ZERO)
	for y: int in source.get_height():
		for x: int in earth_width:
			var c := source.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			out.set_pixel(earth_width + x, y, _stone(source, x, y, c))
	out.save_png(ProjectSettings.globalize_path(SHEET))
	print("Wrote stone columns %d-%d into %s" % [EARTH_COLUMNS, EARTH_COLUMNS * 2 - 1, SHEET])
	quit()

func _stone(source: Image, x: int, y: int, c: Color) -> Color:
	if (c.s > TOP_SATURATION and c.v > TOP_VALUE) or c.v > FROST_VALUE:
		# Keep the season's hue, lose most of its life: moss, lichen, snow.
		return Color.from_hsv(c.h, c.s * 0.45, minf(c.v * 1.02, 1.0), c.a)
	var luma := c.get_luminance()
	var t := inverse_lerp(SOIL_LUMA.x, SOIL_LUMA.y, luma)
	var stone := STONE_DARK.lerp(STONE_LIGHT, lerpf(STONE_LUMA.x, STONE_LUMA.y, clampf(t, 0.0, 1.0)))
	stone.a = c.a
	if _is_rim(source, x, y):
		return stone
	return stone * _mortar(x % TILE, y % TILE)

## Darker on the mortar line, a touch brighter on the row under it (the
## course's lit top edge), untouched elsewhere.
func _mortar(local_x: int, local_y: int) -> Color:
	var course_y := local_y % COURSE
	var offset := (BRICK / 2) if (local_y / COURSE) % 2 == 1 else 0
	var brick_x := (local_x + offset) % BRICK
	if course_y == 0 or brick_x == 0:
		return Color(0.72, 0.72, 0.74, 1.0)
	if course_y == 1 or brick_x == 1:
		return Color(1.12, 1.12, 1.12, 1.0)
	return Color.WHITE

func _is_rim(source: Image, x: int, y: int) -> bool:
	var tile_x := x - x % TILE
	var tile_y := y - y % TILE
	for dy: int in range(-RIM_DEPTH, RIM_DEPTH + 1):
		for dx: int in range(-RIM_DEPTH, RIM_DEPTH + 1):
			var px := x + dx
			var py := y + dy
			# Only this tile's own pixels count: a neighbour tile's transparency
			# is not an edge of this one.
			if px < tile_x or py < tile_y or px >= tile_x + TILE or py >= tile_y + TILE:
				continue
			if source.get_pixel(px, py).a <= 0.0:
				return true
	return false
