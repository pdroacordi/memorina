class_name DustEmitter
extends Node

@export var jump_particles : PackedScene
@export var land_particles : PackedScene

@onready var _spawner : Spawner = get_tree().get_first_node_in_group(Spawner.GROUP)

func spawn_jump_dust(at: Vector2) -> void:
	_spawn(jump_particles, at)

# Keep `_impact_speed` to match the `hard_landed(position, impact_speed)` connection in `ivo.tscn`.
func spawn_land_dust(at: Vector2, _impact_speed: float) -> void:
	_spawn(land_particles, at)

func _spawn(scene: PackedScene, at: Vector2) -> void:
	if scene == null or _spawner == null:
		return

	_spawner.spawn(scene, at)
