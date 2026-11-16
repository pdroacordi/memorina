class_name CreditsRollTest extends GdUnitTestSuite

## The roll builds its sheet's rows with the logo last, retranslates its keys but never a name, stops under a hold,
## lands with the logo centred and hides whole.

const ROLL := preload("res://scenes/ui/credits/credits_roll.tscn")
const HEADING := &"REGION_THRESHOLD"
const ROLE := &"REGION_HOME_VILLAGE"

var _roll: CreditsRoll
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	TranslationServer.set_locale("en")
	_roll = auto_free(ROLL.instantiate()) as CreditsRoll
	_roll.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_roll)

func _sheet() -> CreditsSheet:
	var entry := CreditsEntry.new()
	entry.role_key = ROLE
	entry.names = PackedStringArray(["Ana Example", "Bruno Example"])
	var section := CreditsSection.new()
	section.heading_key = HEADING
	section.entries = [entry]
	var sheet := CreditsSheet.new()
	sheet.sections = [section, section]
	sheet.scroll_speed = 40.0
	sheet.hold_end = 0.5
	return sheet

func _texts() -> Array[String]:
	var found: Array[String] = []
	for row: Control in _roll.rows():
		if row is Label:
			found.append((row as Label).text)
	return found

func test_it_starts_hidden_and_done() -> void:
	assert_bool(_roll.visible).is_false()
	assert_bool(_roll.is_done()).is_true()
	assert_float(_roll.duration()).is_equal(0.0)

func test_it_builds_headings_roles_and_names_with_the_logo_last() -> void:
	_roll.roll(_sheet())
	assert_bool(_roll.visible).is_true()
	var heading := TranslationServer.translate(HEADING)
	var role := TranslationServer.translate(ROLE)
	assert_array(_texts()).is_equal([heading, role, "Ana Example", "Bruno Example", heading, role, "Ana Example",
			"Bruno Example"])
	var last := _roll.rows()[-1]
	assert_bool(last is TextureRect).is_true()
	assert_object((last as TextureRect).texture).is_same(_roll.logo)
	assert_bool(_roll.is_done()).is_false()

## A section with no heading shows its entries alone; an entry shows its lines() (a licence's paragraphs).
func test_a_section_without_a_heading_shows_its_entries_alone() -> void:
	var licence := CreditsLicence.new()
	var section := CreditsSection.new()
	section.entries = [licence]
	var sheet := CreditsSheet.new()
	sheet.sections = [section]
	_roll.roll(sheet)
	assert_array(PackedStringArray(_texts())).is_equal(licence.lines())

func test_its_keys_retranslate_and_its_names_stay() -> void:
	_roll.roll(_sheet())
	var english := _texts()
	TranslationServer.set_locale("pt_BR")
	await get_tree().process_frame
	var portuguese := _texts()
	assert_str(portuguese[0]).is_equal(TranslationServer.translate(HEADING))
	assert_str(portuguese[0]).is_not_equal(english[0])
	assert_str(portuguese[2]).is_equal("Ana Example")

## A name or a licence line that matches a translation key is still shown as written.
func test_no_row_is_auto_translated() -> void:
	_roll.roll(_sheet())
	for row: Control in _roll.rows():
		if row is Label:
			assert_int(row.auto_translate_mode).is_equal(Node.AUTO_TRANSLATE_MODE_DISABLED)

func test_it_rolls_up_in_whole_art_px() -> void:
	_roll.roll(_sheet())
	var column := _roll.get_node("Art/Column") as Control
	assert_float(column.position.y).is_equal(CreditsRoll.VIEW_HEIGHT)
	await await_millis(300)
	assert_float(column.position.y).is_less(CreditsRoll.VIEW_HEIGHT)
	assert_float(column.position.y).is_equal(roundf(column.position.y))

func test_a_paused_tree_stops_it() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_roll.roll(_sheet())
	await await_millis(200)
	freeze.freeze()
	var held := _roll.elapsed()
	# A timer that runs while paused: gdUnit's await_millis stops with the tree.
	await get_tree().create_timer(0.6, true, false, true).timeout
	assert_float(_roll.elapsed()).is_equal(held)
	freeze.thaw()
	remove_child(freeze)
	freeze.free()
	await await_millis(200)
	assert_float(_roll.elapsed()).is_greater(held)

func test_land_centres_the_logo_and_ends_the_hold() -> void:
	_roll.roll(_sheet())
	for i: int in 4:
		await get_tree().process_frame
	_roll.land()
	assert_bool(_roll.is_done()).is_true()
	var column := _roll.get_node("Art/Column") as Control
	var logo := _roll.rows()[-1]
	var centre := column.position.y + logo.position.y + logo.size.y * 0.5
	assert_float(centre).is_equal_approx(CreditsRoll.VIEW_HEIGHT * 0.5, 1.0)
	assert_float(logo.modulate.a).is_equal(1.0)

func test_it_ends_after_its_travel_and_hold() -> void:
	var sheet := _sheet()
	sheet.scroll_speed = 2000.0
	_roll.roll(sheet)
	await await_millis(300)
	assert_bool(_roll.is_done()).is_false()
	await await_millis(500)
	assert_bool(_roll.is_done()).is_true()

func test_hide_now_resets_it() -> void:
	_roll.roll(_sheet())
	_roll.hide_now()
	assert_bool(_roll.visible).is_false()
	assert_int(_roll.rows().size()).is_equal(0)
	assert_bool(_roll.is_done()).is_true()

## game.tscn gives the director its roll, drawn after the bars and under the fade.
func test_game_wires_the_roll_between_the_bars_and_the_fade() -> void:
	var state := (load("res://scenes/world/game.tscn") as PackedScene).get_state()
	var order: Array[StringName] = []
	var wired := NodePath()
	for node: int in state.get_node_count():
		if String(state.get_node_path(node, true)).trim_prefix("./") == "CanvasLayer":
			order.append(state.get_node_name(node))
		if state.get_node_name(node) == &"CutsceneDirector":
			for i: int in state.get_node_property_count(node):
				if state.get_node_property_name(node, i) == &"credits":
					wired = state.get_node_property_value(node, i)
	assert_str(String(wired)).is_equal("../../CanvasLayer/CreditsRoll")
	assert_int(order.find(&"CreditsRoll")).is_greater(order.find(&"Letterbox"))
	assert_int(order.find(&"CreditsRoll")).is_less(order.find(&"Fade"))
