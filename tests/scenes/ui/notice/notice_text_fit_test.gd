class_name NoticeTextFitTest extends GdUnitTestSuite

## Every item name and intent fits the notice's one line, and every intent fits the pause menu's line, in every shipped
## language, measured with the labels' own fonts (systems/notices).

const TOAST := preload("res://scenes/ui/notice/notice_toast.tscn")
const PAUSE := preload("res://scenes/ui/pause_menu/pause_menu.tscn")
const NOTEBOOK := preload("res://resources/ui/notebook/notebook_catalog.tres")
const INTENTS := preload("res://resources/story/intent_catalog.tres")
const LOCALES: Array[String] = ["en", "pt_BR"]

var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func _keys() -> Array[String]:
	var keys: Array[String] = []
	for entry: NotebookEntry in NOTEBOOK.in_section(NotebookEntry.Section.ITEMS):
		keys.append(entry.title_key)
	for intent: Intent in INTENTS.intents:
		keys.append(intent.text_key)
	return keys

func _width(label: Label, text: String) -> float:
	var font := label.get_theme_font(&"font")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size(&"font_size")).x

func test_every_notice_fits_its_line() -> void:
	var toast := auto_free(TOAST.instantiate()) as NoticeToast
	add_child(toast)
	var label := toast.find_child("Text") as Label
	var row := toast.find_child("Row") as HBoxContainer
	var icon := toast.find_child("Icon") as Control
	var room := row.size.x - icon.custom_minimum_size.x - row.get_theme_constant(&"separation")
	assert_float(NoticeToast.TEXT_WIDTH).is_less_equal(room)
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for key: String in _keys():
			var text := tr(key)
			assert_str(text).override_failure_message("[%s] %s is not translated" % [locale, key]).is_not_equal(key)
			var width := _width(label, text)
			assert_float(width).override_failure_message(
					"[%s] %s is %.0f art px, the line holds %.0f" % [locale, key, width, NoticeToast.TEXT_WIDTH]
					).is_less_equal(NoticeToast.TEXT_WIDTH)

func test_every_intent_fits_the_pause_menus_line() -> void:
	var menu := auto_free(PAUSE.instantiate()) as PauseMenu
	add_child(menu)
	var label := menu.find_child("Intent") as Label
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for intent: Intent in INTENTS.intents:
			var width := _width(label, tr(intent.text_key))
			assert_float(width).override_failure_message(
					"[%s] %s is %.0f art px in a %.0f px line" % [locale, intent.text_key, width, label.size.x]
					).is_less_equal(label.size.x)

## The line stays on screen with "Skip scene" shown, the tallest the box gets.
func test_the_pause_menus_line_stays_on_screen() -> void:
	var menu := auto_free(PAUSE.instantiate()) as PauseMenu
	add_child(menu)
	menu.can_skip = func() -> bool: return true
	menu.intent = func() -> String: return "INTENT_ELDER"
	menu.open()
	var label := menu.find_child("Intent") as Label
	assert_float(label.offset_bottom).is_less_equal((menu.find_child("Art") as Control).size.y)
