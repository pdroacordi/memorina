class_name MenuCueGate
extends RefCounted
## Picks at most one menu cue per process frame, the highest priority asked (architecture/sound-effects-system).

enum Cue { NONE, MOVE, CONFIRM, BACK, PAGE, OPEN, CLOSE }

## OPEN and CLOSE tie; the first one asked in a frame keeps it.
const PRIORITY: Dictionary[Cue, int] = {
	Cue.NONE: 0,
	Cue.MOVE: 1,
	Cue.CONFIRM: 2,
	Cue.BACK: 3,
	Cue.PAGE: 4,
	Cue.OPEN: 5,
	Cue.CLOSE: 5,
}

var _asked: Cue = Cue.NONE
var _navigated: bool = false
var _focus_moved: bool = false


func ask(cue: Cue) -> void:
	if PRIORITY[cue] > PRIORITY[_asked]:
		_asked = cue

## A navigation press this frame: up, down, left or right.
func navigated() -> void:
	_navigated = true

## The focus moved this frame; it is a MOVE only beside a navigation press, so a focus grab is silent.
func focus_moved() -> void:
	_focus_moved = true

## The cue to play for the frame that ends, then a fresh frame.
func flush() -> Cue:
	if _focus_moved and _navigated:
		ask(Cue.MOVE)
	var cue := _asked
	_asked = Cue.NONE
	_navigated = false
	_focus_moved = false
	return cue
