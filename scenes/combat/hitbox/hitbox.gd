class_name Hitbox
extends Area2D
## Generic damage-dealing area. Drop this under any attack, hazard or
## projectile and configure damage/knockback per instance instead of writing
## a new script for each one.

## Generic on-hit report, useful beyond damage itself (e.g. a pogo bounce) -
## this signal only ever says a hit landed and on whom, never why that matters.
signal connected(target: Hurtbox)

@export var damage: int = 1
@export var knockback_strength: float = 0.0
## Upward component, in px/s, added on top of the directional push. Separates
## the character from the floor so the shove reads as a hit rather than a slide.
@export var knockback_lift: float = 0.0


func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return

	var knockback: Vector2 = Vector2.ZERO
	if knockback_strength > 0.0 or knockback_lift > 0.0:
		knockback = global_position.direction_to(area.global_position) * knockback_strength
		# Godot 2D y is down-positive, so lift is subtracted to push upward.
		knockback.y -= knockback_lift

	area.receive_hit(damage, knockback, self)
	connected.emit(area)

## Mirrors THIS node's own transform rather than repositioning a child shape.
## Attack animations may keyframe the child CollisionShape2D's position,
## rotation and scale to match the swing frame-by-frame (authored assuming a
## right-facing swing) - flipping the child directly would fight those
## keyframes every frame. Flipping the parent's scale instead composes with
## any animated child transform for free, the same way a mirrored sprite
## doesn't need its individual frames re-authored per facing.
func _on_character_facing_changed(facing: int) -> void:
	scale.x = absf(scale.x) * facing
