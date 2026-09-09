class_name DustEmitter
extends Node

@export var jump_particles : PackedScene
@export var land_particles : PackedScene

@onready var _spawner : Spawner = get_tree().get_first_node_in_group(Spawner.GROUP)

func spawn_jump_dust(at: Vector2) -> void:
	_spawn(jump_particles, at)

# _impact_speed is unused, but must stay in the signature: ivo.tscn connects
# Player's hard_landed(position, impact_speed) signal directly to this method,
# and trimming the parameter would silently break that editor connection.
# TODO: scale the landing dust (size/count) by impact speed for harder landings.
func spawn_land_dust(at: Vector2, _impact_speed: float) -> void:
	_spawn(land_particles, at)

func _spawn(scene: PackedScene, at: Vector2) -> void:
	if scene == null or _spawner == null:
		return

	_spawner.spawn(scene, at)
