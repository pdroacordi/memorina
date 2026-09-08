class_name JumpComponent
extends Node
## Owns ONE jump plus the vertical-motion feel around it: the gravity curve,
## coyote time, input buffering and jump-cut. A second, mid-air jump is NOT
## here — that is a gated ability composed separately, reusing launch()/
## jump_force() rather than duplicating them.

signal jumped(position: Vector2)

@export var stats: JumpStats

## Public: read by the owner's animation contract.
var is_jumping: bool = false

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: Character = get_parent()


func tick_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = stats.coyote_time_max
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_buffer_timer = maxf(_buffer_timer - delta, 0.0)

func buffer_jump() -> void:
	_buffer_timer = stats.jump_buffer_max

func has_buffered_jump() -> bool:
	return _buffer_timer > 0.0

func can_ground_jump(on_floor: bool) -> bool:
	return on_floor or _coyote_timer > 0.0

## Wall-sliding re-arms the coyote window so you can jump off a wall, so the
## owner needs a way to say so without reaching into the timer.
func refresh_coyote() -> void:
	_coyote_timer = stats.coyote_time_max

## Shared launch used by BOTH a ground jump and, later, a mid-air ability
## jump — exposed publicly so a separately-composed air-jump ability reuses
## the exact same launch and force formula instead of duplicating it.
func launch(height: float) -> void:
	_body.velocity.y = jump_force(height)
	is_jumping = true
	_coyote_timer = 0.0
	_buffer_timer = 0.0

func try_ground_jump(on_floor: bool) -> bool:
	if not can_ground_jump(on_floor):
		return false

	launch(stats.jump_height)
	jumped.emit(_body.global_position)
	return true

func jump_force(height: float) -> float:
	var gravity_rise := _body.base_gravity() * stats.rise_gravity_mult
	return sqrt(gravity_rise * height * 2.0) * -1.0

func cut_jump() -> void:
	if is_jumping and _body.velocity.y < 0.0:
		_body.velocity.y *= stats.jump_cut_mult

func apply_gravity(delta: float) -> void:
	var gravity_mult := stats.fall_gravity_mult if _body.velocity.y >= 0.0 else stats.rise_gravity_mult

	if absf(_body.velocity.y) < stats.apex_threshold:
		gravity_mult *= stats.apex_gravity_mult

	var gravity := _body.base_gravity() * gravity_mult

	_body.velocity.y += gravity * delta
	_body.velocity.y  = min(_body.velocity.y, stats.terminal_velocity)

	if is_jumping and _body.velocity.y >= 0.0:
		is_jumping = false

## The owner's camera-intent code needs terminal velocity to normalise fall
## speed; a one-hop accessor beats reaching through `.stats` from outside.
func terminal_velocity() -> float:
	return stats.terminal_velocity
