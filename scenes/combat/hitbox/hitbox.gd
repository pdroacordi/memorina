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
## A swing hits on entry and is over before anyone's i-frames lapse. A body
## that stays dangerous (a guardian's bulk) must keep hitting whoever stays
## inside it, so a continuous hitbox re-applies to every overlapping hurtbox
## each physics frame; the hurtbox's own invulnerability sets the cadence.
@export var continuous: bool = false

## Below this much sideways, a target counts as standing INSIDE the box
## rather than beside it: barely offset from its centre, so the direction to
## it comes out nearly vertical. Popped straight up, it lands back in the
## same box to be hit again the moment its i-frames lapse - which is exactly
## how a guardian lands on someone and hits them twice.
const INSIDE_PUSH_X := 0.5
## What a shove looks like in that case: decisively out to one side, with
## only a trace of the original up or down left in it. A half-sideways push
## of a 380 px/s knockback moved a body 29 px - not even clear of the bulk
## that threw it. Sideways, the same number moves it 66.
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

## Out to one side: whichever side the target is already leaning, or this
## box's own facing when it is dead centre. `knockback_lift` is what gets
## them off the floor, so the shove itself does not need the height.
func _push_direction(area: Area2D) -> Vector2:
	var away := global_position.direction_to(area.global_position)
	if absf(away.x) >= INSIDE_PUSH_X:
		return away
	var side := signf(area.global_position.x - global_position.x)
	if is_zero_approx(side):
		side = signf(scale.x)
	return Vector2(side, clampf(away.y, -INSIDE_PUSH_Y, INSIDE_PUSH_Y)).normalized()

## Mirrors THIS node's own transform rather than repositioning a child shape.
## Attack animations may keyframe the child CollisionShape2D's position,
## rotation and scale to match the swing frame-by-frame (authored assuming a
## right-facing swing) - flipping the child directly would fight those
## keyframes every frame. Flipping the parent's scale instead composes with
## any animated child transform for free, the same way a mirrored sprite
## doesn't need its individual frames re-authored per facing.
func _on_character_facing_changed(facing: int) -> void:
	scale.x = absf(scale.x) * facing
