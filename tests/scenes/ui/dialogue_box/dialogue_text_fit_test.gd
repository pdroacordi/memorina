class_name DialogueTextFitTest extends GdUnitTestSuite

## Every dialogue text fits the box in every language of the CSV: a line in TEXT_ROWS, a question in QUESTION_ROWS, a
## choice in one row, a name in the plate; every key is filled and translated. Measured with the box's own Labels at
## their fixed width, never by container sorts (gotchas/autowrapped-rows-settle-over-several-sorts).

const BOX := preload("res://scenes/ui/dialogue_box/dialogue_box.tscn")
const CATALOG := "res://resources/dialogue/dialogue_catalog.tres"
const SPEAKERS := "res://resources/dialogue/speakers"
const CSV := "res://i18n/translations.csv"

var _box: DialogueBox
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_box = auto_free(BOX.instantiate()) as DialogueBox
	add_child(_box)

## The locales in the CSV header, after the key column.
func _locales() -> PackedStringArray:
	var file := FileAccess.open(CSV, FileAccess.READ)
	return file.get_csv_line().slice(1)

## Every speaker file, plus every speaker a catalog line names.
func _speakers(catalog: DialogueCatalog) -> Array[Speaker]:
	var found: Array[Speaker] = []
	for file: String in DirAccess.get_files_at(SPEAKERS):
		if file.get_extension() == "tres":
			found.append(load(SPEAKERS.path_join(file)) as Speaker)
	for line: DialogueLine in catalog.lines():
		if line.speaker != null and not found.has(line.speaker):
			found.append(line.speaker)
	return found

func _assert_translated(key: String, text: String, locale: String) -> void:
	assert_str(text).override_failure_message("[%s] %s has no text" % [locale, key]).is_not_empty()
	assert_str(text).override_failure_message("[%s] %s has no row" % [locale, key]).is_not_equal(key)

func test_the_box_has_its_fixed_widths() -> void:
	assert_float(_box.text_label().size.x).is_equal(230.0)
	assert_float(_box.choice_button(0).custom_minimum_size.x).is_equal(230.0)

func test_every_line_fits_its_rows_in_every_language() -> void:
	var catalog := load(CATALOG) as DialogueCatalog
	var label := _box.text_label()
	var locales := _locales()
	assert_int(locales.size()).is_greater_equal(2)
	for locale: String in locales:
		TranslationServer.set_locale(locale)
		for line: DialogueLine in catalog.lines():
			if line.text_key.is_empty():
				continue
			var rows := DialogueBox.QUESTION_ROWS if line.asks() else DialogueBox.TEXT_ROWS
			var keys: Array[String] = [line.text_key]
			for variant: LineVariant in line.variants:
				keys.append(variant.text_key)
			for key: String in keys:
				_box.show_line(line.speaker, key)
				_assert_translated(key, label.text, locale)
				assert_int(label.get_line_count()).override_failure_message("[%s] %s takes %d rows, it has %d" % [
						locale, key, label.get_line_count(), rows]).is_less_equal(rows)

func test_every_choice_fits_one_row_in_every_language() -> void:
	var catalog := load(CATALOG) as DialogueCatalog
	var button := _box.choice_button(0)
	for locale: String in _locales():
		TranslationServer.set_locale(locale)
		for answer: DialogueChoice in catalog.choices():
			var text := tr(answer.text_key)
			_assert_translated(answer.text_key, text, locale)
			button.text = text
			var needed := button.get_minimum_size().x
			assert_float(needed).override_failure_message("[%s] %s is %.0f px in a %.0f px row" % [
					locale, answer.text_key, needed, button.custom_minimum_size.x]).is_less_equal(button.custom_minimum_size.x)

func test_every_name_fits_the_plate_in_every_language() -> void:
	var catalog := load(CATALOG) as DialogueCatalog
	for locale: String in _locales():
		TranslationServer.set_locale(locale)
		for speaker: Speaker in _speakers(catalog):
			if speaker.name_key.is_empty():
				continue
			var text := tr(speaker.name_key)
			_assert_translated(speaker.name_key, text, locale)
			var width := _box.plate_width(text)
			assert_float(width).override_failure_message("[%s] %s needs a %.0f px plate, at most %.0f" % [
					locale, speaker.name_key, width, DialogueBox.PLATE_MAX_WIDTH]).is_less_equal(DialogueBox.PLATE_MAX_WIDTH)
