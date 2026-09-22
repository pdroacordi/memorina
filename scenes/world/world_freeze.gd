class_name WorldFreeze extends Node

## The one writer of the world's clock. The instrument freezes everything
## while a performance plays (docs/design/02_mecanicas.md section 6.2); a
## pause menu will call the same two methods. Whatever must keep moving
## through a freeze - the sheet, the instrument's sound, Ivo's idle, the
## memory layer - is marked PROCESS_MODE_ALWAYS in its own scene, not
## excepted here.
##
## The ability recall (section 4) slows the world instead of stopping it:
## "tempo desacelera". Everything keeps moving, just slowly, so the attack
## that forced the memory is still coming while the hand finds the button.
## The slow eases in and out over a few real milliseconds rather than
## snapping, so it reads as the world losing speed and not as a stutter.
##
## A hit-stop is the same clock held for a few real milliseconds so a blow
## has weight; it always returns to whatever the recall had set.

## How slow the world runs during a recall. 1.0 would be no signal at all.
@export_range(0.05, 1.0) var slow_scale: float = 0.2
## Real seconds the clock takes to ease into and out of the slow.
@export_range(0.0, 0.5) var slow_ramp: float = 0.12
## How slow, and for how many REAL seconds, the world holds on a landed hit.
@export_range(0.0, 0.5) var hit_stop_scale: float = 0.05
@export_range(0.0, 0.3) var hit_stop_time: float = 0.06

var _slowed: bool = false
var _stopping: bool = false
var _ramp: Tween

func freeze() -> void:
	get_tree().paused = true

func thaw() -> void:
	get_tree().paused = false

func slow() -> void:
	_slowed = true
	if not _stopping:
		_ease_to(slow_scale)

func restore() -> void:
	_slowed = false
	if not _stopping:
		_ease_to(1.0)

## A landed blow: the clock nearly stops for a moment, then resumes at the
## rate the recall (if any) wants. Overlapping hits do not stack.
func hit_stop() -> void:
	if _stopping or hit_stop_time <= 0.0:
		return
	_stopping = true
	_kill_ramp()
	Engine.time_scale = hit_stop_scale
	await get_tree().create_timer(hit_stop_time, true, false, true).timeout
	_stopping = false
	Engine.time_scale = slow_scale if _slowed else 1.0

## The tween ignores the very clock it is driving, or slowing down would
## slow its own ramp, and runs through a pause for the same reason the
## recall's window does.
func _ease_to(scale: float) -> void:
	_kill_ramp()
	if slow_ramp <= 0.0:
		Engine.time_scale = scale
		return
	_ramp = create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_ramp.tween_property(Engine, "time_scale", scale, slow_ramp)

func _kill_ramp() -> void:
	if _ramp != null:
		_ramp.kill()
		_ramp = null
