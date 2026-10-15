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

## A stick tilted up reports on every motion past the deadzone; the door hears one press.
func test_up_is_one_press_per_tilt() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	var presses: Array = []
	input.look_up_pressed.connect(func() -> void: presses.append(true))
	input._input(_stick_y(-0.9))
	input._input(_stick_y(-0.97))
	assert_int(presses.size()).is_equal(1)

## Up held through a door's fade is not a new edge afterwards: no bounce back through it.
func test_up_held_through_a_resync_is_not_a_new_press() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	var presses: Array = []
	input.look_up_pressed.connect(func() -> void: presses.append(true))
	input.resync(false, false, true)
	input._input(_stick_y(-0.97))
	assert_int(presses.size()).is_equal(0)

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

func _act(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

## A jump held into a NOTES beat and let go during it is cut once the beat frees him (systems/story).
func test_a_jump_released_through_a_notes_beat_is_cut_on_clearing() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	add_child(input)
	var cuts: Array[int] = [0]
	input.jump_canceled.connect(func() -> void: cuts[0] += 1)
	_act(&"jump", true)
	await await_idle_frame()
	input.notes_only = true
	_act(&"jump", false)
	await await_idle_frame()
	assert_int(cuts[0]).is_equal(0)
	input.notes_only = false
	assert_int(cuts[0]).is_equal(1)

## Up held through a NOTES beat is not a new press once it ends.
func test_up_held_through_a_notes_beat_is_not_a_new_press() -> void:
	var input: PlayerInput = auto_free(PlayerInput.new())
	add_child(input)
	var ups: Array[int] = [0]
	input.look_up_pressed.connect(func() -> void: ups[0] += 1)
	input.notes_only = true
	_act(&"look_up", true)
	await await_idle_frame()
	input.notes_only = false
	_act(&"look_up", true)
	await await_idle_frame()
	_act(&"look_up", false)
	await await_idle_frame()
	assert_int(ups[0]).is_equal(0)
