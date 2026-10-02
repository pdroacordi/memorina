class_name Hitbox
extends Area2D
## Applies configured damage and knockback to overlapping hurtboxes.

signal connected(target: Hurtbox)

@export var damage: int = 1
@export var knockback_strength: float = 0.0
## Upward component, in px/s, added on top of the directional push. Separates
## the character from the floor so the shove reads as a hit rather than a slide.
@export var knockback_lift: float = 0.0
## Reapplies damage each physics frame while overlapping; the hurtbox's invulnerability sets the cadence.
@export var continuous: bool = false

## Below this horizontal direction magnitude, use a sideward push to avoid bouncing a target back into the hitbox.
const INSIDE_PUSH_X := 0.5
## Keeps near-centered hits moving sideways, with only a small vertical component.
const INSIDE_PUSH_Y := 0.35


func _physics_process(_delta: float) -> void:
	if not continuous or not monitoring:
		return
	for area: Area2D in get_overlapping_areas():
		# Only a hit that can land is reported: a body inside the box during its
		# i-frames is not being hit sixty times a second.
		if area is Hurtbox and not (area as Hurtbox).is_invulnerable():
			_hit(area)

func _on_area_entered(area: Area2D) -> void:
	_hit(area)

func _hit(area: Area2D) -> void:
	if not (area is Hurtbox):
		return

	var knockback: Vector2 = Vector2.ZERO
	if knockback_strength > 0.0 or knockback_lift > 0.0:
		knockback = _push_direction(area) * knockback_strength
		# Godot 2D y is down-positive, so lift is subtracted to push upward.
		knockback.y -= knockback_lift

	area.receive_hit(damage, knockback, self)
	connected.emit(area)

func _push_direction(area: Area2D) -> Vector2:
	var away := global_position.direction_to(area.global_position)
	if absf(away.x) >= INSIDE_PUSH_X:
		return away
	var side := signf(area.global_position.x - global_position.x)
	if is_zero_approx(side):
		side = signf(scale.x)
	return Vector2(side, clampf(away.y, -INSIDE_PUSH_Y, INSIDE_PUSH_Y)).normalized()

## Flips the parent scale so animated child collision transforms remain composed with the facing.
func _on_character_facing_changed(facing: int) -> void:
	scale.x = absf(scale.x) * facing
