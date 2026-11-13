class_name EngravingCaptionFitTest extends GdUnitTestSuite

## Every bearer caption, alone and as each shipped frame shows it, is at most two lines inside the Caption box in every
## language of the CSV (architecture/story-04-bearer-fragments, "i18n"). Measured with the view's own label and font.

const VIEW := preload("res://scenes/ui/engraving/engraving_view.tscn")
const CATALOG := preload("res://resources/story/bearers/bearer_catalog.tres")
const BASE := preload("res://assets/sprites/story/bearers/frost/frame_1_base.png")
const CSV := "res://i18n/translations.csv"
const FRAMES_PER_FRAGMENT := 4
const MAX_LINES := 2

var _view: EngravingView
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_view = auto_free(VIEW.instantiate()) as EngravingView
	add_child(_view)

## The locales in the CSV header, after the key column.
func _locales() -> PackedStringArray:
	var file := FileAccess.open(CSV, FileAccess.READ)
	return file.get_csv_line().slice(1)

## BEARER_<GUARDIAN>_<N> for every guardian and frame.
func _caption_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for guardian: String in Enums.Guardian.keys():
		for n: int in range(1, FRAMES_PER_FRAGMENT + 1):
			keys.append(StringName("BEARER_%s_%d" % [guardian, n]))
	return keys

## Each key alone, then each shipped frame's captions as it shows them together.
func _caption_sets() -> Array[Array]:
	var sets: Array[Array] = []
	for key: StringName in _caption_keys():
		sets.append([key])
	for fragment: BearerFragment in CATALOG.fragments:
		for leaf: CutsceneStep in CutsceneCatalog.leaves(fragment.engraving.steps):
			if leaf is CutsceneEngraving:
				sets.append((leaf as CutsceneEngraving).frame.captions)
	return sets

func _frame(captions: Array) -> EngravingFrame:
	var layer := EngravingLayer.new()
	layer.texture = BASE
	var frame := EngravingFrame.new()
	frame.layers = [layer]
	frame.captions.assign(captions)
	return frame

func test_every_shipped_caption_is_a_bearer_key() -> void:
	var keys := _caption_keys()
	for captions: Array in _caption_sets():
		for key: StringName in captions:
			assert_bool(keys.has(key)).override_failure_message("%s is not a bearer caption key" % key).is_true()

func test_every_caption_fits_its_box_in_every_language() -> void:
	var label := _view.caption_label()
	var font := label.get_theme_font(&"font")
	var font_size := label.get_theme_font_size(&"font_size")
	var locales := _locales()
	assert_int(locales.size()).is_greater_equal(2)
	for locale: String in locales:
		TranslationServer.set_locale(locale)
		for captions: Array in _caption_sets():
			_view.show_frame(_frame(captions), Color.WHITE, false)
			await await_idle_frame()
			var what := "[%s] %s" % [locale, ", ".join(captions)]
			for key: StringName in captions:
				assert_str(tr(key)).override_failure_message("%s: %s has no row" % [what, key]).is_not_equal(String(key))
			for word: String in label.text.replace("\n", " ").split(" ", false):
				var width := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				assert_float(width).override_failure_message("%s: '%s' is wider than the box" % [what, word]) \
						.is_less_equal(label.size.x)
			var lines := label.get_line_count()
			assert_int(lines).override_failure_message("%s: %d lines" % [what, lines]).is_less_equal(MAX_LINES)
			var needed := lines * label.get_line_height() + maxi(lines - 1, 0) * label.get_theme_constant(&"line_spacing")
			assert_float(label.size.y).override_failure_message("%s: %d lines need %d px, the box has %.0f" % [
					what, lines, needed, label.size.y]).is_greater_equal(needed)
