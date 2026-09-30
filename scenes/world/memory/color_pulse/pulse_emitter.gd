class_name PulseEmitter extends Node

## Turns "a song was played" into a pulse in the world. Mounted on whoever can
## play - Ivo today, a guardian later - and wired by a scene connection, the
## same shape as DustEmitter.
##
## Exists so that the thing that PLAYS a song never has to know how a pulse is
## built or where effects get parented.

@export var pulse_scene: PackedScene
## Whether this emitter's pulses carry what the song DOES (Song.pulse_effect).
## Ivo's do. A guardian's do not: its lesson and its answer are the song
## remembered, not the song played - a Bloom Guardian teaching Enraizar must
## not grow roots across its own arena.
@export var song_acts := true
## Whether its pulses hold still while the world is frozen (a performance, a
## pause). Ivo's do: a song he played is WORLD time, like the water and the
## ice, so the next song's performance does not eat it - Soltar's load is still
## down when Vendaval's gale arrives (design 02 section 7.4). A guardian's do
## not: its lesson pulse is memory, and a lesson freezes time, not memory.
@export var holds_in_pause := true

@onready var _spawner: Spawner = get_tree().get_first_node_in_group(Spawner.GROUP)

## `stats` overrides the song's pulse shape (a lesson's slow, wide pulse).
func spawn_pulse(song: Song, at: Vector2, stats: PulseStats = null) -> void:
	if _spawner == null or pulse_scene == null or song == null:
		return
	var pulse: ColorPulse = _spawner.spawn(pulse_scene, at)
	pulse.performer = get_parent() as Node2D
	pulse.holds_in_pause = holds_in_pause
	pulse.start(song, stats, song_acts)
