class_name ClimbComponent extends Node

## Implements climbing on Enraizar roots (design 02 section 7.1); the body decides when to grab.

enum Exit { HOLDING, LET_GO, OVER_THE_TOP }

## px/s along what is held, in any direction.
@export var climb_speed := 80.0
## The hop that carries the body over the top of what it climbed, px; it lifts the feet over a one-way cell lying on a
## root pole's top from where the sensor leaves it (climb_component_test).
@export var top_hop_height := 54.0
## Regrab delay, in seconds, so held jump input cannot immediately reattach after a hop.
@export var regrab_delay := 0.3
## Pulls toward a pole's axis, px/s.
@export var pole_pull := 240.0
@export var sensor_path: NodePath = ^"../ClimbSensor"

var _held: Climbable
var _regrab := 0.0

@onready var _body: CharacterBody2D = get_parent()
@onready var _sensor: Area2D = get_node(sensor_path)

## Whether hands whose sensor came off with its bottom at `sensor_bottom` left over `top`, the highest part of the
## climbable still standing (a withered top rung makes the next one down the top); never when nothing is left (INF).
static func cleared_top(sensor_bottom: float, top: float) -> bool:
	return top < INF and sensor_bottom <= top

func tick(delta: float) -> void:
	_regrab = maxf(_regrab - delta, 0.0)

func is_climbing() -> bool:
	return _held != null

func grip() -> Climbable.Grip:
	return _held.grip if _held else Climbable.Grip.WALL

func can_grab() -> bool:
	return _regrab <= 0.0 and _reachable() != null

func grab() -> void:
	_held = _reachable()
	_body.velocity = Vector2.ZERO

func release() -> void:
	if _held:
		_held = null
		_regrab = regrab_delay

## Moves the body along what it holds with `axis` (x right, y down), or
## reports how it came off.
func update(delta: float, axis: Vector2) -> Exit:
	if not _still_held():
		var over_the_top := axis.y < -0.5 and _above_the_top()
		release()
		return Exit.OVER_THE_TOP if over_the_top else Exit.LET_GO
	var motion := axis.limit_length(1.0)
	if _held.grip == Climbable.Grip.POLE:
		motion.x = 0.0
		_body.global_position.x = move_toward(_body.global_position.x, _held_axis_x(), pole_pull * delta)
	_body.velocity = motion * climb_speed
	return Exit.HOLDING

func _reachable() -> Climbable:
	for area: Area2D in _sensor.get_overlapping_areas():
		if area is Climbable:
			return area
	return null

func _still_held() -> bool:
	return _held != null and is_instance_valid(_held) and _sensor.get_overlapping_areas().has(_held)

## Whether the hands came off above what is held: only that is climbing out of the top.
func _above_the_top() -> bool:
	if _held == null or not is_instance_valid(_held):
		return false
	var top := INF
	for child: Node in _held.get_children():
		var shape := child as CollisionShape2D
		if shape and not shape.disabled and shape.shape:
			top = minf(top, shape.global_position.y - shape.shape.get_rect().size.y * 0.5)
	return cleared_top(_sensor_bottom(), top)

# The sensor stops overlapping when its bottom passes the top, not its origin (bugs/the-climbs-over-the-top-hop-never-fires).
func _sensor_bottom() -> float:
	var bottom := -INF
	for child: Node in _sensor.get_children():
		var shape := child as CollisionShape2D
		if shape and shape.shape:
			bottom = maxf(bottom, shape.global_position.y + shape.shape.get_rect().end.y)
	return bottom if bottom > -INF else _sensor.global_position.y

## A pole is a single thin shape: its axis is where the body lines up.
func _held_axis_x() -> float:
	for child: Node in _held.get_children():
		var shape := child as CollisionShape2D
		if shape and not shape.disabled:
			return shape.global_position.x
	return _held.global_position.x
