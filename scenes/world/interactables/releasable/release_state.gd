class_name ReleaseState extends RefCounted

## When a thing Soltar let go of comes back. Pure, so the rule is tested:
## - a RELEASE pulse reaching it lets it go (once, however many pulses);
## - when the last pulse has left it, the grey gives back the old state
##   (design 02 section 7.3, "o cinza guarda o estado antigo") - unless
##   something is holding it (roots that caught it, Ivo standing on it), in
##   which case it comes back the moment the last hold lets go.

enum Event { NONE, RELEASED, RESTORED }

var _released := false
var _holds := 0
var _waiting := false

func is_released() -> bool:
	return _released

func is_waiting() -> bool:
	return _waiting

## A RELEASE pulse reached it.
func lit() -> Event:
	_waiting = false
	if _released:
		return Event.NONE
	_released = true
	return Event.RELEASED

## A RELEASE pulse left it; `still_lit` is whether another still covers it.
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
