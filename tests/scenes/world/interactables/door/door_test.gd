class_name DoorTest extends GdUnitTestSuite

## A door is open without a fact or with the fact held, sealed without it, and is found only inside its room.

const DOOR := preload("res://scenes/world/interactables/door/door.tscn")
const OWNS_MEMORINA := preload("res://resources/save_facts/owns_memorina.tres")


func _room() -> Room:
	var room := auto_free(Room.new()) as Room
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 384)
	shape.shape = rect
	room.add_child(shape)
	add_child(room)
	return room

func _door(link: StringName, parent: Node) -> Door:
	var door := DOOR.instantiate() as Door
	door.link = link
	parent.add_child(door)
	return door

func test_a_door_without_a_fact_is_open() -> void:
	var door := _door(&"front", _room())
	assert_bool(door.is_open_for(PlayerData.new())).is_true()

func test_a_door_opens_only_while_its_fact_holds() -> void:
	var door := _door(&"fence", _room())
	door.requires = OWNS_MEMORINA
	var data := PlayerData.new()
	assert_bool(door.is_open_for(data)).is_false()
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	assert_bool(door.is_open_for(data)).is_true()

func test_find_is_scoped_to_the_room() -> void:
	var outside := _room()
	var inside := _room()
	var front_out := _door(&"front", outside)
	var front_in := _door(&"front", inside)
	assert_object(Door.find(get_tree(), outside, &"front")).is_same(front_out)
	assert_object(Door.find(get_tree(), inside, &"front")).is_same(front_in)
	assert_object(Door.find(get_tree(), inside, &"hatch")).is_null()
