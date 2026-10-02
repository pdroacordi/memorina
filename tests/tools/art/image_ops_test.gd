class_name ImageOpsTest extends GdUnitTestSuite

## Image operation tests cover keying, quantization, trimming and packing.

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

func test_holes_clears_the_key_the_body_encloses() -> void:
	var image := _image(Vector2i(7, 7), KEY)
	image.fill_rect(Rect2i(1, 1, 5, 5), Color.DARK_GREEN)
	image.set_pixel(3, 3, KEY)
	var keyed := ImageOps.key_out(image, KEY, 0.25, true)
	assert_float(keyed.get_pixel(3, 3).a).is_equal(0.0)
	assert_float(keyed.get_pixel(2, 2).a).is_equal(1.0)

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

func test_trimming_crops_frames_to_their_shared_bounds() -> void:
	var raised := _image(Vector2i(20, 20), Color(0, 0, 0, 0))
	raised.fill_rect(Rect2i(4, 6, 10, 6), Color.WHITE)
	var pressed := _image(Vector2i(20, 20), Color(0, 0, 0, 0))
	pressed.fill_rect(Rect2i(4, 9, 10, 3), Color.WHITE)
	var trimmed := ImageOps.trim_frames([raised, pressed] as Array[Image])
	assert_vector(trimmed[0].get_size()).is_equal(Vector2i(10, 6))
	assert_vector(trimmed[1].get_size()).is_equal(Vector2i(10, 6))
	# The trimmed frame remains bottom-aligned in the shared bounds.
	assert_float(trimmed[1].get_pixel(0, 0).a).is_equal(0.0)
	assert_float(trimmed[1].get_pixel(0, 5).a).is_equal(1.0)

func test_trimming_leaves_empty_frames_alone() -> void:
	var empty := _image(Vector2i(8, 8), Color(0, 0, 0, 0))
	assert_vector(ImageOps.trim_frames([empty] as Array[Image])[0].get_size()).is_equal(Vector2i(8, 8))

func test_packing_keeps_proportions_and_stands_the_frame_bottom_centre() -> void:
	# A 40x4 frame scales to 20x2 and aligns to the 20x4 cell bottom.
	var frames: Array[Image] = [_image(Vector2i(40, 4), Color.WHITE)]
	var strip := ImageOps.pack_strip(frames, Vector2i(20, 4))
	assert_vector(strip.get_size()).is_equal(Vector2i(20, 4))
	assert_float(strip.get_pixel(10, 1).a).is_equal(0.0)
	assert_float(strip.get_pixel(10, 3).a).is_equal(1.0)

func test_packing_resizes_every_frame_to_the_contract() -> void:
	var frames: Array[Image] = [_image(Vector2i(64, 24), Color.WHITE), _image(Vector2i(64, 24), Color.BLACK)]
	var strip := ImageOps.pack_strip(frames, Vector2i(32, 12))
	assert_vector(strip.get_size()).is_equal(Vector2i(64, 12))
	assert_bool(strip.get_pixel(40, 5).is_equal_approx(Color.BLACK)).is_true()
