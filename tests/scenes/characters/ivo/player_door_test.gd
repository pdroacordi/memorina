class_name PlayerDoorTest extends GdUnitTestSuite

## Up at an open door emits door_entered once; the body refuses it in the air or playing;
## a sealed door knocks; arrive_at lands on the door, turns him and drops buffered presses.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const DOOR := preload("res://scenes/world/interactables/door/door.tscn")
const ALL_RESTORED := preload("res://resources/save_facts/all_guardians_restored.tres")

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _door: Door
var _entered: Array[Door] = []


func before_test() -> void:
	_entered.clear()
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_door = DOOR.instantiate() as Door
	_door.position = Vector2(0, FLOOR_Y)
	_holder.add_child(_door)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)
	_ivo.door_entered.connect(func(door: Door) -> void: _entered.append(door))

func test_up_at_an_open_door_enters_it_once() -> void:
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(_entered).contains_exactly([_door])

## "Buffer it ~0.1 s" (user, 2026-10-08): a press just short of the door takes it when it comes in reach.
func test_an_early_up_waits_for_the_door() -> void:
	_door.position = Vector2(500, FLOOR_Y)
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(1)
	_door.position = Vector2(0, FLOOR_Y)
	await _frames(4)
	assert_array(_entered).contains_exactly([_door])

func test_an_up_older_than_the_buffer_is_dropped() -> void:
	_door.position = Vector2(500, FLOOR_Y)
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(12)
	_door.position = Vector2(0, FLOOR_Y)
	await _frames(4)
	assert_array(_entered).is_empty()

func test_up_in_the_air_does_nothing() -> void:
	_player_input().look_up_pressed.emit()
	await _frames(2)
	assert_bool(_ivo.is_on_floor()).is_false()
	assert_array(_entered).is_empty()

func test_up_with_the_memorina_drawn_is_a_note_not_a_door() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	await _land()
	_player_input().draw_memorina_pressed.emit()
	for i: int in 30:
		await get_tree().physics_frame
		if _ivo.is_memorina_drawn():
			break
	assert_bool(_ivo.is_memorina_drawn()).is_true()
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(_entered).is_empty()

func test_a_sealed_door_knocks_and_is_not_entered() -> void:
	_door.requires = ALL_RESTORED
	var knocks: Array[int] = [0]
	_door.knocked.connect(func() -> void: knocks[0] += 1)
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(_entered).is_empty()
	assert_int(knocks[0]).is_equal(1)

func test_arrive_at_lands_on_the_door_and_applies_its_facing() -> void:
	await _land()
	var other := DOOR.instantiate() as Door
	other.position = Vector2(600, FLOOR_Y)
	other.arrive_facing = -1
	_holder.add_child(other)
	_ivo.arrive_at(other)
	assert_vector(_ivo.global_position).is_equal(other.global_position)
	assert_int(_ivo.facing).is_equal(-1)

func test_arrive_facing_zero_keeps_his_facing() -> void:
	await _land()
	var before := _ivo.facing
	_ivo.arrive_at(_door)
	assert_int(_ivo.facing).is_equal(before)

## The fade does not tick the buffers: a jump pressed on the way in must not fire on arrival.
func test_a_jump_buffered_before_arrival_does_not_fire() -> void:
	await _land()
	_player_input().jump_pressed.emit()
	_ivo.arrive_at(_door)
	await _frames(10)
	assert_bool(_ivo.is_jumping()).is_false()

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

## STORY-14: the prompt shows exactly where Up would take the door, across its edge (both read the door sensor).
func test_the_prompt_and_the_reach_agree_at_the_door_edge() -> void:
	await _land()
	var prompt := _door.get_node("Prompt") as CanvasItem
	var doors := _ivo.get_node("Doors") as DoorComponent
	var shown := 0
	for x: int in range(4, 40, 2):
		_ivo.teleport(Vector2(x, FLOOR_Y))
		await _frames(3)
		var reached := doors.reachable() == _door
		assert_bool(prompt.visible).override_failure_message("x %d: prompt %s, reach %s" % [x, prompt.visible, reached]).is_equal(reached)
		shown += 1 if reached else 0
	assert_int(shown).is_between(1, 17)
