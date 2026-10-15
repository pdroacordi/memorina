class_name PickupComponent extends Node

## Finds the item lying in reach; the body decides when to take it.

@export var sensor_path: NodePath = ^"../DoorSensor"

@onready var _sensor: Area2D = get_node(sensor_path)


## An ItemPickup in reach whose item still lies there; null when none.
func reachable() -> ItemPickup:
	for area: Area2D in _sensor.get_overlapping_areas():
		var found := area as ItemPickup
		if found != null and found.is_available():
			return found
	return null
