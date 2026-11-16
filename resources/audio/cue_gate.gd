class_name CueGate
extends RefCounted
## Refuses a cue started again within its cooldown, on an injected clock.

## Returns the clock's now, in real seconds.
var _now: Callable
## Last start per cue, by instance id, in the clock's seconds.
var _started: Dictionary[int, float] = {}


func _init(now: Callable = CueGate.real_seconds) -> void:
	_now = now

static func real_seconds() -> float:
	return Time.get_ticks_usec() / 1_000_000.0

## True when `cue` may start now, and records the start.
func try_start(cue: SoundCue) -> bool:
	var now: float = _now.call()
	var id := cue.get_instance_id()
	if cue.cooldown > 0.0 and _started.has(id) and now - _started[id] < cue.cooldown:
		return false
	_started[id] = now
	return true
