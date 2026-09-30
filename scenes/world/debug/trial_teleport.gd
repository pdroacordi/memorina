class_name TrialTeleport extends Node

## Debug builds only: F10 (`debug_trials`) carries Ivo to the next song-trials
## room, cycling through every `trial_spawn` marker (one per trials region),
## so each song's puzzles are one key away from any save. The trials are a
## development space, not part of the world map; nothing else leads there.
##
## Reads its action itself rather than through PlayerInput because it is not a
## player verb - it is a tool, and it is inert outside debug builds.

const SPAWN_GROUP := &"trial_spawn"

var _next := 0

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_trials"):
		return
	var spawns := get_tree().get_nodes_in_group(SPAWN_GROUP)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	if spawns.is_empty() or player == null:
		return
	var spawn := spawns[_next % spawns.size()] as Node2D
	_next += 1
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	get_viewport().set_input_as_handled()
