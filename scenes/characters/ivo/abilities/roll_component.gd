class_name RollComponent
extends Node
## A ground dash with invulnerability frames, split into two phases: a
## movement burst (roll_time) that drives the character forward, followed by
## a recovery tail (roll_recovery_time) that lets it slide to a stop while
## still committed. Splitting the phases decouples travel distance, dash
## speed and animation length, which distance = speed x time would otherwise
## lock together. Note the i-frames come from a Hurtbox:monitorable keyframe
## in the roll animation, NOT from this script — so the animation length must
## equal roll_time + roll_recovery_time and the two must be changed together.

## The owner drives this from the save-game skill gate; the component itself
## must never know SaveSystem exists, so it stays reusable.
@export var enabled: bool = true
@export var stats: RollStats

var _roll_timer: float = 0.0
var _move_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _coyote_timer: float = 0.0
var _buffer_timer: float = 0.0

# Always a direct child of the body it drives, matching the existing
# $PlayerInput / $Hurtbox idiom in this codebase; an exported NodePath would
# only add an inspector-reassignable foot-gun with no swappable-target use case.
@onready var _body: Character = get_parent()
@onready var _roll_speed: float = stats.roll_distance / stats.roll_time
# Chosen so the character reaches a standstill exactly as the recovery window
# closes, rather than stopping early and sitting still or still sliding when
# control returns. Guarded against a zero recovery time, which would
# otherwise divide by zero; a large fallback rate stops the character
# effectively instantly instead.
@onready var _recovery_deceleration: float = (
	_roll_speed / stats.roll_recovery_time if stats.roll_recovery_time > 0.0 else 1.0e6
)


func tick_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_timer = stats.roll_coyote_time_max
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_buffer_timer = maxf(_buffer_timer - delta, 0.0)

	_move_timer = maxf(_move_timer - delta, 0.0)

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

## Covers the FULL roll — movement plus recovery — so this is what keeps the
## character committed: locked out of jumping, i-frames active, and the
## animation held in its roll state, for the whole duration.
func is_rolling() -> bool:
	return _roll_timer > 0.0

## True only during the movement burst; false once the character has entered
## its recovery slide even though is_rolling() is still true.
func is_moving() -> bool:
	return _move_timer > 0.0

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
	_move_timer = stats.roll_time
	_roll_timer = stats.roll_time + stats.roll_recovery_time

## Called every frame while the roll state is active, after the movement
## phase's one-time velocity set. Uses move_toward (linear) rather than the
## exponential decay idiom used elsewhere (see Character.apply_knockback_decay)
## specifically because it reaches exactly zero at a known time, matching
## _recovery_deceleration's rate to the end of the recovery window.
func update(delta: float) -> void:
	if is_moving():
		return
	_body.velocity.x = move_toward(_body.velocity.x, 0.0, _recovery_deceleration * delta)
