class_name SitComponent extends Node

## Owns seat occupancy and positioning; the body decides when to sit and the composition root defines rest effects.

@export var sensor_path: NodePath = ^"../SeatSensor"

var _seat: Seat

@onready var _body: Character = get_parent()
@onready var _sensor: Area2D = get_node(sensor_path)


func is_sitting() -> bool:
	return _seat != null

func seat() -> Seat:
	return _seat

## Unoccupied seat detected by this body's sensor, if any.
func reachable() -> Seat:
	for area: Area2D in _sensor.get_overlapping_areas():
		var found := area as Seat
		if found != null and not found.is_occupied():
			return found
	return null

## Places the body at `seat`, faces it toward the seat direction, and stops movement.
func sit(on: Seat) -> void:
	stand()
	_seat = on
	_seat.set_occupied(true)
	_body.global_position = on.global_position
	_body.velocity = Vector2.ZERO
	_body.face_towards(on.facing)

func stand() -> void:
	if _seat == null:
		return
	if is_instance_valid(_seat):
		_seat.set_occupied(false)
	_seat = null
