class_name GameSettingsTest extends GdUnitTestSuite

## Defaults, clamping on load, the language left to the OS until picked, a round trip, and only changed bindings
## written; a table the rules refuse drops that device's overrides.

var _defaults: GameSettings


func before_test() -> void:
	_defaults = GameSettings.new(
			KeyBindings.from_input_map(KeyBindings.Device.KEYBOARD), KeyBindings.from_input_map(KeyBindings.Device.PAD))

func test_the_defaults() -> void:
	var made := GameSettings.from_config(null, _defaults)
	for bus: StringName in GameSettings.VOLUME_BUSES:
		assert_int(made.volumes[bus]).is_equal(10)
	assert_bool(made.fullscreen).is_false()
	assert_int(made.window_scale).is_equal(2)
	assert_str(made.language).is_empty()
	assert_int(made.weather).is_equal(10)

func test_values_out_of_range_clamp_or_fall_back() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", 14)
	cfg.set_value("audio", "music", -2)
	cfg.set_value("audio", "notes", "loud")
	cfg.set_value("display", "window_scale", 5)
	cfg.set_value("general", "language", "fr")
	cfg.set_value("general", "weather", 12)
	var made := GameSettings.from_config(cfg, _defaults)
	assert_int(made.volumes[AudioBuses.MASTER]).is_equal(10)
	assert_int(made.volumes[AudioBuses.MUSIC]).is_equal(0)
	assert_int(made.volumes[AudioBuses.NOTES]).is_equal(10)
	assert_int(made.window_scale).is_equal(GameSettings.DEFAULT_SCALE)
	assert_str(made.language).is_empty()
	assert_int(made.weather).is_equal(10)
	cfg.set_value("general", "weather", -3)
	assert_int(GameSettings.from_config(cfg, _defaults).weather).is_equal(0)
	cfg.set_value("general", "weather", "strong")
	assert_int(GameSettings.from_config(cfg, _defaults).weather).is_equal(10)

func test_a_round_trip_keeps_every_value() -> void:
	var made := _defaults.copy()
	made.volumes[AudioBuses.SFX] = 3
	made.fullscreen = true
	made.window_scale = 1
	made.language = "pt_BR"
	made.weather = 4
	made.keyboard.codes[&"jump"] = KEY_SPACE
	made.pad.codes[&"roll"] = JOY_BUTTON_LEFT_STICK
	var cfg := ConfigFile.new()
	made.to_config(cfg, _defaults)
	var back := GameSettings.from_config(cfg, _defaults)
	assert_int(back.volumes[AudioBuses.SFX]).is_equal(3)
	assert_bool(back.fullscreen).is_true()
	assert_int(back.window_scale).is_equal(1)
	assert_str(back.language).is_equal("pt_BR")
	assert_int(back.weather).is_equal(4)
	assert_int(back.keyboard.code(&"jump")).is_equal(KEY_SPACE)
	assert_int(back.pad.code(&"roll")).is_equal(JOY_BUTTON_LEFT_STICK)

func test_an_unpicked_language_and_default_bindings_are_not_written() -> void:
	var made := _defaults.copy()
	made.keyboard.codes[&"map"] = KEY_TAB
	var cfg := ConfigFile.new()
	made.to_config(cfg, _defaults)
	assert_bool(cfg.has_section_key("general", "language")).is_false()
	assert_array(Array(cfg.get_section_keys("keyboard"))).contains_exactly(["map"])
	assert_bool(cfg.has_section("pad")).is_false()

func test_an_invalid_table_drops_that_devices_overrides_only() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("keyboard", "map", KEY_E)
	cfg.set_value("keyboard", "jump", KEY_SPACE)
	cfg.set_value("pad", "roll", JOY_BUTTON_LEFT_STICK)
	var made := GameSettings.from_config(cfg, _defaults)
	assert_bool(made.keyboard.equals(_defaults.keyboard)).is_true()
	assert_int(made.pad.code(&"roll")).is_equal(JOY_BUTTON_LEFT_STICK)

## bugs/a-hand-edited-keyboard-code-of-0-silently-unbinds-the-action: a code that names no key drops the overrides.
func test_a_keyboard_code_that_is_no_key_drops_the_keyboard_overrides() -> void:
	for bad: int in [0, -5, 1 << 30]:
		var cfg := ConfigFile.new()
		cfg.set_value("keyboard", "jump", bad)
		var made := GameSettings.from_config(cfg, _defaults)
		assert_int(made.keyboard.code(&"jump")).override_failure_message(str(bad)).is_equal(KEY_Z)
