class_name SafeGroundTracker extends Node

## Remembers the last firm ground its body stood on, for a hazard to send it
## back to. A child of the body, so it runs after the body has moved this frame
## (Godot processes a parent before its children) and reads a fresh floor.
##
## Firm means floor under BOTH probes, a margin either side of the feet, and
## neither floor something that will not be there on the way back: a collider
## in the UNSAFE group (FREEZE's ice, which thaws; a root bridge, a Redoma
## shell, anything that moves - a lift, a seesaw, a floating log). And never a
## spot inside a hazard, whatever is under it - the floor of a pool is firm
## ground - nor anywhere water can come back to (a well a shell holds dry, a
## basin the grey has drained). So the body never comes back on the lip of a
## ledge it would walk off, on ice that has since melted, or under water.

## Group of colliders that are never ground to come back to.
const UNSAFE := &"unsafe_ground"
## How far above the feet the probes start, so a foot resting exactly on the
## floor's surface still finds it.
const PROBE_LIFT := 2.0

## How far either side of the body's origin firm floor must reach, in world
## pixels: wider than the feet, so a respawn is never right at a lip.
@export var foot_half_width := 16.0
## How far below the feet the probes look for floor.
@export var probe_depth := 6.0
## Physics layers of the hazards (HazardZone) a spot must be outside of.
@export_flags_2d_physics var hazard_mask := 1024

## Pushed by the body: off while a hazard has it, so nothing it touches on the
## way down is remembered.
var enabled := true

var _last := Vector2.ZERO

@onready var _body: CharacterBody2D = get_parent()

## The judgement on what is under the feet, pure: firm floor under both
## probes. `left` / `right` are the colliders found under each, or null.
static func is_firm(left: Object, right: Object) -> bool:
	return _firm(left) and _firm(right)

static func _firm(ground: Object) -> bool:
	if ground == null:
		return false
	return not (ground is Node and (ground as Node).is_in_group(UNSAFE))

func _ready() -> void:
	_last = _body.global_position

func _physics_process(_delta: float) -> void:
	if not enabled or not _body.is_on_floor():
		return
	if is_firm(_floor_under(-foot_half_width), _floor_under(foot_half_width)) and not _in_hazard() and not _in_water_bed():
		_last = _body.global_position

func last_safe_position() -> Vector2:
	return _last

func _floor_under(offset_x: float) -> Object:
	var from := _body.global_position + Vector2(offset_x, -PROBE_LIFT)
	var query := PhysicsRayQueryParameters2D.create(
		from, from + Vector2(0.0, probe_depth + PROBE_LIFT), _body.collision_mask, [_body.get_rid()])
	var hit := _body.get_world_2d().direct_space_state.intersect_ray(query)
	return hit.get("collider") as Object

## Anywhere water CAN be: inside a body's painted level range, even while it
## is held out by a shell or drained by the grey. A floor the water comes back
## over would send Ivo back under it, inside a hazard he never enters again.
func _in_water_bed() -> bool:
	return WaterBody.at(_body, _body.global_position + Vector2(0.0, -PROBE_LIFT)) != null

func _in_hazard() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _body.global_position + Vector2(0.0, -PROBE_LIFT)
	query.collision_mask = hazard_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return not _body.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()
