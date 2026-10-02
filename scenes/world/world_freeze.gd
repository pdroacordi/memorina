class_name WorldFreeze extends Node

## Owns the world clock for performance freezes, menu holds and recalls; see docs/design/02_mecanicas.md sections 4 and 6.2.
## Freeze stops time and keeps memory moving; hold stops everything (docs/knowledge/architecture/pause-menu-worldfreeze-reuse.md).

## How slow the world runs during a recall. 1.0 would be no signal at all.
@export_range(0.05, 1.0) var slow_scale: float = 0.2
## Real seconds the clock takes to ease into and out of the slow.
@export_range(0.0, 0.5) var slow_ramp: float = 0.12
## How slow, and for how many REAL seconds, the world holds on a landed hit.
@export_range(0.0, 0.5) var hit_stop_scale: float = 0.05
@export_range(0.0, 0.3) var hit_stop_time: float = 0.06

## Static so ALWAYS nodes that run on real time (audio) can pull it without a node path.
static var _held: bool = false

var _slowed: bool = false
var _stopping: bool = false
var _frozen: bool = false
var _ramp: Tween


## True while a menu holds the world.
static func is_held() -> bool:
	return _held

## Reset the clock because WorldFreeze outlives room reloads.
func _ready() -> void:
	_held = false
	Engine.time_scale = 1.0
	get_tree().paused = false

## A world that leaves the tree (death, quit to title) leaves a running clock behind.
func _exit_tree() -> void:
	_kill_ramp()
	_held = false
	Engine.time_scale = 1.0
	get_tree().paused = false

## A performance: time stops at scale 1, so ALWAYS memory and the performance are not slowed by a recall.
func freeze() -> void:
	assert(not get_tree().paused, "Each freeze has one owner; the tree is already paused")
	_frozen = true
	_kill_ramp()
	Engine.time_scale = _running_scale()
	get_tree().paused = true

## Returns to the hit-stop or the recall's slow if either is still on.
func thaw() -> void:
	_frozen = false
	get_tree().paused = false
	Engine.time_scale = _running_scale()

## A menu: the tree pauses and the scale drops to 0, so ALWAYS nodes and scaled tweens stop too.
func hold() -> void:
	assert(not get_tree().paused, "Each hold has one owner; the tree is already paused")
	_held = true
	_kill_ramp()
	Engine.time_scale = _running_scale()
	get_tree().paused = true

func release() -> void:
	_held = false
	get_tree().paused = false
	Engine.time_scale = _running_scale()

func slow() -> void:
	_slowed = true
	if not _stopping and not _frozen and not _held:
		_ease_to(slow_scale)

func restore() -> void:
	_slowed = false
	if not _stopping and not _frozen and not _held:
		_ease_to(1.0)

## A landed blow: the clock nearly stops for a moment, then resumes at the
## rate the recall (if any) wants. Overlapping hits do not stack.
func hit_stop() -> void:
	if _stopping or hit_stop_time <= 0.0:
		return
	_stopping = true
	_kill_ramp()
	Engine.time_scale = _running_scale()
	await get_tree().create_timer(hit_stop_time, true, false, true).timeout
	_stopping = false
	Engine.time_scale = _running_scale()

func _running_scale() -> float:
	if _held:
		return 0.0
	if _frozen:
		return 1.0
	if _stopping:
		return hit_stop_scale
	return slow_scale if _slowed else 1.0

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
