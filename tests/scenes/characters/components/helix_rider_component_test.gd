class_name HelixRiderComponentTest extends GdUnitTestSuite

## A rider boards the foot by Up or by walking in on the hand side, rides straight up the axis, walks off the head onto
## the gallery with the hand side held, holds there on Up, walks off the foot on the other side, stays still while held,
## and leaves the tower turned as he left it.

const STAIR := preload("res://scenes/world/interactables/helix_stair/helix_stair.tscn")
const RIGHT := Vector2(1.0, 0.0)
const LEFT := Vector2(-1.0, 0.0)
const UP := Vector2(0.0, -1.0)
const DOWN := Vector2(0.0, 1.0)
const STEP := 1.0 / 60.0
## Ivo's run speed, px/s.
const SPEED := 192.0

var _body: CharacterBody2D
var _rider: HelixRiderComponent
var _stair: HelixStair


func before_test() -> void:
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	_stair = STAIR.instantiate() as HelixStair
	holder.add_child(_stair)
	holder.add_child(_floor(_stair.feet_global(0.0), false))
	holder.add_child(_floor(_stair.feet_global(_stair.head_u()), true))
	_body = CharacterBody2D.new()
	_body.collision_mask = 2
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11.0
	capsule.height = 54.0
	var shape := CollisionShape2D.new()
	shape.shape = capsule
	shape.position = Vector2(0.0, -27.0)
	_body.add_child(shape)
	var sensor := Area2D.new()
	sensor.name = "ClimbSensor"
	sensor.collision_layer = 0
	sensor.collision_mask = Climbable.LAYER
	var sensor_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12.0, 28.0)
	sensor_shape.shape = box
	sensor_shape.position = Vector2(0.0, -30.0)
	sensor.add_child(sensor_shape)
	_body.add_child(sensor)
	_rider = HelixRiderComponent.new()
	_body.add_child(_rider)
	_body.position = _stair.feet_global(0.0) + Vector2(-4.0, 0.0)
	holder.add_child(_body)

## A floor 256 px wide around `at`; the gallery is one-way, so the rider rises through it.
func _floor(at: Vector2, one_way: bool) -> StaticBody2D:
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = at + Vector2(0.0, 16.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(256.0, 32.0)
	shape.shape = rect
	shape.one_way_collision = one_way
	floor_body.add_child(shape)
	return floor_body

## Steps the rider and the body like Player does, for at most `frames`, until `until` holds.
func _ride(axis: Vector2, frames: int, until: Callable = func() -> bool: return false) -> HelixRiderComponent.Exit:
	var exit := HelixRiderComponent.Exit.RIDING
	for i: int in frames:
		_rider.tick(STEP, axis.x)
		exit = _rider.update(STEP, axis, SPEED)
		_body.move_and_slide()
		await get_tree().physics_frame
		if exit != HelixRiderComponent.Exit.RIDING or until.call():
			break
	return exit

func _board(axis: Vector2) -> bool:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var end := _rider.end_pressed_into(axis)
	if end == null:
		return false
	_rider.board(end)
	return true

func test_up_at_the_foot_boards() -> void:
	assert_bool(await _board(UP)).is_true()

func test_walking_in_on_the_hand_side_boards_and_the_other_side_does_not() -> void:
	assert_bool(await _board(LEFT)).is_false()
	assert_bool(await _board(RIGHT)).is_true()

func test_the_ride_is_straight_up_the_axis_on_the_tread_tops() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	await _ride(RIGHT, 2)
	for i: int in 60:
		await _ride(RIGHT, 1)
		assert_float(_body.velocity.x).is_equal_approx(0.0, 0.01)
		assert_float(_body.velocity.y).is_less_equal(0.0)
		assert_float(_body.global_position.y).is_equal_approx(_stair.stand_global(_rider.progress()).y, 0.5)
	assert_float(_body.global_position.x).is_equal_approx(_stair.feet_global(0.0).x, 0.01)

func test_the_camera_follows_the_steady_rise_while_the_feet_climb_the_risers() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	for i: int in 40:
		await _ride(RIGHT, 1)
		var framed := _body.global_position.y + _rider.frame_bias()
		assert_float(framed).is_equal_approx(_stair.feet_global(_rider.progress()).y, 0.5)

func test_a_held_hand_side_climbs_to_the_head_and_walks_onto_the_gallery() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	var exit: HelixRiderComponent.Exit = await _ride(RIGHT, 900)
	assert_int(exit).is_equal(HelixRiderComponent.Exit.OFF_HEAD)
	assert_float(_body.global_position.distance_to(_stair.feet_global(_stair.head_u()))).is_less(1.0)
	assert_float(_stair.angle()).is_equal(_stair.head_u())

func test_up_holds_at_the_head() -> void:
	assert_bool(await _board(UP)).is_true()
	await _ride(UP, 900, func() -> bool: return _rider.progress() >= _stair.head_u())
	assert_int(await _ride(UP, 30)).is_equal(HelixRiderComponent.Exit.RIDING)
	assert_bool(_rider.is_riding()).is_true()
	assert_int(await _ride(RIGHT, 2)).is_equal(HelixRiderComponent.Exit.OFF_HEAD)

func test_the_other_side_walks_off_the_foot() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	await _ride(RIGHT, 20)
	assert_int(await _ride(LEFT, 200)).is_equal(HelixRiderComponent.Exit.OFF_FOOT)
	assert_float(_body.global_position.distance_to(_stair.feet_global(0.0))).is_less(1.0)
	assert_bool(_body.is_on_floor()).is_true()
	assert_float(_stair.angle()).is_equal(0.0)

func test_a_press_held_from_leaving_does_not_board_again_until_let_go() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	await _ride(RIGHT, 20)
	assert_int(await _ride(LEFT, 200)).is_equal(HelixRiderComponent.Exit.OFF_FOOT)
	_rider.tick(0.5, -1.0)
	assert_object(_rider.end_pressed_into(LEFT)).is_null()

## bugs/a-hit-on-a-far-run-reverses-a-held-helix-climb: a hold keeps the feet still, and the held side climbs after it.
func test_a_hold_keeps_the_feet_still_and_the_climb_resumes() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	await _ride(RIGHT, 60)
	var at := _body.global_position
	for i: int in 10:
		assert_int(_rider.update(STEP, Vector2.ZERO, SPEED, true)).is_equal(HelixRiderComponent.Exit.RIDING)
		_body.move_and_slide()
		await get_tree().physics_frame
	assert_float(_body.global_position.distance_to(at)).is_less(0.5)
	await _ride(RIGHT, 10)
	assert_float(_body.global_position.y).is_less(at.y)

## bugs/boarding-a-helix-end-can-move-the-feet-twelve-px-in-one-frame: an end boards only within board_reach of the feet.
func test_an_end_beyond_board_reach_boards_nothing() -> void:
	Character.teleport_body(_body, _stair.feet_global(0.0) + Vector2(-10.0, 0.0))
	assert_bool(await _board(UP)).is_false()
	Character.teleport_body(_body, _stair.feet_global(0.0) + Vector2(-4.0, 0.0))
	assert_bool(await _board(UP)).is_true()

## bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn: Down at the head takes the feet
## through the one-way gallery and down the treads, never more than one riser a frame.
func test_down_at_the_head_descends_through_the_gallery_tread_by_tread() -> void:
	var head := _stair.feet_global(_stair.head_u())
	Character.teleport_body(_body, head + Vector2(4.0 * _stair.hand, -2.0))
	for i: int in 4:
		_body.velocity = Vector2(0.0, 60.0)
		_body.move_and_slide()
		await get_tree().physics_frame
	assert_bool(_body.is_on_floor()).is_true()
	assert_bool(await _board(DOWN)).is_true()
	var last := _body.global_position.y
	for i: int in 240:
		assert_int(await _ride(DOWN, 1)).is_equal(HelixRiderComponent.Exit.RIDING)
		var y := _body.global_position.y
		assert_float(y).is_equal_approx(_stair.stand_global(_rider.progress()).y, 0.5)
		assert_float(y - last).is_between(-0.5, _stair.shape.riser() + 0.5)
		last = y
	assert_float(_rider.progress()).is_less(_stair.head_u() - 1.0)
	assert_float(_body.global_position.y).is_greater(head.y + _stair.shape.riser() * 10.0)

## A body held short of its target keeps progress where it is until the body arrives.
func test_a_body_short_of_its_step_holds_the_progress() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	await _ride(RIGHT, 30)
	var held := _rider.progress()
	Character.teleport_body(_body, _body.global_position + Vector2(0.0, 8.0))
	_rider.update(STEP, RIGHT, SPEED)
	assert_float(_rider.progress()).is_equal(held)
	_body.move_and_slide()
	await get_tree().physics_frame
	await _ride(RIGHT, 2)
	assert_float(_rider.progress()).is_greater(held)

func test_a_release_mid_stair_leaves_the_tower_at_rest() -> void:
	assert_bool(await _board(RIGHT)).is_true()
	await _ride(RIGHT, 60)
	assert_float(_stair.angle()).is_greater(0.0)
	_rider.release()
	assert_float(_stair.angle()).is_equal(0.0)
