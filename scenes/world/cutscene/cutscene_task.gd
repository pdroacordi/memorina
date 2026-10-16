class_name CutsceneTask
extends RefCounted
## What a begun step waits on, polled on the director's physics clock; this base is over at once. Nothing awaits a
## tween (gotchas/a-killed-tween-never-emits-finished): every task polls.


## Advances by `delta` scaled seconds; true once the step is over.
func tick(_delta: float) -> bool:
	return true

## The scene was skipped or dropped while this ran.
func stop() -> void:
	pass
