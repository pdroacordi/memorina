class_name CachePickupTest extends GdUnitTestSuite

## A seed lies in its cache until taken; a death before a bench puts it back (systems/seeds-and-the-seller).

const PICKUP := preload("res://scenes/world/interactables/cache_pickup/cache_pickup.tscn")


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.commit()

func after_test() -> void:
	SaveSystem.begin("", true)

func _make(slot_id: StringName) -> CachePickup:
	var made := auto_free(PICKUP.instantiate()) as CachePickup
	made.slot_id = slot_id
	add_child(made)
	return made

func test_a_seed_lies_until_taken() -> void:
	var data := PlayerData.new()
	assert_bool(CachePickup.lies(&"threshold_ravine_cache", data)).is_true()
	data.caches_taken.append(&"threshold_ravine_cache")
	assert_bool(CachePickup.lies(&"threshold_ravine_cache", data)).is_false()
	assert_bool(CachePickup.lies(&"woods_crown_cache", data)).is_true()

func test_taking_it_records_it_and_hides_it() -> void:
	var pickup := _make(&"threshold_ravine_cache")
	var taken: Array[StringName] = []
	pickup.taken.connect(func(slot_id: StringName) -> void: taken.append(slot_id))
	assert_bool(pickup.is_available()).is_true()
	pickup.take()
	assert_bool(SaveSystem.has_cache(&"threshold_ravine_cache")).is_true()
	assert_bool(pickup.is_lying()).is_false()
	assert_bool(pickup.is_available()).is_false()
	assert_array(taken).is_equal([&"threshold_ravine_cache"])

func test_a_rewind_puts_it_back() -> void:
	_make(&"threshold_ravine_cache").take()
	SaveSystem.rewind()
	assert_bool(_make(&"threshold_ravine_cache").is_lying()).is_true()

func test_the_husk_stands_on_the_floor_and_the_prompt_over_the_reach() -> void:
	var pickup := _make(&"threshold_ravine_cache")
	var sprite := pickup.get_node("Sprite2D") as Sprite2D
	assert_float(sprite.offset.y + sprite.texture.get_height()).is_equal(0.0)
	var prompt := pickup.get_node("Prompt") as Control
	assert_float(prompt.position.y + prompt.size.y).is_less(-2.0 * RoomMap.CELL_PX)
	assert_bool(prompt.visible).is_false()
