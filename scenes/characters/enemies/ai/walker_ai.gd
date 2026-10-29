class_name WalkerAI
extends EnemyAI
## A creature on the ground: wanders or holds home, closes in on x to its stop distance inside its leash,
## lunges along its facing, and never walks off a ledge.

var _wander_timer: float = 0.0
## Wander heading, -1/0/1.
var _wander_dir: float = 0.0


func handle_wall_contact() -> void:
	super()
	if _states.current == State.IDLE:
		_wander_dir = -_wander_dir

func _idle_tick(delta: float) -> void:
	if not stats.wanders:
		steer = Vector2.ZERO
		return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_wander_phase()
	if _blocked(_wander_dir):
		_wander_dir = -_wander_dir
	steer = Vector2(_wander_dir * _speed(), 0.0)

## Parks on horizontal distance, so a jump or a ledge above is not the target moving away
## (docs/knowledge/bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks.md).
func _approach_tick(_delta: float) -> void:
	var dx := _target.global_position.x - _body.global_position.x
	var dir := signf(dx)
	if absf(dx) <= stats.stop_distance or _past_leash(dir) or _blocked(dir):
		steer = Vector2.ZERO
		return
	steer = Vector2(dir * _speed(), 0.0)

func _home_tick(_delta: float) -> void:
	var dx := _home.x - _body.global_position.x
	var dir := signf(dx)
	if absf(dx) <= HOME_TOLERANCE * 0.5 or _blocked(dir):
		steer = Vector2.ZERO
		return
	steer = Vector2(dir * _speed(), 0.0)

func _active_tick(_delta: float) -> void:
	var move := _clock.move
	if move.lunge_speed > 0.0 and ledge_ahead:
		if move.ends_on_wall:
			_clock.end_active()
		steer = Vector2.ZERO
		return
	steer = Vector2(_move_side * move.lunge_speed, 0.0)

func _speed() -> float:
	return stats.locomotion.move_speed

## A ledge on the side it faces stops a step that way.
func _blocked(dir: float) -> bool:
	return ledge_ahead and not is_zero_approx(dir) and dir == _facing

## Whether a step toward `dir` would leave the leash.
func _past_leash(dir: float) -> bool:
	return stats.leash > 0.0 and (_body.global_position.x - _home.x) * dir >= stats.leash

func _pick_wander_phase() -> void:
	if randf() < 0.5:
		_wander_dir = [-1.0, 1.0].pick_random()
		_wander_timer = randf_range(stats.min_wander_duration, stats.max_wander_duration)
	else:
		_wander_dir = 0.0
		_wander_timer = randf_range(stats.min_idle_duration, stats.max_idle_duration)
