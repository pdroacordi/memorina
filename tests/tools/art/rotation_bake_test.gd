class_name RotationBakeTest extends GdUnitTestSuite

## Baked rotation keeps a symmetric still at frame 0, closes its loop even for a still that is not symmetric, keeps
## the pivot at the still's centre and never invents a colour.

# Whole 8-bit channels, so a colour read back from an RGBA8 image compares equal.
const RED := Color8(204, 51, 26)
const BLUE := Color8(26, 77, 204)


# A plus of two colours with 90 degree symmetry, 9 art px across.
func _plus() -> Image:
	var art := Image.create_empty(9, 9, false, Image.FORMAT_RGBA8)
	for i: int in 9:
		art.set_pixel(4, i, RED)
		art.set_pixel(i, 4, RED)
	art.set_pixel(4, 4, BLUE)
	return art

# A wheel-like ring with spokes of uneven lengths and one odd side: not symmetric under any turn.
func _lopsided() -> Image:
	var art := Image.create_empty(15, 14, false, Image.FORMAT_RGBA8)
	var centre := Vector2(7.5, 7.0)
	for y: int in 14:
		for x: int in 15:
			var d := (Vector2(x + 0.5, y + 0.5) - centre).length()
			if d > 5.0 and d < 6.6:
				art.set_pixel(x, y, RED)
	for i: int in 6:
		art.set_pixel(7, 7 - i, BLUE)
		art.set_pixel(7 + i / 2, 7 + i / 2, BLUE)
	art.set_pixel(1, 2, BLUE)
	return art

func _same(a: Image, b: Image) -> bool:
	for y: int in a.get_height():
		for x: int in a.get_width():
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				return false
	return true

func test_frame_zero_of_a_symmetric_still_is_the_still() -> void:
	var frame := RotationBake.frames(_plus(), 12, 90.0)[0]
	var padded := Image.create_empty(frame.get_width(), frame.get_height(), false, Image.FORMAT_RGBA8)
	padded.blit_rect(_plus(), Rect2i(0, 0, 9, 9), Vector2i(2, 2))
	assert_bool(_same(frame, padded)).is_true()

func test_one_period_later_is_frame_zero_again() -> void:
	assert_bool(_same(RotationBake.turned(_lopsided(), 45.0, 45.0), RotationBake.turned(_lopsided(), 0.0, 45.0))).is_true()

func test_the_wrap_step_is_an_ordinary_step() -> void:
	var frames := RotationBake.frames(_lopsided(), 12, 45.0)
	assert_float(RotationBake.wrap_ratio(frames)).is_less_equal(1.2)

func test_every_colour_comes_from_the_still() -> void:
	for frame: Image in RotationBake.frames(_lopsided(), 6, 45.0):
		for y: int in frame.get_height():
			for x: int in frame.get_width():
				var colour := frame.get_pixel(x, y)
				assert_bool(colour.a == 0.0 or colour == RED or colour == BLUE).is_true()

func test_a_turned_frame_differs_from_frame_zero() -> void:
	assert_bool(_same(RotationBake.turned(_plus(), 30.0, 90.0), RotationBake.turned(_plus(), 0.0, 90.0))).is_false()

func test_the_strip_holds_every_frame_at_scale() -> void:
	var frames := RotationBake.frames(_plus(), 4, 90.0)
	var strip := RotationBake.strip(frames, 2)
	assert_vector(strip.get_size()).is_equal(Vector2i(frames[0].get_width() * 4 * 2, frames[0].get_height() * 2))
