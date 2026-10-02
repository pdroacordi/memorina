class_name ReleaseState extends RefCounted

## Release and restoration transitions; see docs/design/02_mecanicas.md section 7.3.

enum Event { NONE, RELEASED, RESTORED }

var _released := false
var _holds := 0
var _waiting := false

func is_released() -> bool:
	return _released

func is_waiting() -> bool:
	return _waiting

## Marks the object released when a RELEASE pulse reaches it.
func lit() -> Event:
	_waiting = false
	if _released:
		return Event.NONE
	_released = true
	return Event.RELEASED

## Handles a departing RELEASE pulse; `still_lit` indicates another covering pulse.
func unlit(still_lit: bool) -> Event:
	if still_lit or not _released:
		return Event.NONE
	if _holds > 0:
		_waiting = true
		return Event.NONE
	return _restore()

func hold() -> void:
	_holds += 1

func let_go() -> Event:
	_holds = maxi(_holds - 1, 0)
	if _holds == 0 and _waiting:
		return _restore()
	return Event.NONE

func _restore() -> Event:
	_released = false
	_waiting = false
	return Event.RESTORED
