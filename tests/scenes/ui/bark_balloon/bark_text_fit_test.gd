class_name BarkTextFitTest extends GdUnitTestSuite

## Every guardian bark fits the balloon's rows in every language of the CSV and is translated (systems/guardians,
## "Talks"). Measured with the balloon's own Label at its fixed width.

const BALLOON := preload("res://scenes/ui/bark_balloon/bark_balloon.tscn")
const STATS_DIR := "res://resources/characters/guardians"
const CSV := "res://i18n/translations.csv"

var _balloon: BarkBalloon
var _anchor: Node2D
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_balloon = auto_free(BALLOON.instantiate()) as BarkBalloon
	add_child(_balloon)
	_anchor = auto_free(Node2D.new()) as Node2D
	add_child(_anchor)

static func voices() -> Array[GuardianVoice]:
	var found: Array[GuardianVoice] = []
	for dir: String in DirAccess.get_directories_at(STATS_DIR):
		for file: String in DirAccess.get_files_at(STATS_DIR.path_join(dir)):
			if not file.ends_with("_stats.tres"):
				continue
			var stats := load(STATS_DIR.path_join(dir).path_join(file)) as GuardianStats
			if stats != null and stats.voice != null:
				found.append(stats.voice)
	return found

func _locales() -> PackedStringArray:
	var file := FileAccess.open(CSV, FileAccess.READ)
	return file.get_csv_line().slice(1)

func test_every_bark_fits_its_rows_in_every_language() -> void:
	var all := voices()
	assert_int(all.size()).is_greater_equal(2)
	for locale: String in _locales():
		TranslationServer.set_locale(locale)
		for voice: GuardianVoice in all:
			var keys: Array[String] = voice.lucid_barks.duplicate()
			keys.append(voice.retry_bark)
			for key: String in keys:
				_balloon.say(_anchor, key, 1)
				var text := _balloon.text_label().text
				assert_str(text).override_failure_message("[%s] %s has no text" % [locale, key]).is_not_empty()
				assert_str(text).override_failure_message("[%s] %s has no row" % [locale, key]).is_not_equal(key)
				var rows := _balloon.text_label().get_line_count()
				assert_int(rows).override_failure_message("[%s] %s takes %d rows, it has %d" % [
						locale, key, rows, BarkBalloon.MAX_ROWS]).is_less_equal(BarkBalloon.MAX_ROWS)
