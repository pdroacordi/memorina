class_name CueTracker extends RefCounted

## Cues are ascending playback seconds; each index is reported once, and backward positions report nothing.

var _cues: PackedFloat32Array
var _next: int = 0

func _init(cues: PackedFloat32Array) -> void:
	_cues = cues
	for i: int in range(1, cues.size()):
		assert(cues[i] > cues[i - 1], "Cues must be strictly ascending.")

## Unreported cue indices at or before `position`, in order.
func advance(position: float) -> PackedInt32Array:
	var crossed := PackedInt32Array()
	while _next < _cues.size() and _cues[_next] <= position:
		crossed.append(_next)
		_next += 1
	return crossed

func is_done() -> bool:
	return _next >= _cues.size()

func reset() -> void:
	_next = 0
