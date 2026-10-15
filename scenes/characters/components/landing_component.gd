class_name LandingComponent
extends Node
## Detects hard landings and recovery; call after move_and_slide() updates floor state.

signal hard_landed(position: Vector2, impact_speed: float)

@export var stats: LandingStats

var _last_fall_speed: float = 0.0
var _was_on_floor: bool = true
var _just_landed: bool = false
var _recovery_timer: float = 0.0
# Soft-landing zones (SoftLanding) the body is inside: a landing in one is never hard.
var _soft_zones: int = 0

# The driven body is always the parent; an exported NodePath could silently target the wrong node.
@onready var _body: Character = get_parent()


func tick_timer(delta: float, on_floor: bool) -> void:
	if _recovery_timer > 0.0:
		_recovery_timer = _recovery_timer - delta if on_floor else 0.0

func sample_fall_speed(vertical_velocity: float) -> void:
	_last_fall_speed = maxf(vertical_velocity, 0.0)

func check_landing(on_floor: bool) -> void:
	_just_landed = on_floor and not _was_on_floor
	if _just_landed and LandingRule.is_hard(_last_fall_speed, stats.hard_land_speed, _soft_zones):
		_recovery_timer = stats.hard_land_time
		hard_landed.emit(_body.global_position, _last_fall_speed)
	_was_on_floor = on_floor

## The body entered a soft-landing zone.
func enter_soft_zone() -> void:
	_soft_zones += 1

## The body left a soft-landing zone.
func exit_soft_zone() -> void:
	_soft_zones = maxi(_soft_zones - 1, 0)

## Whether the body is inside at least one soft-landing zone.
func in_soft_zone() -> bool:
	return _soft_zones > 0

func cancel_recovery() -> void:
	_recovery_timer = 0.0

func is_recovering() -> bool:
	return _recovery_timer > 0.0

func just_landed() -> bool:
	return _just_landed
