class_name EngravingCaptionFitTest extends GdUnitTestSuite

## Every bearer and final fragment caption, alone and as each shipped frame shows it (together, or one turn at a time), is
## at most two lines inside the Caption box in every language of the CSV (architecture/story-04-bearer-fragments and
## story42-the-final-fragment, "i18n"). Measured with the view's own label and font.

const VIEW := preload("res://scenes/ui/engraving/engraving_view.tscn")
const CATALOG := preload("res://resources/story/bearers/bearer_catalog.tres")
const FINAL_FRAGMENT := preload("res://resources/cutscene/story/final_fragment.tres")
## Caption turns per final fragment panel (architecture/story42-the-final-fragment, "The scene").
const FINAL_TURNS: Array[int] = [2, 2, 2, 1, 2, 1, 3]
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

## BEARER_<GUARDIAN>_<N> for every guardian and frame, then FINAL_FRAGMENT_<PANEL>_<TURN>.
func _caption_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for guardian: String in Enums.Guardian.keys():
		for n: int in range(1, FRAMES_PER_FRAGMENT + 1):
			keys.append(StringName("BEARER_%s_%d" % [guardian, n]))
	for panel: int in FINAL_TURNS.size():
		for turn: int in range(1, FINAL_TURNS[panel] + 1):
			keys.append(StringName("FINAL_FRAGMENT_%d_%d" % [panel + 1, turn]))
	return keys

func _engravings() -> Array[CutsceneEngraving]:
	var found: Array[CutsceneEngraving] = []
	var scenes: Array[Cutscene] = [FINAL_FRAGMENT]
	for fragment: BearerFragment in CATALOG.fragments:
		scenes.append(fragment.engraving)
	for scene: Cutscene in scenes:
		for leaf: CutsceneStep in CutsceneCatalog.leaves(scene.steps):
			if leaf is CutsceneEngraving:
				found.append(leaf as CutsceneEngraving)
	return found

## Each key alone, then each shipped frame's captions as it shows them: together, or one turn at a time.
func _caption_sets() -> Array[Array]:
	var sets: Array[Array] = []
	for key: StringName in _caption_keys():
		sets.append([key])
	for engraving: CutsceneEngraving in _engravings():
		if engraving.frame.caption_turns:
			for key: StringName in engraving.frame.captions:
				sets.append([key])
		else:
			sets.append(engraving.frame.captions)
	return sets

func _frame(captions: Array) -> EngravingFrame:
	var layer := EngravingLayer.new()
	layer.texture = BASE
	var frame := EngravingFrame.new()
	frame.layers = [layer]
	frame.captions.assign(captions)
	return frame

func test_every_shipped_caption_is_a_fragment_key() -> void:
	var keys := _caption_keys()
	for captions: Array in _caption_sets():
		for key: StringName in captions:
			assert_bool(keys.has(key)).override_failure_message("%s is not a fragment caption key" % key).is_true()

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
