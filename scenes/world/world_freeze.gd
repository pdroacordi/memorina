class_name WorldFreeze extends Node

## Owns the world clock for performance freezes and recalls; see docs/design/02_mecanicas.md sections 4 and 6.2.

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

## Reset the clock because WorldFreeze outlives room reloads.
func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false

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

## The tween ignores the clock it drives so slow motion does not slow its own ramp.
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
