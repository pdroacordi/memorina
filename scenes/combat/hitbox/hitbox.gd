class_name Hitbox
extends Area2D
## Generic damage-dealing area. Drop this under any attack, hazard or
## projectile and configure damage/knockback per instance instead of writing
## a new script for each one.

@export var damage: int = 1
@export var knockback_strength: float = 0.0


func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return

	var knockback: Vector2 = Vector2.ZERO
	if knockback_strength > 0.0:
		knockback = global_position.direction_to(area.global_position) * knockback_strength

	area.receive_hit(damage, knockback, self)
