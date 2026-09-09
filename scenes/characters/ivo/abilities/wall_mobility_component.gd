class_name WallMobilityComponent
extends Node
## Clinging to and sliding down a wall, plus re-arming the air options that
## make a wall jump possible. Named "mobility" rather than "slide" because the
## unlock covers both the slide and jumping away from the wall.

## The owner drives this from the save-game skill gate; the component itself
## must never know SaveSystem exists, so it stays reusable.
@export var enabled: bool = true
## Multiplier on base gravity while clinging to a wall. Low values give a slow,
## controlled slide; 0.0 would stick to the wall entirely. A single scalar, so
## a plain export rather than a one-field Resource, which would be ceremony.
@export var wall_gravity_mult: float = 0.1

## Public: read by the owner's animation contract.
var is_sliding: bool = false

## Injected by the owner, which as composition root is the only thing that
## should know the full wiring graph; the component does not go looking for
## siblings.
var jump: JumpComponent
var double_jump: DoubleJumpComponent

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: Character = get_parent()


func update(delta: float, axis: float) -> bool:
	if is_sliding:
		if not _body.is_on_wall() or sign(_body.get_wall_normal().x) == sign(axis):
			is_sliding = false
		else:
			_body.velocity.y += _body.base_gravity() * delta * wall_gravity_mult
			jump.refresh_coyote()
			double_jump.refresh()
	elif (
		enabled
		and _body.is_on_wall()
		and _body.velocity.y >= 0
		and _is_pushing_into_wall(axis)
	):
		is_sliding = true
		jump.refresh_coyote()
		double_jump.refresh()
		_body.velocity.y = min(_body.velocity.y, 0)

	return is_sliding

## Jumping away or touching the ground ends the slide, and the owner drives that.
func stop() -> void:
	is_sliding = false

func _is_pushing_into_wall(axis: float) -> bool:
	return sign(axis * -1) == sign(_body.get_wall_normal().x)
