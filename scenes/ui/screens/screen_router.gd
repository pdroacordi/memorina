class_name ScreenRouter
extends RefCounted
## Decides which screen is open after a press; see docs/knowledge/architecture/pause-menu-worldfreeze-reuse.md.

enum Kind { NONE, PAUSE, NOTEBOOK, MAP }
enum Press { PAUSE, NOTEBOOK, MAP, BACK }


## Opens only from NONE on a running, unlocked tree. An open screen closes on its own toggle, back or pause, and ignores the other toggles.
static func decide(open: Kind, press: Press, tree_paused: bool, locked: bool) -> Kind:
	if open == Kind.NONE:
		if tree_paused or locked:
			return Kind.NONE
		return _opened_by(press)
	if press == Press.BACK or press == Press.PAUSE or _opened_by(press) == open:
		return Kind.NONE
	return open

static func _opened_by(press: Press) -> Kind:
	match press:
		Press.PAUSE:
			return Kind.PAUSE
		Press.NOTEBOOK:
			return Kind.NOTEBOOK
		Press.MAP:
			return Kind.MAP
	return Kind.NONE
