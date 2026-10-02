class_name InputGlyphsTest extends GdUnitTestSuite

## A prompt draws the button under the player's hand: the arrow key on the
## keyboard, the D-pad or the stick on any pad, and the face buttons and
## shoulders in the pad's own family. Every pad binding Ivo has must have a
## glyph - a pad has no key name to fall back on.

const GLYPHS := preload("res://resources/ui/input/input_glyphs.tres")
const PAD_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"look_up", &"look_down", &"jump", &"attack", &"roll",
	&"draw_memorina", &"note_up", &"note_down", &"note_left", &"note_right",
]

func test_the_bench_prompt_is_the_down_arrow_on_the_keyboard() -> void:
	var event := InputDevice.binding_for(&"look_down", false)
	var glyph := GLYPHS.glyph_for(event, Enums.GlyphSet.KEYBOARD_ARROWS)
	assert_object(glyph).is_not_null()
	assert_str(glyph.normal.resource_path).ends_with("key_down_normal.png")

func test_the_bench_prompt_is_the_dpad_on_either_pad() -> void:
	var event := InputDevice.binding_for(&"look_down", true)
	for glyph_set: Enums.GlyphSet in [Enums.GlyphSet.XBOX, Enums.GlyphSet.PLAYSTATION]:
		assert_str(GLYPHS.glyph_for(event, glyph_set).normal.resource_path).ends_with("dpad_down_normal.png")

func test_a_face_button_is_drawn_in_the_pads_own_family() -> void:
	var event := InputDevice.binding_for(&"jump", true)
	assert_str(GLYPHS.glyph_for(event, Enums.GlyphSet.XBOX).normal.resource_path).ends_with("xbox_a_normal.png")
	assert_str(GLYPHS.glyph_for(event, Enums.GlyphSet.PLAYSTATION).normal.resource_path).ends_with("ps_cross_normal.png")

func test_a_key_with_no_symbol_has_no_glyph() -> void:
	var event := InputDevice.binding_for(&"jump", false)
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
