class_name PulseEmitter extends Node

## Turns "a song was played" into a pulse in the world. Mounted on whoever can
## play - Ivo today, a guardian later - and wired by a scene connection, the
## same shape as DustEmitter.
##
## Exists so that the thing that PLAYS a song never has to know how a pulse is
## built or where effects get parented.

@export var pulse_scene: PackedScene

@onready var _spawner: Spawner = get_tree().get_first_node_in_group(Spawner.GROUP)

func spawn_pulse(song: Song, at: Vector2) -> void:
	if _spawner == null or pulse_scene == null or song == null:
		return
	var pulse: ColorPulse = _spawner.spawn(pulse_scene, at)
	pulse.start(song)
