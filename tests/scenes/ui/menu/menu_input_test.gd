class_name MenuInputTest extends GdUnitTestSuite

## MenuInput emits at most one signal per event, and a stick turns a page once per tilt.

var _input: MenuInput
var _emitted: Array[String] = []


func before_test() -> void:
	_emitted.clear()
	_input = auto_free(MenuInput.new())
	_input.pause_pressed.connect(func() -> void: _emitted.append("pause"))
	_input.notebook_pressed.connect(func() -> void: _emitted.append("notebook"))
	_input.map_pressed.connect(func() -> void: _emitted.append("map"))
	_input.zoom_pressed.connect(func(direction: int) -> void: _emitted.append("zoom %d" % direction))
	_input.back_pressed.connect(func() -> void: _emitted.append("back"))
	_input.page_pressed.connect(func(direction: int) -> void: _emitted.append("page %d" % direction))
	_input.bind_pressed.connect(
			func(device: KeyBindings.Device, code: int) -> void: _emitted.append("bind %d %d" % [device, code]))
	_input.capture_cancelled.connect(func() -> void: _emitted.append("cancel"))

func test_escape_is_pause_and_not_also_back() -> void:
	_input._input(_key(KEY_ESCAPE))
	assert_array(_emitted).contains_exactly(["pause"])

func test_each_toggle_key_emits_its_signal() -> void:
	_input._input(_key(KEY_E))
	_input._input(_key(KEY_M))
	assert_array(_emitted).contains_exactly(["notebook", "map"])

func test_pad_buttons_emit_their_signals() -> void:
	for button: JoyButton in [JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_B]:
		_input._input(_pad(button))
	assert_array(_emitted).contains_exactly(["pause", "notebook", "map", "back"])

## Z is also ui_accept; the zoom is what MenuInput reports.
func test_zoom_keys_carry_their_direction() -> void:
	_input._input(_key(KEY_Z))
	_input._input(_key(KEY_X))
	assert_array(_emitted).contains_exactly(["zoom 1", "zoom -1"])

func test_a_held_key_does_not_repeat() -> void:
	var echo := _key(KEY_ESCAPE)
	echo.echo = true
	_input._input(_key(KEY_RIGHT))
	_input._input(echo)
	assert_array(_emitted).contains_exactly(["page 1"])

func test_a_held_stick_turns_one_page_per_tilt() -> void:
	for value: float in [0.6, 0.8, 0.95, 1.0]:
		_input._input(_stick_x(value))
	assert_array(_emitted).contains_exactly(["page 1"])
	_input._input(_stick_x(0.1))
	_input._input(_stick_x(0.9))
	assert_array(_emitted).contains_exactly(["page 1", "page 1"])
	# Flicked straight through to the left: left is a new tilt.
	_input._input(_stick_x(-0.9))
	_input._input(_stick_x(-1.0))
	assert_array(_emitted).contains_exactly(["page 1", "page 1", "page -1"])

## While capturing, a key or pad button is a candidate and nothing else is emitted: E, B and Z are not toggles or back.
func test_capture_emits_only_bind_presses() -> void:
	_input.capturing = true
	_input._input(_key(KEY_E))
	_input._input(_key(KEY_Z))
	_input._input(_pad(JOY_BUTTON_B))
	_input._input(_pad(JOY_BUTTON_LEFT_SHOULDER))
	assert_array(_emitted).contains_exactly(["bind 0 %d" % KEY_E, "bind 0 %d" % KEY_Z, "bind 1 %d" % JOY_BUTTON_B,
			"bind 1 %d" % JOY_BUTTON_LEFT_SHOULDER])

func test_pause_cancels_a_capture_from_either_device() -> void:
	_input.capturing = true
	_input._input(_key(KEY_ESCAPE))
	_input._input(_pad(JOY_BUTTON_START))
	assert_array(_emitted).contains_exactly(["cancel", "cancel"])

func test_capture_ignores_echoes_releases_and_motion() -> void:
	_input.capturing = true
	var echo := _key(KEY_Q)
	echo.echo = true
	var release := _key(KEY_Q)
	release.pressed = false
	_input._input(echo)
	_input._input(release)
	_input._input(_stick_x(1.0))
	assert_array(_emitted).is_empty()

## Leaving capture re-reads the held directions: a press during it never leaves a stale edge behind.
func test_leaving_capture_rereads_the_page_edges() -> void:
	_input._input(_key(KEY_RIGHT))
	_input.capturing = true
	_input.capturing = false
	_input._input(_key(KEY_RIGHT))
	assert_array(_emitted).contains_exactly(["page 1", "page 1"])

func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event

func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event

func _stick_x(value: float) -> InputEventJoypadMotion:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = value
	return motion
