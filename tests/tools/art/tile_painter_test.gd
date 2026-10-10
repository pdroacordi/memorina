class_name TilePainterTest extends GdUnitTestSuite

## Bodies are deterministic 32 px tiles, and a variant changes nothing within the margin, so every variant
## tiles with the plain body.

const RAMP := ["#101010", "#303030", "#505050", "#707070"]


func _ramp() -> PackedColorArray:
	var colors := PackedColorArray()
	for hex: String in RAMP:
		colors.append(Color.html(hex))
	return colors

func test_a_body_is_a_deterministic_tile() -> void:
	var a := TilePainter.noise_body(3, _ramp())
	var b := TilePainter.noise_body(3, _ramp())
	assert_vector(Vector2i(a.get_size())).is_equal(Vector2i(TilePainter.SIZE, TilePainter.SIZE))
	assert_bool(a.get_data() == b.get_data()).is_true()

func test_a_variant_keeps_the_border() -> void:
	var body := TilePainter.stone_body(4, 6, _ramp(), Color.BLACK, PackedColorArray())
	var variant := TilePainter.decorated(body, 9, 8, PackedStringArray(["pebble", "root", "sprig"]), {})
	for y: int in TilePainter.SIZE:
		for x: int in TilePainter.SIZE:
			var inside := x >= TilePainter.MARGIN and y >= TilePainter.MARGIN \
					and x < TilePainter.SIZE - TilePainter.MARGIN and y < TilePainter.SIZE - TilePainter.MARGIN
			if not inside:
				assert_that(variant.get_pixel(x, y)).is_equal(body.get_pixel(x, y))
