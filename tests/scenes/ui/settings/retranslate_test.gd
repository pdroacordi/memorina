class_name RetranslateTest extends GdUnitTestSuite

## A language change rewrites the open pause menu, its Settings and the title without reopening them
## (systems/settings, live language).

const SCREENS := preload("res://scenes/ui/screens/screens.tscn")
const TITLE := preload("res://scenes/ui/title/title.tscn")

var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()
	SaveSystem.use_memory_only()

func after_test() -> void:
	TranslationServer.set_locale("en")
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()

func after() -> void:
	TranslationServer.set_locale(_locale)

func test_the_open_pause_menu_and_its_settings_change_language_at_once() -> void:
	TranslationServer.set_locale("en")
	var screens := auto_free(SCREENS.instantiate()) as Screens
	add_child(screens)
	var menu_input := screens.get_node("MenuInput") as MenuInput
	menu_input.pause_pressed.emit()
	var resume := screens.find_child("Resume") as Button
	var settings := screens.find_child("Settings") as Button
	settings.pressed.emit()
	var tab := screens.find_child("SoundTab") as Button
	var body := screens.find_child("ConfirmQuit").find_child("Body") as Label
	assert_str(resume.text).is_equal("Resume")
	TranslationServer.set_locale("pt_BR")
	assert_str(resume.text).is_equal(tr("PAUSE_RESUME"))
	assert_str(resume.text).is_not_equal("Resume")
	assert_str(settings.text).is_equal("Opções")
	assert_str(tab.text).is_equal(tr("SETTINGS_TAB_SOUND"))
	assert_str(body.text).is_equal(tr("CONFIRM_QUIT_GAME"))
	var master := screens.find_child("SettingsVolumeMaster", true, false) as Button
	assert_str(master.text).is_equal(tr("SETTINGS_VOLUME_MASTER"))

func test_the_title_changes_language_at_once() -> void:
	TranslationServer.set_locale("en")
	var title := auto_free(TITLE.instantiate()) as Title
	add_child(title)
	TranslationServer.set_locale("pt_BR")
	assert_str((title.find_child("NewGame") as Button).text).is_equal("Novo jogo")
	assert_str((title.find_child("Settings") as Button).text).is_equal("Opções")

## Settings.set_language is the one runtime writer; the language row cycles through it.
func test_the_language_row_sets_the_locale() -> void:
	TranslationServer.set_locale("en")
	var screens := auto_free(SCREENS.instantiate()) as Screens
	add_child(screens)
	(screens.get_node("MenuInput") as MenuInput).pause_pressed.emit()
	(screens.find_child("Settings") as Button).pressed.emit()
	(screens.find_child("GeneralTab") as Button).grab_focus()
	var row := screens.find_child("SettingsLanguage", true, false) as SettingRow
	row.pressed.emit()
	assert_str(TranslationServer.get_locale()).is_equal("pt_BR")
	assert_str(row.value_text()).is_equal("Português (Brasil)")
	assert_str(row.text).is_equal("Idioma")
	row.pressed.emit()
	assert_str(TranslationServer.get_locale()).is_equal("en")
