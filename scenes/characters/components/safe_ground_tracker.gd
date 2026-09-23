class_name SafeGroundTracker extends Node

## Remembers the last firm ground its body stood on, for a hazard to send it
## back to. A child of the body, so it runs after the body has moved this frame
## (Godot processes a parent before its children) and reads a fresh floor.
##
## Firm means BOTH edges of the feet are over floor, and neither floor is
## something that will not be there on the way back: a collider in the UNSAFE
## group (FREEZE's ice, which thaws). So the body never comes back on the lip
## of a ledge it would slide off, nor on ice that has since melted.

## Group of colliders that are never ground to come back to.
const UNSAFE := &"unsafe_ground"

## Half the width of the feet, in world pixels: where the two floor probes
## are cast either side of the body's origin.
@export var foot_half_width := 10.0
## How far below the feet the probes look for floor.
@export var probe_depth := 6.0

## Pushed by the body: off while a hazard has it, or a body sinking to the
## floor of a pool would remember the bottom of the pool as firm ground.
var enabled := true

var _last := Vector2.ZERO

@onready var _body: CharacterBody2D = get_parent()

func _ready() -> void:
	_last = _body.global_position

func _physics_process(_delta: float) -> void:
	if not enabled or not _body.is_on_floor():
		return
	if is_safe(true, _floor_under(-foot_half_width), _floor_under(foot_half_width)):
		_last = _body.global_position

func last_safe_position() -> Vector2:
	return _last

## The judgement itself, pure: standing, with firm floor under both feet.
## `left` / `right` are the colliders found under each foot, or null.
static func is_safe(on_floor: bool, left: Object, right: Object) -> bool:
	return on_floor and _firm(left) and _firm(right)

static func _firm(ground: Object) -> bool:
	if ground == null:
		return false
	return not (ground is Node and (ground as Node).is_in_group(UNSAFE))

func _floor_under(offset_x: float) -> Object:
	var from := _body.global_position + Vector2(offset_x, -2.0)
	var query := PhysicsRayQueryParameters2D.create(
		from, from + Vector2(0.0, probe_depth + 2.0), _body.collision_mask, [_body.get_rid()])
	var hit := _body.get_world_2d().direct_space_state.intersect_ray(query)
	return hit.get("collider") as Object
