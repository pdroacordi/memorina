class_name SwordTurnBackTest extends GdUnitTestSuite

## STORY-33: at the Old Bridge a swordless Ivo turns back on every approach, and the unseen wall holds him until he owns
## the sword.

const TURN_BACK := preload("res://resources/dialogue/story/sword_turn_back.tres")
const WALL := preload("res://scenes/world/interactables/fact_barrier/fact_wall.tscn")
const OWNS_SWORD := preload("res://resources/save_facts/owns_sword.tres")


func after_test() -> void:
	SaveSystem.begin("", true)

func test_it_turns_him_back_on_every_approach_until_he_owns_the_sword() -> void:
	var data := PlayerData.new()
	assert_str(String(TURN_BACK.pending(data).id)).is_equal("sword_turn_back")
	data.dialogues_heard.append(&"sword_turn_back")
	assert_object(TURN_BACK.pending(data)).override_failure_message("heard once, it never fires again").is_not_null()
	data.owned_items[Enums.PlayerItem.SWORD] = true
	assert_object(TURN_BACK.current(data)).is_null()

func test_the_wall_stands_until_he_owns_the_sword() -> void:
	SaveSystem.begin("", true)
	var wall := auto_free(WALL.instantiate()) as FactBarrier
	wall.requires = OWNS_SWORD
	add_child(wall)
	assert_bool(wall.is_closed()).is_true()
	assert_float(wall.body_rect().size.y).is_equal(288.0)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	assert_bool(wall.is_closed()).is_false()
