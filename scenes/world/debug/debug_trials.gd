class_name DebugTrials extends Node

## Mounts song trial regions in debug builds; F10 (`debug_trials`) moves Ivo between them.

const SPAWN_GROUP := &"trial_spawn"

## The trials regions, in the order F10 visits them.
@export var regions: Array[PackedScene] = []
## Where the first region goes, and how far apart they sit.
@export var origin := Vector2(0, 6000)
@export var spacing := Vector2(2400, 0)
@export var world_path: NodePath
@export var camera_path: NodePath

var _next := 0

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	var world := get_node(world_path)
	for i: int in regions.size():
		var region := regions[i].instantiate() as Node2D
		region.position = origin + spacing * i
		world.add_child(region)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_trials"):
		return
	var spawns := get_tree().get_nodes_in_group(SPAWN_GROUP)
	var player := get_tree().get_first_node_in_group(Player.GROUP) as Player
	# Do not move a dead or sinking player.
	if spawns.is_empty() or player == null or player.is_dead() or player.is_sinking():
		return
	var spawn := spawns[_next % spawns.size()] as Node2D
	_next += 1
	player.global_position = spawn.global_position
	player.velocity = Vector2.ZERO
	var camera := get_node_or_null(camera_path) as GameCamera
	if camera:
		camera.snap()
	get_viewport().set_input_as_handled()
