class_name InputGlyphsTest extends GdUnitTestSuite

## Verifies glyphs exist for keyboard and gamepad bindings.

const GLYPHS := preload("res://resources/ui/input/input_glyphs.tres")
const PAD_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"look_up", &"look_down", &"jump", &"attack", &"roll",
	&"draw_memorina", &"note_up", &"note_down", &"note_left", &"note_right",
]

func test_the_bench_prompt_is_the_down_arrow_on_the_keyboard() -> void:
	var event := InputDevice.binding_for(&"look_down", Enums.GlyphSet.KEYBOARD_ARROWS)
	var glyph := GLYPHS.glyph_for(event, Enums.GlyphSet.KEYBOARD_ARROWS)
	assert_object(glyph).is_not_null()
	assert_str(glyph.normal.resource_path).ends_with("key_down_normal.png")

func test_the_bench_prompt_is_the_dpad_on_either_pad() -> void:
	var event := InputDevice.binding_for(&"look_down", Enums.GlyphSet.XBOX)
	for glyph_set: Enums.GlyphSet in [Enums.GlyphSet.XBOX, Enums.GlyphSet.PLAYSTATION]:
		assert_str(GLYPHS.glyph_for(event, glyph_set).normal.resource_path).ends_with("dpad_down_normal.png")

func test_a_face_button_is_drawn_in_the_pads_own_family() -> void:
	var event := InputDevice.binding_for(&"jump", Enums.GlyphSet.XBOX)
	assert_str(GLYPHS.glyph_for(event, Enums.GlyphSet.XBOX).normal.resource_path).ends_with("xbox_a_normal.png")
	assert_str(GLYPHS.glyph_for(event, Enums.GlyphSet.PLAYSTATION).normal.resource_path).ends_with("ps_cross_normal.png")

func test_a_key_with_no_symbol_has_no_glyph() -> void:
	var event := InputDevice.binding_for(&"jump", Enums.GlyphSet.KEYBOARD_ARROWS)
	assert_object(GLYPHS.glyph_for(event, Enums.GlyphSet.KEYBOARD_ARROWS)).is_null()

func test_every_pad_binding_has_a_glyph() -> void:
	var missing: Array[String] = []
	for action: StringName in PAD_ACTIONS:
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				continue
			for glyph_set: Enums.GlyphSet in [Enums.GlyphSet.XBOX, Enums.GlyphSet.PLAYSTATION]:
				if GLYPHS.glyph_for(event, glyph_set) == null:
					missing.append("%s %s" % [action, event.as_text()])
	assert_array(missing).is_empty()

func test_a_stick_counts_only_when_pushed() -> void:
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_Y
	drift.axis_value = 0.2
	assert_bool(InputDevice._is_deliberate(drift)).is_false()
	drift.axis_value = 0.9
	assert_bool(InputDevice._is_deliberate(drift)).is_true()

## Stick motion must retain its controller glyph family.
func test_a_stick_is_the_pad() -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	assert_int(PlayerInput.glyph_set_for(motion, "Xbox Wireless Controller")).is_equal(Enums.GlyphSet.XBOX)
	assert_int(PlayerInput.glyph_set_for(motion, "DualSense Wireless Controller")).is_equal(Enums.GlyphSet.PLAYSTATION)

func test_a_wasd_player_is_shown_their_own_key() -> void:
	var event := InputDevice.binding_for(&"note_down", Enums.GlyphSet.KEYBOARD_WASD) as InputEventKey
	assert_int(event.physical_keycode).is_equal(KEY_S)
	event = InputDevice.binding_for(&"note_down", Enums.GlyphSet.KEYBOARD_ARROWS) as InputEventKey
	assert_int(event.physical_keycode).is_equal(KEY_DOWN)

## Repeated stick motion past the deadzone emits one press until released.
func test_a_held_stick_asks_to_sit_once() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	var presses: Array = []
	input.look_down_pressed.connect(func() -> void: presses.append(true))
	for value: float in [0.9, 0.95, 0.92, 1.0]:
		input._input(_stick_y(value))
	assert_int(presses.size()).is_equal(1)
	input._input(_stick_y(0.1))
	input._input(_stick_y(0.9))
	assert_int(presses.size()).is_equal(2)
	# Flicked straight through to up and back: up lets go of down too.
	input._input(_stick_y(-0.9))
	input._input(_stick_y(0.9))
	assert_int(presses.size()).is_equal(3)

func _stick_y(value: float) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_Y
	motion.axis_value = value
	return motion
