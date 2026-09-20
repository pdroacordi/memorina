class_name PlayerInputTest extends GdUnitTestSuite

## glyph_set_for() is static and takes the joypad name as a value, so it runs
## with no Input singleton, no device and no scene tree.

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

## Anything that is not recognisably PlayStation gets the Xbox layout, the
## de-facto standard the SDL mapping follows.
func test_an_unknown_pad_draws_xbox_glyphs() -> void:
	assert_int(PlayerInput.glyph_set_for(_joy_button(), "Unknown Gamepad")).is_equal(Enums.GlyphSet.XBOX)

func test_playstation_pads_draw_playstation_glyphs() -> void:
	for name: String in ["PS5 Controller", "Sony DualSense", "DualShock 4", "Wireless Controller"]:
		assert_int(PlayerInput.glyph_set_for(_joy_button(), name)).override_failure_message(name).is_equal(Enums.GlyphSet.PLAYSTATION)

## "Xbox Wireless Controller" contains "Wireless Controller", the name a
## DualShock 4 reports on Windows; only the exact name may match.
func test_the_bare_wireless_controller_name_is_an_exact_match() -> void:
	assert_bool(PlayerInput.is_playstation_name("Wireless Controller")).is_true()
	assert_bool(PlayerInput.is_playstation_name("Xbox Wireless Controller")).is_false()
