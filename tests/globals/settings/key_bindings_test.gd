class_name KeyBindingsTest extends GdUnitTestSuite

## The managed input of each rebindable action is today's project default; the arrows and the zooms are not managed.


func test_from_input_map_captures_the_keyboard_defaults() -> void:
	var table := KeyBindings.from_input_map(KeyBindings.Device.KEYBOARD)
	var expected: Dictionary[StringName, int] = {
		&"jump": KEY_Z, &"attack": KEY_X, &"roll": KEY_SHIFT, &"draw_memorina": KEY_C,
		&"note_up": KEY_W, &"note_down": KEY_S, &"note_left": KEY_A, &"note_right": KEY_D,
		&"map": KEY_M, &"notebook": KEY_E,
	}
	assert_dict(table.codes).is_equal(expected)

func test_from_input_map_captures_the_pad_defaults() -> void:
	var table := KeyBindings.from_input_map(KeyBindings.Device.PAD)
	var expected: Dictionary[StringName, int] = {
		&"jump": JOY_BUTTON_A, &"attack": JOY_BUTTON_X, &"roll": JOY_BUTTON_B,
		&"draw_memorina": JOY_BUTTON_RIGHT_SHOULDER,
		&"note_up": JOY_BUTTON_Y, &"note_down": JOY_BUTTON_A, &"note_left": JOY_BUTTON_X, &"note_right": JOY_BUTTON_B,
		&"map": JOY_BUTTON_LEFT_SHOULDER, &"notebook": JOY_BUTTON_BACK,
	}
	assert_dict(table.codes).is_equal(expected)

func test_the_arrows_and_the_zooms_are_not_managed() -> void:
	var table := KeyBindings.from_input_map(KeyBindings.Device.KEYBOARD)
	for arrow: int in KeyBindings.ARROW_KEYS:
		assert_array(table.holders(arrow)).is_empty()
	assert_bool(KeyBindings.REBINDABLE.has(&"map_zoom_in")).is_false()
	assert_bool(KeyBindings.REBINDABLE.has(&"map_zoom_out")).is_false()

func test_fixed_and_reserved_codes_are_captured() -> void:
	var keys := KeyBindings.from_input_map(KeyBindings.Device.KEYBOARD)
	assert_array(keys.fixed_holders(KEY_Z)).contains_exactly([KeyBindings.ACCEPT])
	assert_array(keys.fixed_holders(KEY_ESCAPE)).contains_exactly([KeyBindings.CANCEL])
	for reserved: int in [KEY_ESCAPE, KEY_UP, KEY_LEFT, KEY_F8, KEY_F9, KEY_F10]:
		assert_bool(keys.reserved.has(reserved)).override_failure_message(str(reserved)).is_true()
	var pad := KeyBindings.from_input_map(KeyBindings.Device.PAD)
	assert_array(pad.fixed_holders(JOY_BUTTON_A)).contains_exactly([KeyBindings.ACCEPT])
	assert_array(pad.fixed_holders(JOY_BUTTON_B)).contains_exactly([KeyBindings.CANCEL])
	assert_bool(pad.reserved.has(JOY_BUTTON_START)).is_true()

func test_a_copy_is_independent() -> void:
	var table := KeyBindings.from_input_map(KeyBindings.Device.KEYBOARD)
	var copied := table.copy()
	copied.codes[&"jump"] = KEY_SPACE
	assert_int(table.code(&"jump")).is_equal(KEY_Z)
	assert_bool(table.equals(copied)).is_false()
