class_name PulseEmitter extends Node

## Spawns world pulses for a song performer.

@export var pulse_scene: PackedScene
## Whether pulses apply Song.pulse_effect; guardian lesson pulses must not trigger their own effect.
@export var song_acts := true
## Whether pulses pause with the world; player pulses use world time (design 02 section 7.4).
@export var holds_in_pause := true

@onready var _spawner: Spawner = get_tree().get_first_node_in_group(Spawner.GROUP)

## Optional stats override the song's pulse shape.
func spawn_pulse(song: Song, at: Vector2, stats: PulseStats = null) -> void:
	if _spawner == null or pulse_scene == null or song == null:
		return
	var pulse: ColorPulse = _spawner.spawn(pulse_scene, at)
	pulse.performer = get_parent() as Node2D
	pulse.holds_in_pause = holds_in_pause
	pulse.start(song, stats, song_acts)
