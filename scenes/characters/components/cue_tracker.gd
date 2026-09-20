class_name CueTracker extends RefCounted

## Turns a playback position into "these cues were just crossed". Pure logic:
## it never reads a clock, so SongPerformance feeds it the audio position and
## the tests feed it numbers.
##
## Cues are seconds, ascending. advance() is monotonic: a cue reports once and
## a position that moves backwards reports nothing, so a stutter in the audio
## clock cannot light a slot twice.

var _cues: PackedFloat32Array
var _next: int = 0

func _init(cues: PackedFloat32Array) -> void:
	_cues = cues
	for i: int in range(1, cues.size()):
		assert(cues[i] > cues[i - 1], "Cues must be strictly ascending.")

## Every cue index at or before `position` that has not been reported yet, in
## order.
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
