class_name ItemPickupTest extends GdUnitTestSuite

## An item lies in the world only while the save does not own it: shown on ready, hidden once taken, back after a
## rewind; take() writes the live save.

const PICKUP := preload("res://scenes/world/interactables/item_pickup/item_pickup.tscn")
const SWORD := preload("res://assets/sprites/world/pickups/sword.png")
## The farmhouse's: the sword's bottom centre on the meal table's planks.
const REST := Vector2(-4, -19)

var _pickup: ItemPickup


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	SaveSystem.commit()
	_pickup = _make()

func after_test() -> void:
	SaveSystem.begin("", true)

func _make() -> ItemPickup:
	var made := auto_free(PICKUP.instantiate()) as ItemPickup
	made.texture = SWORD
	made.rest_offset = REST
	add_child(made)
	return made

func test_lies_only_while_not_owned() -> void:
	var data := PlayerData.new()
	assert_bool(ItemPickup.lies(Enums.PlayerItem.SWORD, data)).is_true()
	data.owned_items[Enums.PlayerItem.SWORD] = true
	assert_bool(ItemPickup.lies(Enums.PlayerItem.SWORD, data)).is_false()
	assert_bool(ItemPickup.lies(Enums.PlayerItem.MEMORINA, data)).is_true()

func test_an_unowned_item_is_shown_and_available() -> void:
	assert_bool(_pickup.is_lying()).is_true()
	assert_bool(_pickup.is_available()).is_true()

func test_taking_it_owns_the_item_and_hides_it() -> void:
	var taken: Array[int] = []
	_pickup.taken.connect(func(item: Enums.PlayerItem) -> void: taken.append(item))
	_pickup.take()
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.SWORD)).is_true()
	assert_bool(_pickup.is_lying()).is_false()
	assert_bool(_pickup.is_available()).is_false()
	assert_array(taken).is_equal([Enums.PlayerItem.SWORD])

## Losing the item again (a rewound save read by a live pickup) shows it again: presence follows the save alone.
func test_it_follows_the_save_both_ways() -> void:
	_pickup.take()
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	assert_bool(_pickup.is_lying()).is_true()

## A death before a bench forgets the gain; the rebuilt world's pickup reads the rewound save on ready.
func test_a_rewind_puts_it_back() -> void:
	_pickup.take()
	SaveSystem.rewind()
	assert_bool(_make().is_lying()).is_true()

func test_an_item_already_owned_is_never_shown() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	assert_bool(_make().is_lying()).is_false()

## Over the reach (64 px) when the item lies lower, centred on the item: (-4 - 16, -64 - 8 - 32).
func test_the_item_rests_on_its_offset_and_the_prompt_stands_over_the_reach() -> void:
	var sprite := _pickup.get_node("Sprite2D") as Sprite2D
	assert_vector(sprite.position + Vector2(0, SWORD.get_height() * 0.5)).is_equal(REST)
	var prompt := _pickup.get_node("Prompt") as Control
	assert_vector(prompt.position).is_equal(Vector2(-20, -104))

## An item resting above its reach takes the prompt over the item: (-16, -80 - 10 - 8 - 32).
func test_an_item_above_its_reach_lifts_the_prompt_over_it() -> void:
	var high := auto_free(PICKUP.instantiate()) as ItemPickup
	high.texture = SWORD
	high.rest_offset = Vector2(0, -80)
	add_child(high)
	var prompt := high.get_node("Prompt") as Control
	assert_vector(prompt.position).is_equal(Vector2(-16, -130))

func test_a_hidden_pickup_is_not_available() -> void:
	_pickup.hide()
	assert_bool(_pickup.is_available()).is_false()
