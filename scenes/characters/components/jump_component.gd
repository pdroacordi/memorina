class_name JumpComponent
extends Node
## Owns ground jump timing and vertical motion; air jumps are separate abilities.

signal jumped(position: Vector2)

@export var stats: JumpStats

## Public: read by the owner's animation contract.
var is_jumping: bool = false

var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0

# The component is a direct child of the body it drives.
@onready var _body: Character = get_parent()


func tick_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = stats.coyote_time_max
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_buffer_timer = maxf(_buffer_timer - delta, 0.0)

func buffer_jump() -> void:
	_buffer_timer = stats.jump_buffer_max

func clear_buffer() -> void:
	_buffer_timer = 0.0

func has_buffered_jump() -> bool:
	return _buffer_timer > 0.0

func can_ground_jump(on_floor: bool) -> bool:
	return on_floor or _coyote_timer > 0.0

## Re-arms coyote time after a wall slide.
func refresh_coyote() -> void:
	_coyote_timer = stats.coyote_time_max

## Shared launch for ground and air jumps.
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

## Returns terminal velocity for camera fall-speed normalization.
func terminal_velocity() -> float:
	return stats.terminal_velocity
