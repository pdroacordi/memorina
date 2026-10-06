class_name PlayerInputTest extends GdUnitTestSuite

## Tests device classification without requiring an Input singleton or scene tree.

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event

func _joy_button() -> InputEventJoypadButton:
	return InputEventJoypadButton.new()

func test_arrow_keys_draw_arrow_glyphs() -> void:
	for keycode: Key in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		assert_int(PlayerInput.glyph_set_for(_key(keycode), "")).is_equal(Enums.GlyphSet.KEYBOARD_ARROWS)

func test_wasd_keys_draw_letter_glyphs() -> void:
	for keycode: Key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		assert_int(PlayerInput.glyph_set_for(_key(keycode), "")).is_equal(Enums.GlyphSet.KEYBOARD_WASD)

func test_an_xbox_pad_draws_xbox_glyphs() -> void:
	assert_int(PlayerInput.glyph_set_for(_joy_button(), "Xbox Wireless Controller")).is_equal(Enums.GlyphSet.XBOX)

## Unknown pad names use the Xbox layout.
func test_an_unknown_pad_draws_xbox_glyphs() -> void:
	assert_int(PlayerInput.glyph_set_for(_joy_button(), "Unknown Gamepad")).is_equal(Enums.GlyphSet.XBOX)

func test_playstation_pads_draw_playstation_glyphs() -> void:
	for name: String in ["PS5 Controller", "Sony DualSense", "DualShock 4", "Wireless Controller"]:
		assert_int(PlayerInput.glyph_set_for(_joy_button(), name)).override_failure_message(name).is_equal(Enums.GlyphSet.PLAYSTATION)

## Exact matching prevents the Xbox name from matching the PlayStation substring.
func test_the_bare_wireless_controller_name_is_an_exact_match() -> void:
	assert_bool(PlayerInput.is_playstation_name("Wireless Controller")).is_true()
	assert_bool(PlayerInput.is_playstation_name("Xbox Wireless Controller")).is_false()

## A jump released while the tree was paused is still cut once it runs again.
func test_a_jump_released_during_a_pause_is_cut_on_resync() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	var cuts: Array = []
	input.jump_canceled.connect(func() -> void: cuts.append(true))
	input._input(_action("jump", true))
	input.resync(true, false)
	assert_int(cuts.size()).is_equal(0)
	input.resync(false, false)
	assert_int(cuts.size()).is_equal(1)
	input.resync(false, false)
	assert_int(cuts.size()).is_equal(1)

## Down held through a menu is not a new edge afterwards: no sit nobody asked for.
func test_down_held_through_a_pause_is_not_a_new_press() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	var presses: Array = []
	input.look_down_pressed.connect(func() -> void: presses.append(true))
	input.resync(false, true)
	input._input(_stick_y(0.97))
	assert_int(presses.size()).is_equal(0)

## Down released during a menu: the first press afterwards counts.
func test_down_released_during_a_pause_presses_again() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	var presses: Array = []
	input.look_down_pressed.connect(func() -> void: presses.append(true))
	input._input(_stick_y(0.9))
	input.resync(false, false)
	input._input(_stick_y(0.9))
	assert_int(presses.size()).is_equal(2)

## The map blocks Ivo by disabling his input node: no `_input`, no axes.
func test_a_blocked_input_cannot_process_and_reads_no_axis() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	add_child(input)
	input.blocked = true
	assert_bool(input.can_process()).is_false()
	assert_float(input.direction).is_equal(0.0)
	assert_float(input.look_direction).is_equal(0.0)
	input.blocked = false
	assert_bool(input.can_process()).is_true()

## A jump released while the map was open is cut when it closes, as after a pause.
func test_a_jump_released_while_blocked_is_cut_on_unblock() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	add_child(input)
	var cuts: Array = []
	input.jump_canceled.connect(func() -> void: cuts.append(true))
	input._input(_action("jump", true))
	input.blocked = true
	input.blocked = false
	assert_int(cuts.size()).is_equal(1)

func _action(action: StringName, pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event

func _stick_y(value: float) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_Y
	motion.axis_value = value
	return motion
