class_name CutsceneFace
extends CutsceneStep
## An actor or Ivo turns toward (or away from) another id, or to a fixed side.

@export var actor: StringName = &""
## Empty turns to `side`.
@export var toward: StringName = &""
## Turns its back on `toward` instead.
@export var away: bool = false
## -1 west, 1 east; read when `toward` is empty.
@export_range(-1, 1) var side: int = 1


func begin(context: CutsceneContext) -> CutsceneTask:
	land(context)
	return CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.face(actor, direction(context))

## -1 or 1, read when the step begins.
func direction(context: CutsceneContext) -> int:
	if toward == &"":
		return -1 if side < 0 else 1
	var to := 1 if context.point_of(toward).x >= context.point_of(actor).x else -1
	return -to if away else to

func subjects() -> Array[StringName]:
	return [actor]

func names() -> Array[StringName]:
	return [actor] if toward == &"" else [actor, toward]
