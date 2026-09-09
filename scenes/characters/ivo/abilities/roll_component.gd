class_name RollComponent
extends Node
## A ground dash with invulnerability frames. Note the i-frames come from a
## Hurtbox:monitorable keyframe in the roll animation, NOT from this script —
## so roll_time and the baked animation length are coupled and must be
## changed together.

## The owner drives this from the save-game skill gate; the component itself
## must never know SaveSystem exists, so it stays reusable.
@export var enabled: bool = true
@export var stats: RollStats

var _roll_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: Character = get_parent()
@onready var _roll_speed: float = stats.roll_distance / stats.roll_time


func tick_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = stats.roll_coyote_time_max
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_buffer_timer = maxf(_buffer_timer - delta, 0.0)

	if _roll_timer > 0.0:
		_roll_timer = maxf(_roll_timer - delta, 0.0)
		if _roll_timer == 0.0:
			_cooldown_timer = stats.roll_cooldown
	elif _cooldown_timer > 0.0:
		_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)

func buffer_roll() -> void:
	_buffer_timer = stats.roll_buffer_max

## Lets the owner skip the whole attempt — including querying the skill gate —
## on the frames where no roll was asked for, which is most of them.
func has_buffered_roll() -> bool:
	return _buffer_timer > 0.0

func is_rolling() -> bool:
	return _roll_timer > 0.0

func is_on_cooldown() -> bool:
	return _cooldown_timer > 0.0

func try_roll(on_floor: bool, axis: float, facing: int) -> void:
	if _buffer_timer <= 0.0:
		return
	if not (on_floor or _coyote_timer > 0.0):
		return
	if not enabled:
		return
	if is_rolling() or is_on_cooldown():
		return

	_buffer_timer = 0.0
	_coyote_timer = 0.0

	var direction: float = axis
	var roll_direction: float = sign(direction) if direction else facing

	_body.velocity.x = roll_direction * _roll_speed
	_roll_timer = stats.roll_time
