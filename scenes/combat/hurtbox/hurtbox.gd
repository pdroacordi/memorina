class_name Hurtbox
extends Area2D

signal hit_received(damage: int, knockback: Vector2, source: Node2D)

@export var invulnerability_time: float = 0.0

var _invulnerability_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_invulnerability_timer -= delta

func is_invulnerable() -> bool:
	return _invulnerability_timer > 0.0

func receive_hit(damage: int, knockback: Vector2 = Vector2.ZERO, source: Node2D = null) -> void:
	if is_invulnerable():
		return

	hit_received.emit(damage, knockback, source)

	if invulnerability_time > 0.0:
		_invulnerability_timer = invulnerability_time
