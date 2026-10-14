class_name RegionTitleFitTest extends GdUnitTestSuite

## Every region title that can play has a filled name and epithet that fit the title's box, in every language of the CSV.
## Measured with the title's own labels and fonts.

const GAME := "res://scenes/world/game.tscn"
const VILLAGE := "res://scenes/world/rooms/home_village.tscn"
const CSV := "res://i18n/translations.csv"
const TITLE := preload("res://scenes/ui/region_title/region_title.tscn")

var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

## The locales in the CSV header, after the key column.
func _locales() -> PackedStringArray:
	var file := FileAccess.open(CSV, FileAccess.READ)
	var header := file.get_csv_line()
	return header.slice(1)

## A property the scene file sets on its root, else `fallback` (gotchas/scene-state-lists-only-the-properties-a-scene-file-sets).
func _root_property(state: SceneState, property: StringName, fallback: Variant) -> Variant:
	for i: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == property:
			return state.get_node_property_value(0, i)
	return fallback

## [name_key, epithet_key] of every region placed in the game whose title can play.
func _titled_regions() -> Array[PackedStringArray]:
	var game := (load(GAME) as PackedScene).get_state()
	var regions: Array[PackedStringArray] = []
	for node: int in game.get_node_count():
		var placed := game.get_node_instance(node)
		if placed == null:
			continue
		var state := placed.get_state()
		var script := _root_property(state, &"script", null) as Script
		if script == null or script.get_global_name() != &"Region":
			continue
		if not bool(_root_property(state, &"shows_title", true)):
			continue
		regions.append(PackedStringArray([
			String(_root_property(state, &"name_key", "")), String(_root_property(state, &"epithet_key", "")),
		]))
	return regions

func test_the_game_places_titled_regions() -> void:
	assert_int(_titled_regions().size()).is_greater_equal(6)

## "No village title (Recommended)" (user, 2026-10-14): the village is home, not a discovery.
func test_the_village_never_titles() -> void:
	var village := (load(VILLAGE) as PackedScene).get_state()
	assert_bool(bool(_root_property(village, &"shows_title", true))).is_false()
	for keys: PackedStringArray in _titled_regions():
		assert_str(keys[0]).is_not_equal("REGION_HOME_VILLAGE")

func test_every_titled_region_names_both_keys() -> void:
	for keys: PackedStringArray in _titled_regions():
		assert_str(keys[0]).override_failure_message("a titled region has no name_key").is_not_empty()
		assert_str(keys[1]).override_failure_message("%s has no epithet_key" % keys[0]).is_not_empty()

func test_every_name_and_epithet_is_filled_and_fits_in_every_language() -> void:
	var title := auto_free(TITLE.instantiate()) as RegionTitle
	add_child(title)
	var name_label := title.get_node("Art/Card/Name") as Label
	var epithet_label := title.get_node("Art/Card/Epithet") as Label
	assert_float(name_label.size.x).is_equal(RegionTitle.TEXT_WIDTH)
	assert_float(epithet_label.size.x).is_equal(RegionTitle.TEXT_WIDTH)
	var locales := _locales()
	assert_int(locales.size()).is_greater_equal(2)
	for locale: String in locales:
		TranslationServer.set_locale(locale)
		for keys: PackedStringArray in _titled_regions():
			title.show_title(keys[0], keys[1])
			for pair: Array in [[keys[0], name_label], [keys[1], epithet_label]]:
				var key: String = pair[0]
				var label: Label = pair[1]
				assert_str(label.text).override_failure_message("[%s] %s has no text" % [locale, key]).is_not_empty()
				assert_str(label.text).override_failure_message("[%s] %s has no row" % [locale, key]).is_not_equal(key)
				var width := label.get_theme_font(&"font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
						label.get_theme_font_size(&"font_size")).x
				assert_float(width).override_failure_message("[%s] %s is %.0f px in a %.0f px box" % [
						locale, key, width, label.size.x]).is_less_equal(label.size.x)
