class_name SettingsTextFitTest extends GdUnitTestSuite

## Every Settings text fits its box in every shipped language, measured in the menu theme's 8 px font (systems/settings).

const THEME := preload("res://scenes/ui/menu/menu_theme.tres")
const LOCALES: Array[String] = ["en", "pt_BR"]
## Pack px of each box, less the buttons' 4 px content margins.
const ENTRY := 64.0
const TAB := 56.0
const SETTING_NAME := SettingRow.VALUE_LEFT - 4.0
const SETTING_VALUE := 272.0 - SettingRow.VALUE_LEFT - 4.0
const PERCENT_VALUE := 272.0 - SettingRow.PERCENT_LEFT - 4.0
const BINDING_NAME := BindingRow.VALUE_LEFT - 4.0
const BINDING_VALUE := 272.0 - BindingRow.VALUE_LEFT - 4.0
const STATUS := 272.0
const CONFIRM_BODY := Vector2(108, 30)

var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func _width(text: String) -> float:
	return THEME.default_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, THEME.default_font_size).x

func _fits(key: String, text: String, room: float, locale: String) -> void:
	assert_str(tr(key)).override_failure_message("[%s] %s is not translated" % [locale, key]).is_not_equal(key)
	var width := _width(text)
	assert_float(width).override_failure_message("[%s] %s is %.0f px, the box holds %.0f" % [locale, key, width, room]) \
			.is_less_equal(room)

func test_every_settings_text_fits_its_box() -> void:
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for key: String in ["PAUSE_SETTINGS", "TITLE_SETTINGS"]:
			_fits(key, tr(key), ENTRY, locale)
		for key: String in SettingsScreen.TAB_KEYS.values():
			_fits(key, tr(key), TAB, locale)
		var names: Array[String] = ["SETTINGS_LANGUAGE", "SETTINGS_FULLSCREEN", "SETTINGS_WINDOW_SIZE", "SETTINGS_WEATHER"]
		names.append_array(SettingsScreen.VOLUME_KEYS.values())
		for key: String in names:
			_fits(key, tr(key), SETTING_NAME, locale)
		for key: String in ["SETTINGS_ON", "SETTINGS_OFF", "LANGUAGE_EN", "LANGUAGE_PT_BR"]:
			_fits(key, "< %s >" % tr(key), SETTING_VALUE, locale)
		_fits("SETTINGS_PERCENT", "< %s >" % (tr("SETTINGS_PERCENT") % 100), PERCENT_VALUE, locale)
		_fits("SETTINGS_WINDOW_SCALE", "< %s >" % (tr("SETTINGS_WINDOW_SCALE") % [3, 1920, 1080]), SETTING_VALUE, locale)
		for action: StringName in KeyBindings.REBINDABLE:
			var key := BindingRow.action_key(action)
			_fits(key, tr(key), BINDING_NAME, locale)
			_fits(key, tr("SETTINGS_BIND_SWAPPED") % tr(key), STATUS, locale)
		# Every action the status line can name: a refusal may name a fixed holder.
		for action: StringName in BindingRules.GROUPS:
			var key := BindingRow.action_key(action)
			_fits(key, tr("SETTINGS_BIND_TAKEN") % tr(key), STATUS, locale)
		_fits(SettingsScreen.RESET_KEY, tr(SettingsScreen.RESET_KEY), BINDING_NAME, locale)
		for key: String in ["SETTINGS_PRESS_KEY", "SETTINGS_PRESS_BUTTON"]:
			_fits(key, tr(key), BINDING_VALUE, locale)
		_fits("SETTINGS_BIND_RESERVED", tr("SETTINGS_BIND_RESERVED"), STATUS, locale)
		for family: Dictionary[int, String] in [BindingNames.XBOX_KEYS, BindingNames.PLAYSTATION_KEYS]:
			for key: String in family.values():
				_fits(key, tr(key), BINDING_VALUE, locale)

## The weather row's bar starts at VALUE_LEFT and ends before its percentage's box.
func test_the_weather_bar_ends_before_its_percentage() -> void:
	assert_float(SettingRow.VALUE_LEFT + StepBar.width()).is_less_equal(SettingRow.PERCENT_LEFT)

func test_every_reset_question_fits_its_panel() -> void:
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for key: String in ["CONFIRM_RESET_KEYBOARD", "CONFIRM_RESET_PAD"]:
			var size := THEME.default_font.get_multiline_string_size(tr(key), HORIZONTAL_ALIGNMENT_CENTER, CONFIRM_BODY.x,
					THEME.default_font_size, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND)
			assert_float(size.x).override_failure_message("[%s] %s is %.0f px wide" % [locale, key, size.x]) \
					.is_less_equal(CONFIRM_BODY.x)
			assert_float(size.y).override_failure_message("[%s] %s is %.0f px tall" % [locale, key, size.y]) \
					.is_less_equal(CONFIRM_BODY.y)
