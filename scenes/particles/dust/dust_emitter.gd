class_name DustEmitter
extends Node

@export var jump_particles : PackedScene
@export var land_particles : PackedScene
@export var min_land_speed : float = 800.0

@onready var _spawner : Spawner = get_tree().get_first_node_in_group(Spawner.GROUP)

func spawn_jump_dust(at: Vector2) -> void:
	_spawn(jump_particles, at)

func spawn_land_dust(at: Vector2, impact_speed: float) -> void:
	if impact_speed < min_land_speed:
		return

	_spawn(land_particles, at)

func _spawn(scene: PackedScene, at: Vector2) -> void:
	if scene == null or _spawner == null:
		return

	_spawner.spawn(scene, at)
