class_name HitGate
extends RefCounted
## One life note per guardian string, by any of its hitboxes: refuses a link's hit on a target an earlier link of the
## same string hurt ("One note per string (Recommended)", user, 2026-11-18). The first link is never refused.

## The link under way, 0 for the string's first move and between strings.
var link: int = 0

## Link that last hurt each target in this string, by instance id.
var _hurt_at: Dictionary[int, int] = {}


## A new string, or the end of one: nothing is hurt yet.
func begin_string() -> void:
	link = 0
	_hurt_at.clear()

func allows(target: Object) -> bool:
	var id := target.get_instance_id()
	return not _hurt_at.has(id) or _hurt_at[id] >= link

func record(target: Object) -> void:
	var id := target.get_instance_id()
	if not _hurt_at.has(id):
		_hurt_at[id] = link
