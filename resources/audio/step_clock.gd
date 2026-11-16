class_name StepClock
extends RefCounted
## Counts the contact times a looping clip's play position crossed since the last read (systems/sound-effects).

## Before a clip's first frame, so a contact at 0 s sounds as the clip starts.
const BEFORE_START := -1.0
## s; contacts are stored as 32-bit floats, so 0.4 lies just past a 64-bit position of 0.4.
const EPSILON := 0.00001

var _clip: StringName = &""
var _last: float = BEFORE_START


## How many of `contacts` (s) the play `position` (s) of `clip` crossed since the last call; `length` is the clip's, s.
## A new clip starts before its first contact; a position moved back by under half the clip reports nothing.
func advance(clip: StringName, position: float, length: float, contacts: PackedFloat32Array) -> int:
	if clip != _clip:
		_clip = clip
		_last = BEFORE_START
	var from := _last
	_last = position
	if position >= from:
		return _count(contacts, from, position)
	# A read comes every physics frame, far under half a step clip, so a jump back that large is the loop wrapping.
	if length > 0.0 and from - position > length * 0.5:
		return _count(contacts, from, length) + _count(contacts, BEFORE_START, position)
	return 0

## Forgets the clip, so the next read starts it again.
func reset() -> void:
	_clip = &""
	_last = BEFORE_START

# Contacts in (after, upto], both bounds moved by EPSILON so a contact counts exactly once.
static func _count(contacts: PackedFloat32Array, after: float, upto: float) -> int:
	var crossed := 0
	for contact: float in contacts:
		if contact > after + EPSILON and contact <= upto + EPSILON:
			crossed += 1
	return crossed
