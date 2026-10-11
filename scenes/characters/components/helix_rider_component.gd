class_name HelixRiderComponent extends Node

## Holds its body on a HelixStair's axis while the tower turns around it (architecture/walkable-helix-stair, Revision);
## the body decides when to board.

enum Exit { RIDING, OFF_FOOT, OFF_HEAD }

## Px the body may end a step from where it was sent before `_u` waits for it.
const MISS := 1.0

## Seconds after leaving before an end can be boarded again, as ClimbComponent's regrab.
@export var regrab_delay := 0.3
## Px from an end's x within which it boards: the first ride step moves the feet this far at most.
@export var board_reach := 6.0
@export var sensor_path: NodePath = ^"../ClimbSensor"

var _stair: HelixStair
## Radians along the stair from its foot; the tower is turned by it.
var _u := 0.0
## 1 up, -1 down, 0 still, this step.
var _direction := 0
var _regrab := 0.0
## The horizontal sign held when the body left; it boards no end until that press changes.
var _held_at_leave := 0
## Where the last step sent the body; INF before the first step of a ride.
var _target := Vector2.INF

@onready var _body: CharacterBody2D = get_parent()
@onready var _sensor: Area2D = get_node(sensor_path)


func tick(delta: float, axis_x: float) -> void:
	_regrab = maxf(_regrab - delta, 0.0)
	if _sign(axis_x) != _held_at_leave:
		_held_at_leave = 0

func is_riding() -> bool:
	return _stair != null

## The end in reach that `axis` (x right, y down) presses onto its stair, or null: Up or the hand side at a foot, Down
## or the other side at a head.
func end_pressed_into(axis: Vector2) -> HelixEnd:
	if _regrab > 0.0:
		return null
	for area: Area2D in _sensor.get_overlapping_areas():
		var end := area as HelixEnd
		if end == null or not is_instance_valid(end.stair):
			continue
		if absf(_body.global_position.x - end.global_position.x) > board_reach:
			continue
		var onto := -1 if end.at_head else 1
		var x := _sign(axis.x)
		if x == _held_at_leave and absf(axis.y) < HelixSteer.VERTICAL:
			continue
		if HelixSteer.direction(axis, end.stair.hand) == onto:
			return end
	return null

func board(end: HelixEnd) -> void:
	_stair = end.stair
	_u = _stair.head_u() if end.at_head else 0.0
	_direction = 0
	_target = Vector2.INF
	_body.velocity = Vector2.ZERO

func release() -> void:
	if _stair == null:
		return
	if is_instance_valid(_stair):
		_stair.clear_rider(_u >= _stair.head_u())
	_stair = null
	_direction = 0
	_target = Vector2.INF
	_regrab = regrab_delay

## Moves the body up or down the axis at `run_speed` (px/s) by `axis`, or reports that it stepped off an end.
## While `held` (a hit, a death) it stays where it is.
func update(delta: float, axis: Vector2, run_speed: float, held: bool = false) -> Exit:
	if not is_instance_valid(_stair):
		_stair = null
		return Exit.OFF_FOOT
	if _target != Vector2.INF and _body.global_position.distance_to(_target) > MISS:
		# The body fell short of the last step, so _u waits for it (bugs/descending-from-the-helix-head-runs-in-place-on-the-gallery-then-drops-a-turn).
		_direction = 0
		_step_to(_target, delta)
		return Exit.RIDING
	if held:
		_direction = 0
		_step_to(_stair.stand_global(_u), delta)
		return Exit.RIDING
	var direction := HelixSteer.direction(axis, _stair.hand)
	var vertical := absf(axis.y) >= HelixSteer.VERTICAL
	if _u >= _stair.head_u() and direction > 0 and vertical and _stair.above() != null:
		# Up rides on up the stair standing on this head; the hand side still walks onto the floor (systems/helix-stair).
		_stair = _stair.above()
		_u = 0.0
	var head := _stair.head_u()
	if _u >= head and direction > 0:
		# The hand side walks onto the gallery, fresh or held; Up holds.
		if not vertical:
			_leave(_sign(axis.x), delta)
			return Exit.OFF_HEAD
		direction = 0
	_u = clampf(_u + direction * HelixMath.angular_speed(_stair.shape, run_speed) * delta, 0.0, head)
	if _u <= 0.0 and direction < 0:
		if not vertical or _stair.below() == null:
			_leave(_sign(axis.x), delta)
			return Exit.OFF_FOOT
		# Down rides on down the stair under this foot; the other side still walks onto the floor.
		_stair = _stair.below()
		_u = _stair.head_u()
	_direction = direction
	_step_to(_stair.stand_global(_u), delta)
	_stair.set_rider_angle(_u)
	return Exit.RIDING

## Whether the stair moves the body this step; its height changes only at the risers.
func is_moving() -> bool:
	return is_riding() and _direction != 0

## Radians along the stair; the tower's turn.
func progress() -> float:
	return _u

## Px the camera adds to the feet so it follows the axis height, which rises steadily, not the risers.
func frame_bias() -> float:
	if not is_riding():
		return 0.0
	return HelixMath.feet(_stair.shape, _u).y - HelixMath.stand(_stair.shape, _u).y

## The way the body faces as it climbs or descends; 0 keeps the facing.
func facing_axis() -> float:
	if not is_riding():
		return 0.0
	return float(_stair.hand * _direction)

## Steps off onto the floor or the gallery at an end (down off the bottom step at the foot); the body stays grounded,
## so no landing is read.
func _leave(held_x: int, delta: float) -> void:
	_body.velocity = (_stair.stand_global(_u) - _body.global_position) / delta
	release()
	_held_at_leave = held_x
	_body.apply_floor_snap()

## Sends the body to `point` this step. A step down from a floor is a teleport: a body resting on a one-way cannot
## be moved down into it (gotchas/a-body-resting-on-a-one-way-cannot-be-pushed-down-into-it), and the column holds no
## solid (HelixStair.check).
func _step_to(point: Vector2, delta: float) -> void:
	_target = point
	if point.y > _body.global_position.y + MISS and _body.is_on_floor():
		Character.teleport_body(_body, point)
	_body.velocity = (point - _body.global_position) / delta

func _sign(value: float) -> int:
	if is_zero_approx(value):
		return 0
	return 1 if value > 0.0 else -1
