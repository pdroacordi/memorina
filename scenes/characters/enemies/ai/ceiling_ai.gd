class_name CeilingAI
extends EnemyAI
## A creature that hangs from a ceiling: waits at its anchor until a target is inside its swoop's reach below, drops,
## swoops along a SwoopPath through the target's chest where it was when the drop ended, and flies back to hang.

## Steer per px off the path or the anchor, px/s per px.
const CATCH_UP := 8.0
## Distance to the anchor under which it stops steering, px.
const SETTLE := 1.0

var _path: SwoopPath = null
## Time into the current swoop, s.
var _path_time: float = 0.0
## Time into flying the swoop back, s.
var _return_time: float = 0.0


## The steer that keeps a flyer at `position` on `path` at `t` s: the path's velocity plus a pull back onto it.
static func swoop_steer(path: SwoopPath, t: float, position: Vector2) -> Vector2:
	return path.velocity_at(t) + (path.point_at(t) - position) * CATCH_UP

func _away_from_home() -> bool:
	return _body.global_position.distance_to(_home) > HOME_TOLERANCE

func _idle_tick(delta: float) -> void:
	steer = _homeward(delta)

## It never chases: it waits at the anchor for the target to come under it.
func _approach_tick(delta: float) -> void:
	steer = _homeward(delta)

func _home_tick(delta: float) -> void:
	steer = _homeward(delta)

func _telegraph_tick(_delta: float) -> void:
	steer = Vector2.ZERO

func _active_tick(delta: float) -> void:
	_path_time += delta
	if _path == null or _path.is_done(_path_time):
		_clock.end_active()
		steer = Vector2.ZERO
		return
	steer = swoop_steer(_path, _path_time, _body.global_position)

func _recover_tick(delta: float) -> void:
	steer = _homeward(delta)

func _enter_phase(phase: MoveClock.Phase) -> void:
	if phase != MoveClock.Phase.ACTIVE:
		return
	var from := _body.global_position
	var through := _target.global_position + CHEST if _target != null else from + Vector2(_move_side * 64.0, 128.0)
	_path = SwoopPath.new(from, through, _clock.move.lunge_speed)
	_path_time = 0.0
	_return_time = 0.0
	# The swoop faces where it flies (bugs/a-flyer-dashes-tail-first-when-its-target-crosses-during-the-telegraph).
	if not is_equal_approx(through.x, from.x):
		_move_side = signf(through.x - from.x)

# Back along the swoop it just flew, which is clear, then onto the anchor (bugs/the-icicle-bat-never-flies-home-after-a-swoop).
func _homeward(delta: float) -> Vector2:
	if _path != null and _return_time < _path.duration:
		_return_time += delta
		var t := maxf(_path.duration - _return_time, 0.0)
		return -_path.velocity_at(t) + (_path.point_at(t) - _body.global_position) * CATCH_UP
	return _toward(_home)

func _toward(point: Vector2) -> Vector2:
	var offset := point - _body.global_position
	if offset.length() < SETTLE:
		return Vector2.ZERO
	return (offset * CATCH_UP).limit_length(stats.locomotion.move_speed)
