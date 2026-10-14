class_name RegionTitleTest extends GdUnitTestSuite

## The title fades in, holds and fades out on its own; a second title replaces the first; a paused tree stops it.

const TITLE := preload("res://scenes/ui/region_title/region_title.tscn")

var _title: RegionTitle
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	TranslationServer.set_locale("en")
	_title = auto_free(TITLE.instantiate()) as RegionTitle
	# Pausable like the game's CanvasLayer, whatever the test runner's own mode.
	_title.process_mode = Node.PROCESS_MODE_PAUSABLE
	_title.lead_in = 0.05
	_title.fade_in = 0.05
	# Longer than a headless frame (measured up to 0.14 s), so the shown checks land inside it.
	_title.hold = 1.0
	_title.fade_out = 0.05
	add_child(_title)

func _label(label_name: String) -> Label:
	return _title.get_node("Art/Card/" + label_name) as Label

func test_it_starts_hidden() -> void:
	assert_bool(_title.is_showing()).is_false()
	assert_float(_title.alpha()).is_equal(0.0)

func test_a_title_shows_the_translated_name_and_epithet() -> void:
	_title.show_title("REGION_THRESHOLD", "REGION_THRESHOLD_EPITHET")
	assert_str(_label("Name").text).is_equal("Threshold Road")
	assert_str(_label("Epithet").text).is_equal("The road past all you remember")

func test_an_empty_epithet_key_leaves_the_line_empty() -> void:
	_title.show_title("REGION_THRESHOLD", "")
	assert_str(_label("Epithet").text).is_empty()

func test_it_fades_in_holds_and_fades_out() -> void:
	_title.show_title("REGION_THRESHOLD", "REGION_THRESHOLD_EPITHET")
	await await_millis(400)
	assert_float(_title.alpha()).is_equal(1.0)
	var card := _title.get_node("Art/Card") as Control
	assert_float(card.position.y).is_equal(0.0)
	await await_millis(1200)
	assert_bool(_title.is_showing()).is_false()

## The rule is centred under the name and reaches past both its ends.
func test_the_rule_spans_the_name() -> void:
	_title.show_title("REGION_SUMMER_CALDERA", "REGION_SUMMER_CALDERA_EPITHET")
	var label := _label("Name")
	var width := label.get_theme_font(&"font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			label.get_theme_font_size(&"font_size")).x
	var rule := _title.get_node("Art/Card/Rule") as RegionTitleOrnament
	assert_float(rule.size.x).is_greater_equal(width + RegionTitle.RULE_OVERHANG * 2)
	assert_float(absf(rule.position.x + rule.size.x * 0.5 - 160.0)).is_less_equal(0.5)

func test_a_second_title_replaces_the_first_and_leaves_nothing_behind() -> void:
	_title.show_title("REGION_THRESHOLD", "REGION_THRESHOLD_EPITHET")
	await await_millis(300)
	_title.show_title("REGION_FROST_EDGE", "REGION_FROST_EDGE_EPITHET")
	assert_str(_label("Name").text).is_equal("Threshold Road")
	await await_millis(400)
	assert_str(_label("Name").text).is_equal("Frost Edge")
	assert_float(_title.alpha()).is_equal(1.0)
	await await_millis(1200)
	assert_bool(_title.is_showing()).is_false()

## A performance freeze or a menu hold pauses the tree; the card stays where it was and resumes from there.
func test_a_paused_tree_stops_it() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_title.show_title("REGION_THRESHOLD", "REGION_THRESHOLD_EPITHET")
	await await_millis(300)
	freeze.freeze()
	var held := _title.alpha()
	# A timer that runs while paused: gdUnit's await_millis stops with the tree.
	await get_tree().create_timer(1.5, true, false, true).timeout
	assert_float(_title.alpha()).is_equal(held)
	freeze.thaw()
	remove_child(freeze)
	freeze.free()
	await await_millis(1300)
	assert_bool(_title.is_showing()).is_false()
