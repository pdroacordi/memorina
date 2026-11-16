class_name CreditsTextFitTest extends GdUnitTestSuite

## The shipped credits (architecture/story-07-epilogue, decisions 9 and 12): every key is a CREDITS_* row filled in every
## language of the CSV, every heading stands on one line, every word of every row fits the column and every glyph is in
## its font; the names never translate, and the engine's licence notice closes the roll. Measured in the roll itself.

const ROLL := preload("res://scenes/ui/credits/credits_roll.tscn")
const SHEET := preload("res://resources/story/credits/credits.tres")
const SCENE := preload("res://resources/cutscene/story/credits.tres")
const CSV := "res://i18n/translations.csv"
const PREFIX := "CREDITS_"

var _roll: CreditsRoll
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_roll = auto_free(ROLL.instantiate()) as CreditsRoll
	add_child(_roll)

## The locales in the CSV header, after the key column.
func _locales() -> PackedStringArray:
	var file := FileAccess.open(CSV, FileAccess.READ)
	return file.get_csv_line().slice(1)

func _csv_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var file := FileAccess.open(CSV, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if not row.is_empty() and row[0].begins_with(PREFIX):
			keys.append(row[0])
	return keys

func _sheet_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for section: CreditsSection in SHEET.sections:
		if not section.heading_key.is_empty():
			keys.append(String(section.heading_key))
		for entry: CreditsEntry in section.entries:
			if not entry.role_key.is_empty():
				keys.append(String(entry.role_key))
	return keys

## Every untranslated row the sheet shows, top to bottom.
func _sheet_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for section: CreditsSection in SHEET.sections:
		for entry: CreditsEntry in section.entries:
			lines.append_array(entry.lines())
	return lines

func _labels() -> Array[Label]:
	var found: Array[Label] = []
	for row: Control in _roll.rows():
		if row is Label:
			found.append(row as Label)
	return found

func test_the_scene_rolls_the_shipped_sheet() -> void:
	var rolls := 0
	for leaf: CutsceneStep in CutsceneCatalog.leaves(SCENE.steps):
		if leaf is CutsceneCredits:
			rolls += 1
			assert_object((leaf as CutsceneCredits).sheet).is_same(SHEET)
	assert_int(rolls).is_equal(1)

func test_the_sheet_and_the_csv_hold_the_same_credits_keys() -> void:
	var used := _sheet_keys()
	for key: String in used:
		assert_str(key).override_failure_message("%s is not a credits key" % key).starts_with(PREFIX)
	for key: String in _csv_keys():
		assert_bool(used.has(key)).override_failure_message("%s is in the CSV but not in the sheet" % key).is_true()

## Decision 12: "Made with Godot Engine" and the engine's notice, read from the engine, end the roll before the logo.
func test_the_roll_ends_on_the_engines_licence() -> void:
	var last := SHEET.sections[-1]
	assert_bool(last.entries[-1] is CreditsLicence).is_true()
	assert_str(String(last.entries[0].role_key)).is_equal("CREDITS_MADE_WITH_GODOT")
	var notice := " ".join(last.entries[-1].lines())
	assert_str(notice).contains("Godot Engine contributors")
	assert_str(notice).contains("Permission is hereby granted")
	assert_str(notice.replace(" ", "")).is_equal(Engine.get_license_text().strip_edges().replace(" ", "")
			.replace("\n", ""))

func test_every_row_fits_the_column_in_every_language() -> void:
	var locales := _locales()
	assert_int(locales.size()).is_greater_equal(2)
	var column := (_roll.get_node("Art/Column") as Control).custom_minimum_size.x
	for locale: String in locales:
		TranslationServer.set_locale(locale)
		_roll.roll(SHEET)
		for i: int in 4:
			await get_tree().process_frame
		var shown := PackedStringArray()
		for label: Label in _labels():
			var font := label.get_theme_font(&"font")
			var font_size := label.get_theme_font_size(&"font_size")
			var what := "[%s] '%s'" % [locale, label.text]
			assert_str(label.text).override_failure_message("[%s] an empty row" % locale).is_not_empty()
			assert_bool(label.text.begins_with(PREFIX)).override_failure_message("%s has no row" % what).is_false()
			for c: String in label.text:
				assert_bool(font.has_char(c.unicode_at(0))).override_failure_message("%s: '%s' is not in its font" % [
						what, c]).is_true()
			for word: String in label.text.split(" ", false):
				var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				assert_float(width).override_failure_message("%s: '%s' is %.0f px in a %.0f px column" % [
						what, word, width, column]).is_less_equal(column)
			if font_size == CreditsRoll.HEADING_SIZE:
				var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				assert_float(width).override_failure_message("%s: a heading of %.0f px in a %.0f px column" % [
						what, width, column]).is_less_equal(column)
				assert_int(label.get_line_count()).override_failure_message("%s wraps" % what).is_equal(1)
			else:
				shown.append(label.text)
		for line: String in _sheet_lines():
			assert_bool(shown.has(line)).override_failure_message("[%s] '%s' is not shown as written" % [locale, line]) \
					.is_true()
