class_name ImageOpsTest extends GdUnitTestSuite

## The art pipeline steps: key the background out from the edges, snap to
## the palette, cut and pack frames to the contract.

const KEY := Color(1, 0, 1)

func _image(size: Vector2i, color: Color) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image

func test_the_background_is_keyed_out_from_the_edges() -> void:
	var image := _image(Vector2i(6, 6), KEY)
	image.fill_rect(Rect2i(2, 2, 2, 2), Color.DARK_GREEN)
	var keyed := ImageOps.key_out(image, KEY)
	assert_float(keyed.get_pixel(0, 0).a).is_equal(0.0)
	assert_float(keyed.get_pixel(2, 2).a).is_equal(1.0)

func test_key_colour_enclosed_by_the_body_survives() -> void:
	var image := _image(Vector2i(7, 7), KEY)
	image.fill_rect(Rect2i(1, 1, 5, 5), Color.DARK_GREEN)
	image.set_pixel(3, 3, KEY)
	var keyed := ImageOps.key_out(image, KEY)
	assert_float(keyed.get_pixel(3, 3).a).is_equal(1.0)

func test_quantize_snaps_to_the_nearest_palette_colour() -> void:
	var image := _image(Vector2i(2, 1), Color(0.9, 0.1, 0.1))
	var snapped := ImageOps.quantize(image, PackedColorArray([Color.RED, Color.BLUE]))
	assert_bool(snapped.get_pixel(0, 0).is_equal_approx(Color.RED)).is_true()

func test_quantize_makes_alpha_binary() -> void:
	var image := _image(Vector2i(2, 1), Color(1, 0, 0, 0.3))
	image.set_pixel(1, 0, Color(1, 0, 0, 0.7))
	var snapped := ImageOps.quantize(image, PackedColorArray([Color.RED]))
	assert_float(snapped.get_pixel(0, 0).a).is_equal(0.0)
	assert_float(snapped.get_pixel(1, 0).a).is_equal(1.0)

func test_a_strip_splits_into_equal_frames() -> void:
	var frames := ImageOps.split_strip(_image(Vector2i(30, 8), Color.WHITE), 3)
	assert_int(frames.size()).is_equal(3)
	assert_vector(frames[0].get_size()).is_equal(Vector2i(10, 8))

func test_packing_resizes_every_frame_to_the_contract() -> void:
	var frames: Array[Image] = [_image(Vector2i(64, 24), Color.WHITE), _image(Vector2i(64, 24), Color.BLACK)]
	var strip := ImageOps.pack_strip(frames, Vector2i(32, 12))
	assert_vector(strip.get_size()).is_equal(Vector2i(64, 12))
	assert_bool(strip.get_pixel(40, 5).is_equal_approx(Color.BLACK)).is_true()
