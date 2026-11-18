class_name EngravingMathTest extends GdUnitTestSuite

## The pan eases in whole game px, layers follow by depth, only ink drifts, captions keep their windows, frames fit.

const BASE := preload("res://assets/sprites/story/bearers/frost/frame_1_base.png")
const FLAKES := preload("res://assets/sprites/story/bearers/frost/frame_1_flakes.png")


func _layer(texture: Texture2D, depth: float = 1.0, ink_only: bool = false, drift := Vector2.ZERO) -> EngravingLayer:
	var layer := EngravingLayer.new()
	layer.texture = texture
	layer.depth = depth
	layer.ink_only = ink_only
	layer.drift = drift
	return layer

func _frame() -> EngravingFrame:
	var frame := EngravingFrame.new()
	frame.layers = [_layer(BASE), _layer(FLAKES, 0.5, true, Vector2(0.0, 3.0))]
	frame.captions = [&"BEARER_FROST_1"]
	frame.seconds = 8.0
	frame.pan_from = Vector2(0.0, 32.0)
	frame.pan_to = Vector2(63.0, 0.0)
	frame.reveal_seconds = 1.5
	frame.dissolve_seconds = 1.0
	return frame

func test_the_pan_eases_from_start_to_end() -> void:
	var frame := _frame()
	assert_vector(EngravingMath.window(frame, 0.0)).is_equal(Vector2(0.0, 32.0))
	assert_vector(EngravingMath.window(frame, 8.0)).is_equal(Vector2(63.0, 0.0))
	assert_vector(EngravingMath.window(frame, 99.0)).is_equal(Vector2(63.0, 0.0))
	# Eased: the first tenth moves less than a tenth of the way.
	assert_float(EngravingMath.window(frame, 0.8).x).is_less(6.3)
	assert_vector(EngravingMath.window(frame, 4.0)).is_equal(Vector2(31.5, 16.0))

func test_every_window_is_whole_game_px() -> void:
	var frame := _frame()
	for i: int in 81:
		var w := EngravingMath.window(frame, i * 0.1) * EngravingMath.ART_SCALE
		assert_vector(w).is_equal(w.round())

func test_a_layer_follows_its_depth_of_the_pan() -> void:
	var frame := _frame()
	assert_vector(EngravingMath.layer_window(frame, frame.layers[0], 8.0)).is_equal(Vector2(63.0, 0.0))
	assert_vector(EngravingMath.layer_window(frame, frame.layers[1], 8.0)).is_equal(Vector2(31.5, 16.0))
	assert_vector(EngravingMath.layer_window(frame, frame.layers[1], 0.0)).is_equal(Vector2(0.0, 32.0))

func test_only_ink_drifts_in_whole_px_and_wraps() -> void:
	var frame := _frame()
	assert_vector(EngravingMath.scroll(frame.layers[1], 2.5)).is_equal(Vector2(0.0, 7.0))
	assert_vector(EngravingMath.scroll(frame.layers[1], 60.0)).is_equal(Vector2(0.0, fposmod(180.0, 176.0)))
	var grey := _layer(BASE, 1.0, false, Vector2(5.0, 5.0))
	assert_vector(EngravingMath.scroll(grey, 3.0)).is_equal(Vector2.ZERO)

func test_a_loop_cell_turns_only_on_ink() -> void:
	var ink := _layer(FLAKES, 1.0, true)
	ink.hframes = 4
	ink.fps = 2.0
	assert_int(EngravingMath.cell(ink, 0.0)).is_equal(0)
	assert_int(EngravingMath.cell(ink, 1.6)).is_equal(3)
	assert_int(EngravingMath.cell(ink, 2.1)).is_equal(0)
	assert_vector(EngravingMath.cell_size(ink)).is_equal(Vector2(96.0, 176.0))
	var grey := _layer(BASE)
	grey.hframes = 4
	grey.fps = 2.0
	assert_int(EngravingMath.cell(grey, 1.6)).is_equal(0)

func test_reveal_and_dissolve_take_their_own_seconds() -> void:
	var frame := _frame()
	assert_float(EngravingMath.shown(frame, false, 0.75)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.shown(frame, true, 0.5)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.shown(frame, false, 1.5)).is_equal(1.0)

func test_the_caption_waits_for_the_frame_and_leaves_before_its_end() -> void:
	var frame := _frame()
	assert_float(EngravingMath.caption_alpha(frame, false, 1.4)).is_equal(0.0)
	assert_float(EngravingMath.caption_alpha(frame, false, 1.75)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.caption_alpha(frame, false, 4.0)).is_equal(1.0)
	assert_float(EngravingMath.caption_alpha(frame, false, 7.8)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.caption_alpha(frame, false, 8.0)).is_equal(0.0)
	assert_float(EngravingMath.caption_alpha(frame, true, 1.25)).is_equal_approx(0.5, 0.001)

func test_a_frame_fits_only_inside_its_canvas() -> void:
	var frame := _frame()
	assert_bool(EngravingMath.fits(frame)).is_true()
	frame.pan_to = Vector2(65.0, 0.0)
	assert_bool(EngravingMath.fits(frame)).is_false()
	frame.pan_to = Vector2(0.0, -1.0)
	assert_bool(EngravingMath.fits(frame)).is_false()
	frame.layers = []
	assert_bool(EngravingMath.fits(frame)).is_false()

func test_every_shipped_canvas_holds_the_widest_pan() -> void:
	var widest := EngravingMath.VIEW + Vector2(64.0, 32.0)
	for guardian: String in ["bloom", "frost", "autumn", "summer"]:
		var folder := "res://assets/sprites/story/bearers/%s/" % guardian
		for file: String in ResourceLoader.list_directory(folder):
			if not file.ends_with(".png"):
				continue
			var texture := load(folder + file) as Texture2D
			assert_vector(texture.get_size()).override_failure_message(folder + file).is_equal(widest)

func _turns(seconds: float = 9.0) -> EngravingFrame:
	var frame := _frame()
	frame.captions = [&"FINAL_FRAGMENT_1_1", &"FINAL_FRAGMENT_1_2"]
	frame.caption_turns = true
	frame.seconds = seconds
	return frame

## 9 s, entered over a 1 s dissolve: two 4 s turns from 1 s.
func test_turns_show_one_caption_at_a_time_in_equal_shares() -> void:
	var frame := _turns()
	assert_int(EngravingMath.caption_turn(frame, true, 0.0)).is_equal(0)
	assert_int(EngravingMath.caption_turn(frame, true, 4.9)).is_equal(0)
	assert_int(EngravingMath.caption_turn(frame, true, 5.0)).is_equal(1)
	assert_int(EngravingMath.caption_turn(frame, true, 99.0)).is_equal(1)
	assert_float(EngravingMath.caption_alpha(frame, true, 0.9)).is_equal(0.0)
	assert_float(EngravingMath.caption_alpha(frame, true, 1.25)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.caption_alpha(frame, true, 3.0)).is_equal(1.0)
	assert_float(EngravingMath.caption_alpha(frame, true, 4.8)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.caption_alpha(frame, true, 5.0)).is_equal(0.0)
	assert_float(EngravingMath.caption_alpha(frame, true, 5.25)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.caption_alpha(frame, true, 8.8)).is_equal_approx(0.5, 0.001)
	assert_float(EngravingMath.caption_alpha(frame, true, 9.0)).is_equal(0.0)

func test_a_frame_without_turns_shows_its_captions_together_as_before() -> void:
	var frame := _turns()
	frame.caption_turns = false
	assert_int(EngravingMath.caption_turn(frame, true, 6.0)).is_equal(0)
	assert_float(EngravingMath.caption_alpha(frame, true, 5.0)).is_equal(1.0)
	var single := _turns()
	single.captions = [&"FINAL_FRAGMENT_6_1"]
	assert_int(EngravingMath.caption_turn(single, true, 6.0)).is_equal(0)
	assert_float(EngravingMath.caption_alpha(single, true, 5.0)).is_equal(1.0)

func test_a_still_frame_never_trembles() -> void:
	var frame := _frame()
	for t: float in [0.0, 0.35, 4.0, 99.0]:
		assert_int(EngravingMath.tremble_step(frame, t)).is_equal(0)

func test_the_tremble_steps_at_its_rate_and_repeats_at_the_same_time() -> void:
	var frame := _frame()
	frame.tremble = 1.0
	assert_int(EngravingMath.tremble_step(frame, 0.0)).is_equal(0)
	assert_int(EngravingMath.tremble_step(frame, 0.09)).is_equal(0)
	assert_int(EngravingMath.tremble_step(frame, 0.1)).is_equal(1)
	assert_int(EngravingMath.tremble_step(frame, 2.55)).is_equal(25)
	assert_int(EngravingMath.tremble_step(frame, 2.55)).is_equal(EngravingMath.tremble_step(frame, 2.55))
	assert_int(EngravingMath.tremble_step(frame, -1.0)).is_equal(0)
