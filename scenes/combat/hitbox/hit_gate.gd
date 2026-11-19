class_name HitGate
extends RefCounted
## One life note per guardian move or string, by any of its hitboxes: from a string's first wind-up to the end of its
## recovery, a target it hurt is not hurt again ("One note per string (Recommended)", user, 2026-11-18;
## bugs/a-single-guardian-move-can-cost-two-notes-through-its-contact-box). Between strings nothing is refused.

## Targets the string under way hurt, by instance id.
var _hurt: Dictionary[int, bool] = {}
var _active: bool = false


## A string's first wind-up: nothing is hurt yet.
func begin_string() -> void:
	_active = true
	_hurt.clear()

## The string's recovery is over: hits count again, one by one.
func end_string() -> void:
	_active = false
	_hurt.clear()

func is_active() -> bool:
	return _active

func allows(target: Object) -> bool:
	return not _active or not _hurt.has(target.get_instance_id())

func record(target: Object) -> void:
	if _active:
		_hurt[target.get_instance_id()] = true
