class_name SeedShopPanelTest extends GdUnitTestSuite

## The shop panel shows one row per offer and a Leave row, keeps rows the player cannot afford out of focus, wraps
## focus at both ends and releases it on close (systems/seeds-and-the-seller).

const PANEL := preload("res://scenes/ui/seed_shop/seed_shop_panel.tscn")

var _panel: SeedShopPanel
var _chosen: Array[StringName] = []
var _left: int = 0
var _locale: String
var _map: SeedOffer
var _rumour: SeedOffer
var _replant: SeedOffer


func before() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_chosen.clear()
	_left = 0
	_map = SeedStockTest.offer(&"map_threshold", SeedOffer.Kind.MAP, 1, "REGION_THRESHOLD")
	_rumour = SeedStockTest.offer(&"rumour", SeedOffer.Kind.RUMOUR, 1, "")
	_replant = SeedStockTest.offer(&"replant_village", SeedOffer.Kind.REPLANT, 3, "")
	_panel = auto_free(PANEL.instantiate()) as SeedShopPanel
	# The suite runs ALWAYS; the panel inherits PAUSABLE in the game.
	_panel.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_panel)
	_panel.chosen.connect(func(id: StringName) -> void: _chosen.append(id))
	_panel.left.connect(func() -> void: _left += 1)

func after_test() -> void:
	get_viewport().gui_release_focus()

func _offers() -> Array[SeedOffer]:
	return [_map, _rumour, _replant]

func _press(action: StringName) -> void:
	for down: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		Input.parse_input_event(event)
		await await_idle_frame()

func _focused() -> Control:
	return get_viewport().gui_get_focus_owner()

func test_rows_follow_the_offers_with_the_count_and_leave_last() -> void:
	_panel.open(_offers(), 2)
	assert_bool(_panel.visible).is_true()
	assert_str(_panel.held_label().text).is_equal(tr("SHOP_SEEDS_HELD") % 2)
	assert_str(_panel.row(&"map_threshold").text).is_equal(tr("SHOP_MAP") % tr("REGION_THRESHOLD"))
	assert_str(_panel.row(&"rumour").text).is_equal(tr("SHOP_RUMOUR"))
	assert_str(_panel.row(&"replant_village").text).is_equal(tr("SHOP_REPLANT"))
	var rows := _panel.leave_button().get_parent()
	assert_int(rows.get_child_count()).is_equal(4)
	assert_object(rows.get_child(3)).is_same(_panel.leave_button())
	assert_object(_focused()).is_same(_panel.row(&"map_threshold"))

func test_a_row_the_player_cannot_afford_is_unfocusable() -> void:
	_panel.open(_offers(), 2)
	var replant := _panel.row(&"replant_village")
	assert_bool(replant.disabled).is_true()
	assert_int(replant.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_bool(_panel.row(&"rumour").disabled).is_false()

func test_with_nothing_affordable_leave_takes_focus() -> void:
	_panel.open(_offers(), 0)
	assert_object(_focused()).is_same(_panel.leave_button())

func test_focus_wraps_and_skips_what_cannot_be_bought() -> void:
	_panel.open(_offers(), 2)
	await await_idle_frame()
	await _press(&"ui_down")
	assert_object(_focused()).is_same(_panel.row(&"rumour"))
	await _press(&"ui_down")
	assert_object(_focused()).is_same(_panel.leave_button())
	await _press(&"ui_down")
	assert_object(_focused()).is_same(_panel.row(&"map_threshold"))
	await _press(&"ui_up")
	assert_object(_focused()).is_same(_panel.leave_button())

func test_accept_on_a_row_chooses_it_and_on_leave_leaves() -> void:
	_panel.open(_offers(), 2)
	await await_idle_frame()
	await _press(&"ui_accept")
	assert_array(_chosen).contains_exactly([&"map_threshold"])
	_panel.leave_button().grab_focus()
	await _press(&"ui_accept")
	assert_int(_left).is_equal(1)

func test_close_releases_focus_and_hides() -> void:
	_panel.open(_offers(), 2)
	_panel.close()
	assert_bool(_panel.visible).is_false()
	assert_object(_focused()).is_null()

## A bought row leaves the list; focus moves to the row that took its place, and the said line stays.
func test_show_offers_keeps_focus_near_and_the_said_line() -> void:
	_panel.open(_offers(), 3)
	_panel.say("SHOP_SAID_MAP")
	var after: Array[SeedOffer] = [_rumour, _replant]
	_panel.show_offers(after, 2)
	await await_idle_frame()
	assert_object(_panel.row(&"map_threshold")).is_null()
	assert_object(_focused()).is_same(_panel.row(&"rumour"))
	assert_str(_panel.said_label().text).is_equal(tr("SHOP_SAID_MAP"))
	assert_str(_panel.held_label().text).is_equal(tr("SHOP_SEEDS_HELD") % 2)

func test_said_line_takes_the_region_name() -> void:
	_panel.open(_offers(), 2)
	_panel.say("SHOP_SAID_RUMOUR", "REGION_SPRING_WOODS")
	assert_str(_panel.said_label().text).is_equal(tr("SHOP_SAID_RUMOUR") % tr("REGION_SPRING_WOODS"))
