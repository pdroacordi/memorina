class_name SafeGroundTracker extends Node

## Tracks safe return ground; both probes must find firm ground outside hazards and possible water beds.

## Temporary or moving surfaces must not become respawn ground.
const UNSAFE := &"unsafe_ground"
## Probe start height above the feet in px.
const PROBE_LIFT := 2.0

## Required firm-floor half-width around the body origin in world px.
@export var foot_half_width := 16.0
## How far below the feet the probes look for floor.
@export var probe_depth := 6.0
## Physics layers of the hazards (HazardZone) a spot must be outside of.
@export_flags_2d_physics var hazard_mask := 1024

var enabled := true

var _last := Vector2.ZERO

@onready var _body: CharacterBody2D = get_parent()

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

## Excludes painted water beds even while temporarily drained or held out by a shell.
func _in_water_bed() -> bool:
	return WaterBody.at(_body, _body.global_position + Vector2(0.0, -PROBE_LIFT)) != null

func _in_hazard() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _body.global_position + Vector2(0.0, -PROBE_LIFT)
	query.collision_mask = hazard_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return not _body.get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()
