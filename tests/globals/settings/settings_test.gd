class_name SettingsTest extends GdUnitTestSuite

## The autoload under the suite: no disk, no file; a binding reaches InputMap with the zooms following, and a reset
## restores the project's events.


func after_test() -> void:
	Settings.reset_bindings(KeyBindings.Device.KEYBOARD)
	Settings.reset_bindings(KeyBindings.Device.PAD)
	Settings.set_volume(AudioBuses.MUSIC, SettingsMath.VOLUME_STEPS)
	Settings.set_weather(GameSettings.WEATHER_STEPS)

func _codes(action: StringName, device: KeyBindings.Device) -> Array[int]:
	var found: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var code := KeyBindings.code_of(event, device)
		if code != KeyBindings.NONE:
			found.append(code)
	return found

## A headless run shares the player's user://, where a played debug session leaves settings_debug.cfg: the run must leave
## any such file as it found it, never require it absent (bugs/settings-test-fails-when-the-players-debug-settings-file-exists).
func test_a_headless_run_has_no_disk_and_writes_no_file() -> void:
	assert_bool(Settings.has_disk()).is_false()
	assert_str((Settings.get(&"_file") as SettingsFile).path()).is_empty()
	var before := _settings_files()
	Settings.set_volume(AudioBuses.MUSIC, 3)
	Settings.commit()
	assert_dict(_settings_files()).is_equal(before)

# Whether each user://settings*.cfg exists, and its modified time when it does: read by stat only, never opened.
func _settings_files() -> Dictionary:
	var found := {}
	for debug: bool in [true, false]:
		var path := Settings.PATH.path_join(SettingsFile.file_name(debug))
		var exists := FileAccess.file_exists(path)
		found[path] = [exists, FileAccess.get_modified_time(path) if exists else 0]
	return found

## A MEMORY session reads no file, so regional weather starts at its full 10 steps.
func test_a_memory_session_keeps_full_weather() -> void:
	assert_int(Settings.weather()).is_equal(GameSettings.WEATHER_STEPS)
	assert_float(Settings.weather_intensity()).is_equal(1.0)
	Settings.set_weather(13)
	assert_int(Settings.weather()).override_failure_message("a step clamps at 10").is_equal(10)
	Settings.set_weather(3)
	assert_float(Settings.weather_intensity()).is_equal_approx(0.3, 0.0001)

func test_a_volume_step_sets_its_bus() -> void:
	Settings.set_volume(AudioBuses.MUSIC, 5)
	var index := AudioServer.get_bus_index(AudioBuses.MUSIC)
	assert_float(AudioServer.get_bus_volume_db(index)).is_equal_approx(SettingsMath.volume_db(5), 0.01)
	Settings.set_volume(AudioBuses.MUSIC, 0)
	assert_bool(AudioServer.is_bus_mute(index)).is_true()
	Settings.set_volume(AudioBuses.MUSIC, 10)
	assert_bool(AudioServer.is_bus_mute(index)).is_false()

func test_bind_writes_input_map_and_the_zoom_follows() -> void:
	var told: Array[int] = [0]
	var count := func() -> void: told[0] += 1
	Settings.bindings_changed.connect(count)
	var result := Settings.bind(KeyBindings.Device.KEYBOARD, &"jump", KEY_SPACE)
	Settings.bindings_changed.disconnect(count)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.ASSIGNED)
	assert_int(told[0]).is_equal(1)
	assert_array(_codes(&"jump", KeyBindings.Device.KEYBOARD)).contains_exactly([KEY_SPACE])
	assert_array(_codes(&"map_zoom_in", KeyBindings.Device.KEYBOARD)).contains_exactly([KEY_SPACE])
	assert_array(_codes(&"jump", KeyBindings.Device.PAD)).contains_exactly([JOY_BUTTON_A])

func test_a_note_keeps_its_arrow_when_its_letter_moves() -> void:
	Settings.bind(KeyBindings.Device.KEYBOARD, &"note_up", KEY_Q)
	assert_array(_codes(&"note_up", KeyBindings.Device.KEYBOARD)).contains_exactly([KEY_UP, KEY_Q])

func test_a_swap_moves_both_and_the_zooms() -> void:
	Settings.bind(KeyBindings.Device.PAD, &"jump", JOY_BUTTON_X)
	assert_array(_codes(&"attack", KeyBindings.Device.PAD)).contains_exactly([JOY_BUTTON_A])
	assert_array(_codes(&"map_zoom_in", KeyBindings.Device.PAD)).contains_exactly([JOY_BUTTON_X])
	assert_array(_codes(&"map_zoom_out", KeyBindings.Device.PAD)).contains_exactly([JOY_BUTTON_A])

func test_a_refusal_changes_nothing() -> void:
	var result := Settings.bind(KeyBindings.Device.PAD, &"map", JOY_BUTTON_A)
	assert_int(result.outcome).is_equal(BindingRules.Outcome.REFUSED_TAKEN)
	assert_array(_codes(&"map", KeyBindings.Device.PAD)).contains_exactly([JOY_BUTTON_LEFT_SHOULDER])

func test_reset_restores_the_defaults() -> void:
	Settings.bind(KeyBindings.Device.KEYBOARD, &"attack", KEY_V)
	Settings.reset_bindings(KeyBindings.Device.KEYBOARD)
	assert_array(_codes(&"attack", KeyBindings.Device.KEYBOARD)).contains_exactly([KEY_X])
	assert_array(_codes(&"map_zoom_out", KeyBindings.Device.KEYBOARD)).contains_exactly([KEY_X])

## bugs/a-rebound-pad-button-answers-only-joypad-0: a rebound or reset event answers every device, as the project's do.
func test_a_rebound_and_a_reset_event_answer_every_device() -> void:
	Settings.bind(KeyBindings.Device.PAD, &"jump", JOY_BUTTON_Y)
	Settings.bind(KeyBindings.Device.KEYBOARD, &"jump", KEY_SPACE)
	var press := InputEventJoypadButton.new()
	press.device = 1
	press.button_index = JOY_BUTTON_Y
	press.pressed = true
	assert_bool(press.is_action(&"jump")).is_true()
	assert_bool(press.is_action(&"map_zoom_in")).is_true()
	for action: StringName in [&"jump", &"map_zoom_in"]:
		for event: InputEvent in InputMap.action_get_events(action):
			assert_int(event.device).override_failure_message("%s: %s" % [action, event]).is_equal(-1)
	Settings.reset_bindings(KeyBindings.Device.PAD)
	Settings.reset_bindings(KeyBindings.Device.KEYBOARD)
	var actions: Array[StringName] = KeyBindings.REBINDABLE.duplicate()
	actions.append_array(Settings.FOLLOWERS.keys())
	for action: StringName in actions:
		for event: InputEvent in InputMap.action_get_events(action):
			assert_int(event.device).override_failure_message("%s: %s" % [action, event]).is_equal(-1)

## bugs/closing-the-window-with-settings-open-forgets-the-changes: a window close commits. The disk is a temporary
## directory set on the private file, so no player's settings are touched.
func test_a_window_close_writes_what_changed() -> void:
	var dir := "user://settings_close_test"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := dir.path_join(SettingsFile.file_name(OS.is_debug_build()))
	Settings._file = SettingsFile.new(dir, OS.is_debug_build())
	Settings.set_volume(AudioBuses.MUSIC, 3)
	Settings.notification(NOTIFICATION_WM_CLOSE_REQUEST)
	var written := FileAccess.file_exists(path)
	var cfg := ConfigFile.new()
	cfg.load(path)
	Settings.use_memory_only()
	if written:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))
	assert_bool(written).is_true()
	assert_int(int(cfg.get_value("audio", "music", 0))).is_equal(3)
