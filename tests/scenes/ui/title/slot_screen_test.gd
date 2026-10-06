class_name SlotScreenTest extends GdUnitTestSuite

## The slot screen only shows and asks: continuing focuses the latest save and greys empty slots, a new game over
## full slots focuses the oldest and asks before overwriting, Erase asks first, and back closes onto what asked.

const SLOT_SCREEN := preload("res://scenes/ui/title/slot_screen.tscn")

var _screen: SlotScreen
var _events: Array[String] = []


func before_test() -> void:
	_events.clear()
	_screen = auto_free(SLOT_SCREEN.instantiate()) as SlotScreen
	add_child(_screen)
	_screen.chosen.connect(func(slot: int) -> void: _events.append("chosen %d" % slot))
	_screen.erase_confirmed.connect(func(slot: int) -> void: _events.append("erase %d" % slot))
	_screen.overwrite_confirmed.connect(func(slot: int) -> void: _events.append("overwrite %d" % slot))

func test_a_used_slot_shows_its_region_bench_and_play_time() -> void:
	_screen.open(SlotScreen.Purpose.LOAD, _saves_used_at([2]))
	var card := _card(2)
	assert_bool(_label(card, "Empty").visible).is_false()
	assert_str(_label(card, "Region").text).is_equal(tr("REGION_HOME_VILLAGE"))
	assert_str(_label(card, "Bench").text).is_equal(tr("BENCH_DOWNTOWN_BENCH"))
	assert_str(_label(card, "Time").text).is_equal(tr("TITLE_PLAY_TIME") % [3, 7])
	assert_bool((card.find_child("Erase") as Button).visible).is_true()
	assert_bool((_card(1).find_child("Erase") as Button).visible).is_false()

func test_continuing_focuses_the_latest_save_and_greys_empty_slots() -> void:
	var saves := _saves_used_at([1, 3])
	saves[2].saved_at = 50
	_screen.open(SlotScreen.Purpose.LOAD, saves)
	assert_str(_focused_path()).is_equal("Slot3/Card")
	assert_bool(_card(2).is_selectable()).is_false()
	assert_int((_card(2).find_child("Card") as Button).focus_mode).is_equal(Control.FOCUS_NONE)
	assert_str(_label(_card(2), "Empty").text).is_equal(tr("TITLE_EMPTY_SLOT"))

## User decision 2026-10-06, "Oldest save".
func test_a_new_game_over_full_slots_focuses_the_oldest_save() -> void:
	var saves := _saves_used_at([1, 2, 3])
	saves[0].saved_at = 300
	saves[1].saved_at = 200
	saves[2].saved_at = 100
	_screen.open(SlotScreen.Purpose.NEW, saves)
	assert_str(_focused_path()).is_equal("Slot3/Card")

func test_picking_a_used_slot_to_continue_chooses_it() -> void:
	_screen.open(SlotScreen.Purpose.LOAD, _saves_used_at([2]))
	(_card(2).find_child("Card") as Button).pressed.emit()
	assert_array(_events).contains_exactly(["chosen 2"])

func test_overwriting_asks_first_with_no_focused_and_back_returns_to_the_card() -> void:
	_screen.open(SlotScreen.Purpose.NEW, _saves_used_at([1, 2, 3]))
	(_card(2).find_child("Card") as Button).pressed.emit()
	assert_bool(_screen.is_confirming()).is_true()
	assert_bool((_screen.find_child("List") as Control).visible).is_false()
	assert_str(_focused_path()).is_equal("ConfirmOverwrite/Choices/No")
	assert_str((_screen.find_child("ConfirmOverwrite").find_child("Body") as Label).text).is_equal(tr("CONFIRM_OVERWRITE"))
	assert_bool(_screen.step_back()).is_true()
	assert_str(_focused_path()).is_equal("Slot2/Card")
	assert_array(_events).is_empty()

func test_yes_confirms_the_overwrite_of_that_slot() -> void:
	_screen.open(SlotScreen.Purpose.NEW, _saves_used_at([1, 2, 3]))
	(_card(3).find_child("Card") as Button).pressed.emit()
	(_screen.find_child("ConfirmOverwrite").find_child("Yes") as Button).pressed.emit()
	assert_array(_events).contains_exactly(["overwrite 3"])

func test_erase_asks_first_and_no_returns_to_the_erase_that_asked() -> void:
	_screen.open(SlotScreen.Purpose.LOAD, _saves_used_at([1, 2]))
	(_card(2).find_child("Erase") as Button).pressed.emit()
	assert_str(_focused_path()).is_equal("ConfirmErase/Choices/No")
	(_screen.find_child("ConfirmErase").find_child("No") as Button).pressed.emit()
	assert_bool(_screen.is_confirming()).is_false()
	assert_str(_focused_path()).is_equal("Slot2/Erase")
	assert_array(_events).is_empty()

func test_yes_confirms_the_erase_of_that_slot() -> void:
	_screen.open(SlotScreen.Purpose.LOAD, _saves_used_at([1, 2]))
	(_card(2).find_child("Erase") as Button).pressed.emit()
	(_screen.find_child("ConfirmErase").find_child("Yes") as Button).pressed.emit()
	assert_array(_events).contains_exactly(["erase 2"])

## In a new game an empty slot takes the game without asking.
func test_while_choosing_for_a_new_game_an_empty_slot_is_chosen_at_once() -> void:
	_screen.open(SlotScreen.Purpose.NEW, _saves_used_at([1, 3]))
	(_card(2).find_child("Card") as Button).pressed.emit()
	assert_array(_events).contains_exactly(["chosen 2"])

func _saves_used_at(slots: Array[int]) -> Array[PlayerData]:
	var saves: Array[PlayerData] = [null, null, null]
	for slot: int in slots:
		var data := PlayerData.new()
		data.bench_id = &"downtown_bench"
		data.region_name_key = "REGION_HOME_VILLAGE"
		data.play_time = 3 * 3600 + 7 * 60 + 30.0
		saves[slot - 1] = data
	return saves

func _card(slot: int) -> SlotCard:
	return _screen.find_child("Slot%d" % slot) as SlotCard

func _label(card: SlotCard, label_name: String) -> Label:
	return card.find_child(label_name) as Label

## The focus owner's path below the screen's List, so Slot1/Card and Slot2/Card differ.
func _focused_path() -> String:
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null:
		return ""
	return String(_screen.get_path_to(owner)).trim_prefix("List/")
