class_name PlayerCalmRoomTest extends GdUnitTestSuite

## STORY-14: an interior of a region with calm interiors (the village's houses) is calm; Game copies that to
## `Player.calm` on each room change, and a calm Ivo's attack press does nothing.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const HOUSE := preload("res://scenes/world/rooms/home_village/village_house.tscn")
const VILLAGE := "res://scenes/world/rooms/home_village.tscn"

## Px below the room's top: Ivo stands on a test floor inside the room's 640x384 bounds.
const FLOOR_Y := 300.0

var _region: Region
var _room: Room
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)

func after_test() -> void:
	SaveSystem.begin("", true)

func _build(calm: bool) -> void:
	_region = auto_free(Region.new()) as Region
	_region.calm_interiors = calm
	var memory := RegionMemory.new()
	memory.name = "Memory"
	_region.add_child(memory)
	_room = HOUSE.instantiate() as Room
	_region.add_child(_room)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(320, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(640, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_region.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(320, FLOOR_Y - 60.0)
	_region.add_child(_ivo)
	add_child(_region)
	assert_bool(_room.interior).is_true()
	_ivo.calm = _room.is_calm()

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func _swings() -> bool:
	(_ivo.get_node("PlayerInput") as PlayerInput).attack_pressed.emit()
	for i: int in 3:
		await get_tree().physics_frame
	return _ivo.is_attacking()

func test_an_attack_in_a_calm_interior_does_nothing() -> void:
	_build(true)
	assert_bool(_room.is_calm()).is_true()
	await _land()
	assert_bool(await _swings()).is_false()

func test_the_same_interior_in_a_region_without_calm_lets_him_swing() -> void:
	_build(false)
	assert_bool(_room.is_calm()).is_false()
	await _land()
	assert_bool(await _swings()).is_true()


## The village's interiors are the calm ones (STORY-14).
func test_the_village_has_calm_interiors() -> void:
	var state := (load(VILLAGE) as PackedScene).get_state()
	var calm := false
	for i: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"calm_interiors":
			calm = bool(state.get_node_property_value(0, i))
	assert_bool(calm).is_true()
