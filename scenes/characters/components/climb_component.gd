class_name ClimbComponent extends Node

## Holding on to something climbable - Enraizar's root webs and pillars
## (design 02 section 7.1; a climbing state rather than stacked steps, by the
## user's choice). Generic, not a skill: nothing gates it but the roots.
##
## The body decides WHEN to grab (Player: up held, not rolling or hurt) and
## what a jump does; this owns being on it: moving along it at climb speed,
## no gravity, and noticing it is gone - withered roots let go, and climbing
## out of the top is its own exit, so the body can hop onto the ledge.

enum Exit { HOLDING, LET_GO, OVER_THE_TOP }

## px/s along what is held, in any direction.
@export var climb_speed := 80.0
## The hop that carries the body over the top of what it climbed, px.
@export var top_hop_height := 44.0
## Seconds after letting go before the same body can grab again, so a jump
## off with up still held does not snatch it straight back.
@export var regrab_delay := 0.3
## Pulls toward a pole's axis, px/s.
@export var pole_pull := 240.0
@export var sensor_path: NodePath = ^"../ClimbSensor"

var _held: Climbable
var _regrab := 0.0

@onready var _body: CharacterBody2D = get_parent()
@onready var _sensor: Area2D = get_node(sensor_path)

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
		var climbing_up := axis.y < -0.5
		release()
		return Exit.OVER_THE_TOP if climbing_up else Exit.LET_GO
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

## A pole is a single thin shape: its axis is where the body lines up.
func _held_axis_x() -> float:
	for child: Node in _held.get_children():
		var shape := child as CollisionShape2D
		if shape and not shape.disabled:
			return shape.global_position.x
	return _held.global_position.x
