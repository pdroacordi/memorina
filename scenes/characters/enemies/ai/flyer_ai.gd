class_name FlyerAI
extends EnemyAI
## A creature on the wing: hovers at home on a slow bob, holds a point `hover_distance` beside its target at the
## target's chest height, and dashes along the aim it locked when the telegraph ended. FlightComponent adds the wind to
## the steer, so a current bends the dash (systems/air).

## Steer per px off the point it holds, px/s per px.
const HOLD_GAIN := 4.0

## Horizontal gap it keeps from its target, px.
@export var hover_distance: float = 128.0
## Bob amplitude while hovering at home, px.
@export var bob_height: float = 6.0
## Bob period, s.
@export var bob_period: float = 1.6

## Unit direction of the current dash.
var _aim: Vector2 = Vector2.RIGHT
## Where it holds during a telegraph.
var _hold: Vector2 = Vector2.ZERO
var _bob_time: float = 0.0


## The unit dash direction from `from` at a target whose feet are at `feet`.
static func aim_at(from: Vector2, feet: Vector2) -> Vector2:
	var aim := (feet + CHEST - from).normalized()
	return aim if not aim.is_zero_approx() else Vector2.RIGHT

## With a target it always faces it, so settling on its point never flips it.
func _get_facing_direction() -> float:
	if _clock.is_busy():
		return _move_side
	if _target != null:
		return _side.side
	return super()

func _away_from_home() -> bool:
	var away := _body.global_position.distance_to(_home)
	if stats.wanders:
		return stats.leash > 0.0 and away > stats.leash
	return away > HOME_TOLERANCE

func _idle_tick(delta: float) -> void:
	_bob_time += delta
	steer = _toward(_home + Vector2(0.0, sin(_bob_time * TAU / bob_period) * bob_height))

func _approach_tick(_delta: float) -> void:
	var point := _target.global_position + CHEST - Vector2(_side.side * hover_distance, 0.0)
	if stats.leash > 0.0:
		point = _home + (point - _home).limit_length(stats.leash)
	steer = _toward(point)

func _home_tick(_delta: float) -> void:
	steer = _toward(_home)

func _telegraph_tick(_delta: float) -> void:
	steer = _toward(_hold)

func _active_tick(_delta: float) -> void:
	steer = _aim * _clock.move.lunge_speed

## It drifts to a stop.
func _recover_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _enter_phase(phase: MoveClock.Phase) -> void:
	match phase:
		MoveClock.Phase.TELEGRAPH:
			_hold = _body.global_position
		MoveClock.Phase.ACTIVE:
			_aim = aim_at(_body.global_position, _target.global_position) if _target != null else Vector2(_move_side, 0.0)
			# The dash faces where it flies (bugs/a-flyer-dashes-tail-first-when-its-target-crosses-during-the-telegraph).
			if not is_zero_approx(_aim.x):
				_move_side = signf(_aim.x)

func _toward(point: Vector2) -> Vector2:
	return ((point - _body.global_position) * HOLD_GAIN).limit_length(stats.locomotion.move_speed)
