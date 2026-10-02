class_name WallMobilityComponent
extends Node
## Wall slide and wall-jump mobility.

## Set by the owner from the saved skill gate.
@export var enabled: bool = true
## Base-gravity multiplier during a wall slide (0 sticks; 1 is normal gravity).
@export var wall_gravity_mult: float = 0.1

## Read by the owner's animation logic.
var is_sliding: bool = false

## Injected by the owner.
var jump: JumpComponent
var double_jump: DoubleJumpComponent

# The component is a direct child of the body it drives.
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

## Ends the slide after a jump or ground contact.
func stop() -> void:
	is_sliding = false

func _is_pushing_into_wall(axis: float) -> bool:
	return sign(axis * -1) == sign(_body.get_wall_normal().x)
