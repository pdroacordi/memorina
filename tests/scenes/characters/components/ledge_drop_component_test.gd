class_name LedgeDropComponentTest extends GdUnitTestSuite

## On a built room with real move_and_slide: a drop falls past the ledge and lands on the floor below without rising;
## its fall moves from the second frame; a plank, an edge beside a plank, the air and a 0.5 px teleport do not drop.

const STEP := 1.0 / 60.0
## px/s², px/s.
const GRAVITY := 980.0
const TERMINAL := 600.0
const CELL := RoomMap.CELL_PX

const ROOM := """[room]
origin = 0, 0
tileset = legacy

[grid]
............
............
............
............
...=====-...
............
............
############
"""

var _room: RoomMapNode
var _body: CharacterBody2D
var _drop: LedgeDropComponent


func before_test() -> void:
	var result := RoomMapParser.parse(ROOM, RoomLegend.load_default())
	assert_bool(result.ok()).is_true()
	_room = RoomMapNode.new()
	_room.map = result.map
	add_child(_room)
	auto_free(_room)
	_body = CharacterBody2D.new()
	_body.collision_mask = GroundCollision.COLLISION_LAYER
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 54.0
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = capsule
	shape.position = Vector2(0.0, -27.0)
	_body.add_child(shape)
	_drop = LedgeDropComponent.new()
	_body.add_child(_drop)
	add_child(_body)
	auto_free(_body)

## Stands the body with its feet on row 4's top at column `column` (centre x offset by `dx` px).
func _stand_at(column: int, dx: float = 0.0) -> void:
	Character.teleport_body(_body, Vector2(column * CELL + CELL * 0.5 + dx, 4 * CELL - 20.0))
	await _fall_until(func() -> bool: return _body.is_on_floor(), 60)
	assert_bool(_body.is_on_floor()).is_true()

## Steps gravity and move_and_slide until `until` holds or `frames` pass; returns the highest y seen after the first.
func _fall_until(until: Callable, frames: int) -> float:
	var lowest := -INF
	for _frame: int in frames:
		await get_tree().physics_frame
		_body.velocity.y = minf(_body.velocity.y + GRAVITY * STEP, TERMINAL)
		_body.move_and_slide()
		assert_float(_body.global_position.y).is_greater_equal(lowest - 0.01)
		lowest = _body.global_position.y
		if until.call():
			break
	return lowest

func test_a_drop_falls_past_the_ledge_and_lands_on_the_floor_below() -> void:
	await _stand_at(5)
	var at := _body.global_position
	var heard: Array[Vector2] = []
	_drop.dropped.connect(func(from: Vector2) -> void: heard.append(from))
	assert_bool(_drop.try_drop()).is_true()
	assert_that(heard).is_equal([at] as Array[Vector2])
	await _fall_until(func() -> bool: return _body.is_on_floor(), 120)
	assert_bool(_body.is_on_floor()).is_true()
	assert_float(_body.global_position.y).is_equal_approx(7 * CELL, 1.0)

func test_the_fall_moves_from_its_second_frame() -> void:
	await _stand_at(5)
	assert_bool(_drop.try_drop()).is_true()
	var ys: Array[float] = [_body.global_position.y]
	for _frame: int in 2:
		await get_tree().physics_frame
		_body.velocity.y = minf(_body.velocity.y + GRAVITY * STEP, TERMINAL)
		_body.move_and_slide()
		ys.append(_body.global_position.y)
	assert_float(ys[2] - ys[1]).is_greater_equal(1.0)

func test_a_plank_stays() -> void:
	await _stand_at(8)
	assert_bool(_drop.try_drop()).is_false()

func test_an_edge_beside_a_plank_stays() -> void:
	await _stand_at(7, 14.0)
	assert_bool(_drop.try_drop()).is_false()

func test_a_heel_over_air_drops() -> void:
	await _stand_at(3, -14.0)
	assert_bool(_drop.try_drop()).is_true()

func test_the_air_never_drops() -> void:
	Character.teleport_body(_body, Vector2(5 * CELL + 16.0, 2 * CELL))
	await get_tree().physics_frame
	_body.velocity = Vector2.ZERO
	_body.move_and_slide()
	assert_bool(_drop.try_drop()).is_false()

func test_half_a_pixel_into_the_ledge_stalls_on_it() -> void:
	await _stand_at(5)
	_drop.depth = 0.5
	assert_bool(_drop.try_drop()).is_true()
	await _fall_until(func() -> bool: return false, 30)
	assert_bool(_body.is_on_floor()).is_true()
	assert_float(_body.global_position.y).is_less(4 * CELL + 1.0)
