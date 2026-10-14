class_name RegionTitleOrnament
extends Control
## The rule under a region's name: a diamond with a line running out each side, in pack px.

## Diamond width and height, px.
const DIAMOND := 5
## The diamond's centre row and column; the lines run on this row.
const MID := 2
## Pixels at each line's outer end drawn every other pixel.
const DITHER := 6

## Each line's length beside the diamond, px.
@export var line_length: int = 40:
	set(value):
		line_length = maxi(value, DITHER)
		_fit()
@export var color: Color = Color(0.96, 0.9, 0.72)
## Drawn 1 px under every pixel, so the rule reads on snow and sky.
@export var shadow: Color = Color(0.13, 0.08, 0.05)


func _ready() -> void:
	_fit()

func _draw() -> void:
	_draw_rule(Vector2i(0, 1), shadow)
	_draw_rule(Vector2i.ZERO, color)

## Centres the rule on `centre_x` with its line row at `line_y`, in the parent's px.
func place(centre_x: float, line_y: float) -> void:
	position = Vector2(floorf(centre_x - size.x * 0.5), line_y - MID)

# The rect covers every pixel drawn, shadow row included (gotchas/a-control-is-culled-by-its-own-rect).
func _fit() -> void:
	custom_minimum_size = Vector2(line_length * 2 + DIAMOND, DIAMOND + 1)
	size = custom_minimum_size
	queue_redraw()

func _draw_rule(offset: Vector2i, ink: Color) -> void:
	for row: int in DIAMOND:
		var half := MID - absi(row - MID)
		_dot(Vector2i(line_length + MID - half, row) + offset, Vector2i(half * 2 + 1, 1), ink)
	for i: int in line_length:
		var from_end := line_length - 1 - i
		if from_end < DITHER and from_end % 2 == 1:
			continue
		_dot(Vector2i(line_length - 1 - i, MID) + offset, Vector2i.ONE, ink)
		_dot(Vector2i(line_length + DIAMOND + i, MID) + offset, Vector2i.ONE, ink)

func _dot(at: Vector2i, extent: Vector2i, ink: Color) -> void:
	draw_rect(Rect2(at, extent), ink)
