class_name PlayerHelixTest extends GdUnitTestSuite

## Ivo on a helix stair: a press buffered into the boarding frame is dropped, a teleport ends the ride, and a death
## holds the corpse on its tread.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const STAIR := preload("res://scenes/world/interactables/helix_stair/helix_stair.tscn")

var _holder: Node2D
var _ivo: Player
var _stair: HelixStair


func before_test() -> void:
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	_stair = STAIR.instantiate() as HelixStair
	_holder.add_child(_stair)
	var foot := _stair.feet_global(0.0)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = foot + Vector2(0.0, 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = foot + Vector2(-4.0, -2.0)
	_holder.add_child(_ivo)

func after_test() -> void:
	Input.action_release(&"move_right")

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _input_node() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

## Lands on the floor beside the foot, then walks into it with a jump buffered on the same frame.
func _board_with_a_jump() -> void:
	await _frames(20)
	assert_bool(_ivo.is_on_floor()).is_true()
	Input.action_press(&"move_right")
	_input_node().jump_pressed.emit()
	await _frames(3)

func test_a_jump_buffered_into_the_boarding_frame_is_dropped() -> void:
	await _board_with_a_jump()
	assert_bool(_ivo.is_riding_stair()).is_true()
	assert_bool(_ivo.is_jumping()).is_false()

func test_a_teleport_ends_the_ride() -> void:
	await _board_with_a_jump()
	assert_bool(_ivo.is_riding_stair()).is_true()
	Input.action_release(&"move_right")
	_ivo.teleport(_stair.feet_global(0.0) + Vector2(-120.0, -2.0))
	assert_bool(_ivo.is_riding_stair()).is_false()
	await _frames(5)
	assert_float(_ivo.global_position.x).is_less(_stair.feet_global(0.0).x - 100.0)

func test_a_death_holds_the_corpse_on_its_tread() -> void:
	await _board_with_a_jump()
	await _frames(30)
	assert_bool(_ivo.is_riding_stair()).is_true()
	var at := _ivo.global_position
	assert_float(at.y).is_less(_stair.feet_global(0.0).y - 20.0)
	_ivo.health.take_damage(_ivo.health.max_hp)
	await _frames(40)
	assert_bool(_ivo.is_dead()).is_true()
	assert_bool(_ivo.is_riding_stair()).is_true()
	assert_float(_ivo.global_position.distance_to(at)).is_less(0.5)
