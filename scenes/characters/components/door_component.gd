class_name DoorComponent extends Node

## Finds the door in reach; the body decides when to take it and the composition root carries the travel out.

@export var sensor_path: NodePath = ^"../DoorSensor"

@onready var _sensor: Area2D = get_node(sensor_path)


## Door detected by this body's sensor, if any.
func reachable() -> Door:
	for area: Area2D in _sensor.get_overlapping_areas():
		var found := area as Door
		if found != null:
			return found
	return null
