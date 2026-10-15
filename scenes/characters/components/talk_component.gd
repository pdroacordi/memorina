class_name TalkComponent extends Node

## Finds the Talkable in reach; the body decides when to talk and the director runs the talk.

@export var sensor_path: NodePath = ^"../DoorSensor"

@onready var _sensor: Area2D = get_node(sensor_path)


## A Talkable in reach with something to say; null when none.
func reachable() -> Talkable:
	for area: Area2D in _sensor.get_overlapping_areas():
		var found := area as Talkable
		if found != null and found.has_talk():
			return found
	return null

## A Talkable in reach whose auto start is due; null when none.
func auto_ready() -> Talkable:
	for area: Area2D in _sensor.get_overlapping_areas():
		var found := area as Talkable
		if found != null and found.auto_ready():
			return found
	return null
