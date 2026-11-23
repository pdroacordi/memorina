class_name PlayerLedgeDropTest extends GdUnitTestSuite

## Down then Jump on an earth ledge drops Ivo through it with no jump and no coyote jump after; on a plank, alone, with
## Jump first, while blocked, or buffered in the air, the press is a jump or nothing (architecture/drop-through-ledges).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const CELL := RoomMap.CELL_PX
## Earth ledge cols 2-7 and plank cols 8-9 on row 4; the floor's top is row 7.
const ROOM := """[room]
origin = 0, 0
tileset = legacy

[grid]
..............
..............
..............
..............
..======--....
..............
..............
##############
"""
const LEDGE_TOP := 4 * CELL
const FLOOR_TOP := 7 * CELL

var _holder: Node2D
var _ivo: Player
var _jumps: int = 0


func before_test() -> void:
	SaveSystem.begin("", true)
	_jumps = 0
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var result := RoomMapParser.parse(ROOM, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	var room := RoomMapNode.new()
	room.map = result.map
	_holder.add_child(room)

func after_test() -> void:
	_act(&"look_down", false)
	_act(&"jump", false)
	SaveSystem.begin("", true)

## Puts Ivo on the row-4 ledge over column `column` and waits for him to stand.
func _spawn(column: int) -> void:
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(column * CELL + CELL * 0.5, LEDGE_TOP - 2.0)
	_holder.add_child(_ivo)
	_ivo.jumped.connect(func(_at: Vector2) -> void: _jumps += 1)
	for i: int in 60:
		await get_tree().physics_frame
		if i > 5 and _ivo.is_on_floor():
			break
	assert_bool(_ivo.is_on_floor()).is_true()

func _act(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _jump_component() -> JumpComponent:
	return _ivo.get_node("Jump") as JumpComponent

## Down held, Jump pressed a few frames later and both let go.
func _down_then_jump() -> void:
	_act(&"look_down", true)
	await _frames(4)
	_act(&"jump", true)
	await _frames(3)
	_act(&"jump", false)
	_act(&"look_down", false)

func test_down_then_jump_on_an_earth_ledge_drops_through_it() -> void:
	await _spawn(4)
	var dropped: Array[Vector2] = []
	_ivo.dropped_through.connect(func(at: Vector2) -> void: dropped.append(at))
	_act(&"look_down", true)
	await _frames(4)
	_act(&"jump", true)
	await _frames(2)
	assert_int(dropped.size()).is_equal(1)
	assert_bool(_jump_component().has_buffered_jump()).is_false()
	assert_bool(_jump_component().can_ground_jump(false)).is_false()
	_act(&"jump", false)
	_act(&"look_down", false)
	await _frames(60)
	assert_int(_jumps).is_equal(0)
	assert_bool(_ivo.is_on_floor()).is_true()
	assert_float(_ivo.global_position.y).is_equal_approx(FLOOR_TOP, 1.0)

func test_down_then_jump_on_a_plank_jumps() -> void:
	await _spawn(9)
	await _down_then_jump()
	assert_int(_jumps).is_equal(1)
	await _frames(90)
	assert_float(_ivo.global_position.y).is_less(LEDGE_TOP + 1.0)

func test_jump_alone_on_an_earth_ledge_jumps_and_lands_back_on_it() -> void:
	await _spawn(4)
	_act(&"jump", true)
	await _frames(3)
	_act(&"jump", false)
	assert_int(_jumps).is_equal(1)
	await _frames(90)
	assert_bool(_ivo.is_on_floor()).is_true()
	assert_float(_ivo.global_position.y).is_less(LEDGE_TOP + 1.0)

func test_jump_then_down_jumps() -> void:
	await _spawn(4)
	_act(&"jump", true)
	await _frames(3)
	_act(&"look_down", true)
	await _frames(3)
	_act(&"jump", false)
	_act(&"look_down", false)
	assert_int(_jumps).is_equal(1)

func test_a_blocked_ivo_neither_drops_nor_jumps() -> void:
	await _spawn(4)
	_ivo.block_input()
	await _down_then_jump()
	await _frames(20)
	_ivo.unblock_input()
	assert_int(_jumps).is_equal(0)
	assert_float(_ivo.global_position.y).is_less(LEDGE_TOP + 1.0)

func test_a_second_press_just_after_a_drop_is_no_ground_jump() -> void:
	await _spawn(4)
	var dropped: Array[Vector2] = []
	_ivo.dropped_through.connect(func(at: Vector2) -> void: dropped.append(at))
	_act(&"look_down", true)
	await _frames(4)
	_act(&"jump", true)
	for i: int in 10:
		await get_tree().physics_frame
		if not dropped.is_empty():
			break
	assert_int(dropped.size()).is_equal(1)
	_act(&"jump", false)
	_act(&"look_down", false)
	await _frames(1)
	_act(&"jump", true)
	await _frames(3)
	_act(&"jump", false)
	assert_int(_jumps).is_equal(0)

## bugs/a-jump-buffered-in-the-air-with-down-held-drops-through-a-ledge-on-landing
func test_a_jump_buffered_in_the_air_with_down_held_jumps_on_landing() -> void:
	await _spawn(4)
	var dropped: Array[Vector2] = []
	_ivo.dropped_through.connect(func(at: Vector2) -> void: dropped.append(at))
	_ivo.teleport(Vector2(_ivo.global_position.x, LEDGE_TOP - 110.0))
	_act(&"look_down", true)
	for i: int in 60:
		await get_tree().physics_frame
		if _ivo.global_position.y > LEDGE_TOP - 12.0:
			break
	assert_bool(_ivo.is_on_floor()).is_false()
	_act(&"jump", true)
	await _frames(12)
	_act(&"jump", false)
	_act(&"look_down", false)
	assert_int(_jumps).is_equal(1)
	assert_int(dropped.size()).is_equal(0)
