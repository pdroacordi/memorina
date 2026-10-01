class_name SitComponent extends Node

## Sitting on a seat (a bench, design 02 "Pontos de restauração"). Generic,
## like ClimbComponent: the seat is only a place on the Interactable layer,
## found through this body's own sensor, and this owns being on it - the body
## stands on the seat's spot facing its way, and the seat knows it is taken so
## its prompt goes away.
##
## The body decides WHEN to sit and what gets it up (Player: down pressed,
## still on the floor, instrument away); the composition root decides what a
## rest does.

@export var sensor_path: NodePath = ^"../SeatSensor"

var _seat: Seat

@onready var _body: Character = get_parent()
@onready var _sensor: Area2D = get_node(sensor_path)


func is_sitting() -> bool:
	return _seat != null

func seat() -> Seat:
	return _seat

## The seat within reach, if any.
func reachable() -> Seat:
	for area: Area2D in _sensor.get_overlapping_areas():
		var found := area as Seat
		if found != null and not found.is_occupied():
			return found
	return null

## Sits on `seat`: the body is put on its spot, facing its way, and holds still.
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
