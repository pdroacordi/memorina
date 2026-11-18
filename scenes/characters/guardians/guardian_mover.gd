class_name GuardianMover
extends Node
## Moves its guardian through a strike: the legacy lunge and leap, or the MotionPath its move's GuardianMotion planned.
## Called down from Guardian._process_motion in the same frame, so it never reads a stale parent.

## Px from the arena's edge ahead within which a body counts as against it.
const EDGE_BAND := 6.0

## The strike being moved; null outside one.
var _attack: GuardianAttack = null
var _path: MotionPath = null
## The feet the path is offset from; moved by a blink.
var _start: Vector2 = Vector2.ZERO
## Scaled s into the strike at the last drive.
var _elapsed: float = 0.0
var _blinked: bool = false
var _take_off_y: float = 0.0
## Left the floor during this strike, and touched it again this frame.
var _airborne: bool = false
var _landed: bool = false
## Physics frame of the last drive; a path holds the body only on a frame it was driven.
var _driven_frame: int = -1
## Px from the feet's x to either side of the body.
var _half_width: float = 0.0

@onready var _guardian: Guardian = get_parent()


func _ready() -> void:
	_half_width = _guardian.body_rect().size.x * 0.5


## The strike of `attack` begins; `ctx` is planned against when the move has a motion, else it may be null.
func begin(attack: GuardianAttack, ctx: MotionContext) -> void:
	_attack = attack
	_path = null
	_elapsed = 0.0
	_blinked = false
	_airborne = false
	_landed = false
	if attack.motion != null and ctx != null:
		_path = attack.motion.plan(ctx)
		_start = ctx.feet
		_take_off_y = ctx.feet.y
		return
	# A leap: the swing carries it over the player (lunge_speed does the horizontal half). Gravity brings it down
	# inside the same clip.
	if attack.leap_impulse > 0.0 and _guardian.is_on_floor():
		_guardian.velocity.y = -attack.leap_impulse

## The strike ended or was cancelled.
func end() -> void:
	_attack = null
	_path = null
	_airborne = false
	_landed = false

## Writes the body's velocity for this frame, `elapsed` scaled s into the strike.
func drive(delta: float, elapsed: float) -> void:
	if _attack == null:
		return
	_elapsed = elapsed
	_driven_frame = Engine.get_physics_frames()
	if _path == null:
		if _attack.lunge_speed > 0.0 and elapsed >= _attack.lunge_delay:
			_guardian.velocity.x = _guardian.facing * _attack.lunge_speed
		return
	if not _blinked and _path.blink_at >= 0.0 and elapsed >= _path.blink_at:
		_blinked = true
		_guardian.teleport(_start + _path.blink_to)
		_face_player()
	var target := _start + _path.at(elapsed)
	var step := (target - _guardian.global_position) / maxf(delta, 0.0001)
	_guardian.velocity.x = step.x
	if _path.holds_vertical(elapsed):
		_guardian.velocity.y = step.y

## Called after the body moved: tracks a landing inside the strike.
func after_move() -> void:
	_landed = false
	if _attack == null:
		return
	if not _guardian.is_on_floor():
		_airborne = true
	elif _airborne:
		_airborne = false
		_landed = true

## The path owns the vertical motion now: gravity waits. A strike left undriven (out of the pressure, Ivo out of the
## arena) releases it.
func owns_vertical() -> bool:
	return _holds() and _path.holds_vertical(_elapsed)

## A blink's out-to-in: nothing hits it and it hurts nothing.
func is_intangible() -> bool:
	return _holds() and _path.is_intangible(_elapsed)

## The path passes through the world above its take-off floor now.
func passes_through() -> bool:
	return _holds() and _attack.motion.passes_through() and _path.holds_vertical(_elapsed)

func take_off_y() -> float:
	return _take_off_y

## Touched the floor this frame after leaving it during the strike.
func just_landed() -> bool:
	return _landed

## Against a wall it faces, or within EDGE_BAND of `arena`'s edge ahead (an empty arena has no edge).
func against_wall(arena: Rect2) -> bool:
	var facing := _guardian.facing
	if _guardian.is_on_wall() and signf(_guardian.get_wall_normal().x) == -facing:
		return true
	if arena.size.x <= 0.0:
		return false
	var x := _guardian.global_position.x
	if facing > 0:
		return arena.end.x - (x + _half_width) <= EDGE_BAND
	return (x - _half_width) - arena.position.x <= EDGE_BAND

## A path that was driven this physics frame; the hit flush of the same frame still reads it.
func _holds() -> bool:
	return _path != null and _driven_frame == Engine.get_physics_frames()

func _face_player() -> void:
	var ivo := _guardian.fought_player()
	if ivo != null:
		_guardian.face_towards(ivo.global_position.x - _guardian.global_position.x)
