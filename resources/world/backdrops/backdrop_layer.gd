@tool
class_name BackdropLayer
extends Resource
## One parallax layer of a backdrop: a stacked seasonal strip and how it moves and fills (architecture/vertical-backdrops).

## What a layer shows past the top or bottom of its strip.
enum Fill { NONE, EDGE, REPEAT }

## A stacked sheet: `band_count` equal bands, one per season.
@export var texture: Texture2D
@export_range(1, 8) var band_count: int = 3
## Band per Enums.Season (WINTER, SUMMER, AUTUMN, SPRING); must agree with tools/stack_seasonal_sheets.gd.
@export var band_of_season: Vector4i = Vector4i(2, 0, 1, 0)
## 0..1 per axis: 0 stays on screen, 1 moves with the world.
@export var scroll_scale: Vector2 = Vector2(0.5, 0.5)
## Band-local art row drawn on the room's horizon.
@export var horizon_row: int = 0
@export var fill_above: Fill = Fill.NONE
@export var fill_below: Fill = Fill.EDGE
## Tile the strip horizontally; false leaves it transparent left and right of the art.
@export var repeat_x: bool = true
## 0..1, how far away it reads: the haze takes it where the world is forgotten (systems/seasonal-art).
@export_range(0.0, 1.0) var distance: float = 0.0


## Size of one band in px.
func strip_size() -> Vector2i:
	if texture == null:
		return Vector2i.ZERO
	return Vector2i(texture.get_width(), texture.get_height() / band_count)

## Developer diagnostics; empty when the layer is usable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if texture == null:
		found.append("no texture")
		return found
	if texture.get_height() % band_count != 0:
		found.append("height %d does not divide into %d bands" % [texture.get_height(), band_count])
	for axis: int in 2:
		if scroll_scale[axis] < 0.0 or scroll_scale[axis] > 1.0:
			found.append("scroll_scale out of 0..1: %s" % scroll_scale)
	for season: int in 4:
		if band_of_season[season] < 0 or band_of_season[season] >= band_count:
			found.append("band_of_season %s points past %d bands" % [band_of_season, band_count])
			break
	return found
