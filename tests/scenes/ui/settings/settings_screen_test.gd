class_name SettingsScreenTest extends GdUnitTestSuite

## Focus on open, tabs and pages, value steps, accept on a list row, the capture flow through MenuInput's signals and
## the reset question.

const SCREEN := preload("res://scenes/ui/settings/settings_screen.tscn")

var _screen: SettingsScreen
var _menu_input: MenuInput


func before_test() -> void:
	_menu_input = auto_free(MenuInput.new()) as MenuInput
	add_child(_menu_input)
	_screen = auto_free(SCREEN.instantiate()) as SettingsScreen
	add_child(_screen)
	_screen.menu_input = _menu_input
	_screen.open()

func after_test() -> void:
	_screen.close()
	Settings.reset_bindings(KeyBindings.Device.KEYBOARD)
	Settings.reset_bindings(KeyBindings.Device.PAD)
	Settings.set_fullscreen(false)
	Settings.set_weather(GameSettings.WEATHER_STEPS)
	for bus: StringName in GameSettings.VOLUME_BUSES:
		Settings.set_volume(bus, SettingsMath.VOLUME_STEPS)

func _focused() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	return owner.name if owner != null else ""

func _row(page: String, row_name: String) -> Button:
	return _screen.find_child(page).get_node(row_name) as Button

func test_opening_focuses_the_sound_tab_on_the_sound_page() -> void:
	assert_str(_focused()).is_equal("SoundTab")
	assert_int(_screen.page()).is_equal(SettingsScreen.Page.SOUND)
	assert_bool((_screen.find_child("SoundPage") as Control).visible).is_true()
	assert_bool((_screen.find_child("PadPage") as Control).visible).is_false()

func test_focusing_a_tab_shows_its_page() -> void:
	(_screen.find_child("PadTab") as Button).grab_focus()
	assert_int(_screen.page()).is_equal(SettingsScreen.Page.PAD)
	assert_bool((_screen.find_child("PadPage") as Control).visible).is_true()
	assert_bool((_screen.find_child("SoundPage") as Control).visible).is_false()

func test_a_step_on_a_volume_row_changes_it_and_on_a_tab_it_is_refused() -> void:
	assert_bool(_screen.step(1)).is_false()
	_row("SoundPage", "SettingsVolumeMusic").grab_focus()
	assert_bool(_screen.step(-1)).is_true()
	assert_bool(_screen.step(-1)).is_true()
	assert_int(Settings.volume(AudioBuses.MUSIC)).is_equal(8)
	assert_bool(_screen.step(1)).is_true()
	assert_int(Settings.volume(AudioBuses.MUSIC)).is_equal(9)
	for i: int in 3:
		_screen.step(1)
	assert_int(Settings.volume(AudioBuses.MUSIC)).override_failure_message("a step clamps at 10").is_equal(10)

func test_the_weather_row_steps_and_shows_a_percentage() -> void:
	(_screen.find_child("GeneralTab") as Button).grab_focus()
	var row := _row("GeneralPage", "SettingsWeather") as SettingRow
	row.grab_focus()
	assert_bool(_screen.step(-1)).is_true()
	assert_bool(_screen.step(-1)).is_true()
	assert_int(Settings.weather()).is_equal(8)
	assert_str(row.value_text()).is_equal(tr("SETTINGS_PERCENT") % 80)
	row.pressed.emit()
	assert_int(Settings.weather()).override_failure_message("accept does not step it").is_equal(8)
	for i: int in 3:
		_screen.step(1)
	assert_int(Settings.weather()).override_failure_message("a step clamps at 10").is_equal(10)

func test_the_weather_row_follows_the_window_size() -> void:
	var window := _row("GeneralPage", "SettingsWindowSize")
	var weather := _row("GeneralPage", "SettingsWeather")
	(_screen.find_child("GeneralTab") as Button).grab_focus()
	assert_object(window.get_node(window.focus_neighbor_bottom)).is_same(weather)

func test_accept_toggles_fullscreen_and_greys_the_window_size() -> void:
	(_screen.find_child("GeneralTab") as Button).grab_focus()
	var window := _row("GeneralPage", "SettingsWindowSize")
	_row("GeneralPage", "SettingsFullscreen").pressed.emit()
	assert_bool(Settings.fullscreen()).is_true()
	assert_bool(window.disabled).is_true()
	assert_int(window.focus_mode).is_equal(Control.FOCUS_NONE)
	_row("GeneralPage", "SettingsFullscreen").pressed.emit()
	assert_bool(Settings.fullscreen()).is_false()
	assert_bool(window.disabled).is_false()

func test_the_first_row_goes_up_to_its_tab() -> void:
	var first := _row("SoundPage", "SettingsVolumeMaster")
	assert_object(first.get_node(first.focus_neighbor_top)).is_same(_screen.find_child("SoundTab"))
	var tab := _screen.find_child("SoundTab") as Button
	assert_object(tab.get_node(tab.focus_neighbor_bottom)).is_same(first)

func test_a_capture_assigns_and_ends() -> void:
	(_screen.find_child("KeyboardTab") as Button).grab_focus()
	var jump := _row("KeyboardPage", "Jump") as BindingRow
	jump.pressed.emit()
	assert_bool(_screen.is_capturing()).is_true()
	assert_bool(_menu_input.capturing).is_true()
	assert_str(jump.value_text()).is_equal(tr("SETTINGS_PRESS_KEY"))
	_menu_input.bind_pressed.emit(KeyBindings.Device.KEYBOARD, KEY_SPACE)
	assert_bool(_screen.is_capturing()).is_false()
	assert_bool(_menu_input.capturing).is_false()
	assert_str(jump.value_text()).is_equal(BindingNames.key_text(KEY_SPACE))

func test_a_refused_press_keeps_the_capture_open_and_says_why() -> void:
	(_screen.find_child("KeyboardTab") as Button).grab_focus()
	(_row("KeyboardPage", "Map")).pressed.emit()
	_menu_input.bind_pressed.emit(KeyBindings.Device.PAD, JOY_BUTTON_Y)
	assert_bool(_screen.is_capturing()).override_failure_message("a pad button is ignored on the keyboard page").is_true()
	_menu_input.bind_pressed.emit(KeyBindings.Device.KEYBOARD, KEY_Z)
	assert_bool(_screen.is_capturing()).is_true()
	assert_str(_screen.status()).is_equal(tr("SETTINGS_BIND_TAKEN") % tr("ACTION_JUMP"))
	_menu_input.bind_pressed.emit(KeyBindings.Device.KEYBOARD, KEY_ESCAPE)
	assert_str(_screen.status()).is_equal(tr("SETTINGS_BIND_RESERVED"))
	_menu_input.capture_cancelled.emit()
	assert_bool(_screen.is_capturing()).is_false()
	assert_int(Settings.bindings(KeyBindings.Device.KEYBOARD).code(&"map")).is_equal(KEY_M)

func test_a_swap_says_with_what() -> void:
	(_screen.find_child("PadTab") as Button).grab_focus()
	(_row("PadPage", "Jump")).pressed.emit()
	_menu_input.bind_pressed.emit(KeyBindings.Device.PAD, JOY_BUTTON_X)
	assert_str(_screen.status()).is_equal(tr("SETTINGS_BIND_SWAPPED") % tr("ACTION_ATTACK"))
	assert_str((_row("PadPage", "Attack") as BindingRow).value_text()).is_equal(tr("PAD_XBOX_A"))

func test_reset_asks_first_and_back_returns_to_it() -> void:
	(_screen.find_child("KeyboardTab") as Button).grab_focus()
	Settings.bind(KeyBindings.Device.KEYBOARD, &"attack", KEY_V)
	var reset := _row("KeyboardPage", "Reset")
	reset.pressed.emit()
	var confirm := _screen.find_child("ConfirmResetKeyboard") as ConfirmPanel
	assert_bool(confirm.visible).is_true()
	assert_bool((_screen.find_child("Sheet") as Control).visible).is_false()
	assert_str(_focused()).is_equal("No")
	assert_bool(_screen.step_back()).is_true()
	assert_bool(confirm.visible).is_false()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(reset)
	assert_int(Settings.bindings(KeyBindings.Device.KEYBOARD).code(&"attack")).is_equal(KEY_V)
	reset.pressed.emit()
	(confirm.find_child("Yes") as Button).pressed.emit()
	assert_int(Settings.bindings(KeyBindings.Device.KEYBOARD).code(&"attack")).is_equal(KEY_X)
	assert_int(Settings.bindings(KeyBindings.Device.PAD).code(&"attack")).is_equal(JOY_BUTTON_X)
	assert_bool(_screen.step_back()).is_false()

func test_close_ends_a_capture() -> void:
	(_screen.find_child("KeyboardTab") as Button).grab_focus()
	(_row("KeyboardPage", "Jump")).pressed.emit()
	_screen.close()
	assert_bool(_menu_input.capturing).is_false()
	assert_bool(_screen.visible).is_false()

## bugs/a-binding-refused-by-ui-accept-shows-the-raw-key-action-ui-accept: a fixed action is named, never its key.
func test_a_refusal_by_ui_accept_names_it() -> void:
	(_screen.find_child("KeyboardTab") as Button).grab_focus()
	(_row("KeyboardPage", "NoteUp")).pressed.emit()
	_menu_input.bind_pressed.emit(KeyBindings.Device.KEYBOARD, KEY_SPACE)
	assert_str(_screen.status()).is_equal(tr("SETTINGS_BIND_TAKEN") % tr("ACTION_UI_ACCEPT"))
	assert_str(_screen.status()).not_contains("ACTION_")

func test_cancelling_a_capture_and_leaving_a_row_clear_the_status() -> void:
	(_screen.find_child("KeyboardTab") as Button).grab_focus()
	var map := _row("KeyboardPage", "Map")
	map.grab_focus()
	map.pressed.emit()
	_menu_input.bind_pressed.emit(KeyBindings.Device.KEYBOARD, KEY_ESCAPE)
	assert_str(_screen.status()).is_not_empty()
	_menu_input.capture_cancelled.emit()
	assert_str(_screen.status()).is_empty()
	(_screen.find_child("PadTab") as Button).grab_focus()
	var jump := _row("PadPage", "Jump")
	jump.grab_focus()
	jump.pressed.emit()
	_menu_input.bind_pressed.emit(KeyBindings.Device.PAD, JOY_BUTTON_X)
	assert_str(_screen.status()).is_not_empty()
	_row("PadPage", "Attack").grab_focus()
	assert_str(_screen.status()).is_empty()

## The shown page's tab keeps the Selected look while a row has the focus.
func test_the_shown_pages_tab_stays_selected() -> void:
	(_screen.find_child("GeneralTab") as Button).grab_focus()
	_row("GeneralPage", "SettingsLanguage").grab_focus()
	var general := _screen.find_child("GeneralTab") as Button
	assert_str(String(general.theme_type_variation)).is_equal(String(MenuEntry.FOCUSED_VARIATION))
	for other: String in ["SoundTab", "KeyboardTab", "PadTab"]:
		assert_str(String((_screen.find_child(other) as Button).theme_type_variation)).is_empty()

## bugs/settings-rows-measure-12-px-so-reset-to-defaults-sits-on-the-status-line, measured after layout.
func test_the_last_row_ends_above_the_status_line_in_every_language() -> void:
	var locale := TranslationServer.get_locale()
	var status := _screen.find_child("Status") as Control
	for language: String in ["en", "pt_BR"]:
		TranslationServer.set_locale(language)
		for page: String in ["KeyboardPage", "PadPage", "SoundPage", "GeneralPage"]:
			var rows := _screen.find_child(page) as Control
			rows.show()
			await await_idle_frame()
			var last := rows.get_child(rows.get_child_count() - 1) as Control
			assert_float(last.size.y).override_failure_message("%s row height" % page).is_equal(SettingRow.HEIGHT)
			var bottom := rows.position.y + last.position.y + last.size.y
			assert_float(bottom).override_failure_message("[%s] %s ends at %.0f" % [language, page, bottom]) \
					.is_less_equal(status.position.y)
	TranslationServer.set_locale(locale)

## The title's theme already plays on the Music bus, so its Settings plays no Music sample (orchestrator, 2026-11-10).
func test_without_a_music_preview_a_music_step_plays_nothing() -> void:
	_screen.music_preview = false
	_row("SoundPage", "SettingsVolumeMusic").grab_focus()
	_screen.step(-1)
	assert_bool((_screen.find_child("MusicPreview") as AudioStreamPlayer).playing).is_false()
