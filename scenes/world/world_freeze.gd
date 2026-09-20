class_name WorldFreeze extends Node

## The one writer of the world's clock. The instrument freezes everything
## while a performance plays (docs/design/02_mecanicas.md section 6.2); a
## pause menu will call the same two methods. Whatever must keep moving
## through a freeze - the sheet, the instrument's sound, Ivo's idle - is
## marked PROCESS_MODE_ALWAYS in its own scene, not excepted here.
##
## The ability recall (section 4) slows the world instead of stopping it:
## "tempo desacelera". Everything keeps moving, just slowly, so the attack
## that forced the memory is still coming while the hand finds the button.
##
## A hit-stop is the same clock held for a few real milliseconds so a blow
## has weight; it always returns to whatever the recall had set.

## How slow the world runs during a recall. 1.0 would be no signal at all.
@export_range(0.05, 1.0) var slow_scale: float = 0.25
## How slow, and for how many REAL seconds, the world holds on a landed hit.
@export_range(0.0, 0.5) var hit_stop_scale: float = 0.05
@export_range(0.0, 0.3) var hit_stop_time: float = 0.06

var _slowed: bool = false
var _stopping: bool = false

func freeze() -> void:
	get_tree().paused = true

func thaw() -> void:
	get_tree().paused = false

func slow() -> void:
	_slowed = true
	if not _stopping:
		Engine.time_scale = slow_scale

func restore() -> void:
	_slowed = false
	if not _stopping:
		Engine.time_scale = 1.0

## A landed blow: the clock nearly stops for a moment, then resumes at the
## rate the recall (if any) wants. Overlapping hits do not stack.
func hit_stop() -> void:
	if _stopping or hit_stop_time <= 0.0:
		return
	_stopping = true
	Engine.time_scale = hit_stop_scale
	await get_tree().create_timer(hit_stop_time, true, false, true).timeout
	_stopping = false
	Engine.time_scale = slow_scale if _slowed else 1.0
