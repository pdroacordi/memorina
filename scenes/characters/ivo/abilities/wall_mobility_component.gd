class_name WallMobilityComponent
extends Node
## Wall slide and wall-jump mobility.

## Least |normal.x| of a slide collision that counts as a wall.
const WALL_NORMAL_X := 0.7

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
	var wall := _grip_normal()
	if is_sliding:
		if wall == Vector2.ZERO or sign(wall.x) == sign(axis):
			is_sliding = false
		else:
			_body.velocity.y += _body.base_gravity() * delta * wall_gravity_mult
			jump.refresh_coyote()
			double_jump.refresh()
	elif (
		enabled
		and wall != Vector2.ZERO
		and _body.velocity.y >= 0
		and sign(axis * -1) == sign(wall.x)
	):
		is_sliding = true
		jump.refresh_coyote()
		double_jump.refresh()
		_body.velocity.y = min(_body.velocity.y, 0)

	return is_sliding

## Ends the slide after a jump or ground contact.
func stop() -> void:
	is_sliding = false

# The normal of a wall this step's slide touched that is not an invisible world edge (WorldEdges), else ZERO: an edge is
# never slid on, wall-jumped from or a refresh of the air jump.
func _grip_normal() -> Vector2:
	if not _body.is_on_wall():
		return Vector2.ZERO
	for i: int in _body.get_slide_collision_count():
		var hit := _body.get_slide_collision(i)
		if absf(hit.get_normal().x) <= WALL_NORMAL_X:
			continue
		if PhysicsServer2D.body_get_collision_layer(hit.get_collider_rid()) & WorldEdges.LAYER == 0:
			return hit.get_normal()
	return Vector2.ZERO
