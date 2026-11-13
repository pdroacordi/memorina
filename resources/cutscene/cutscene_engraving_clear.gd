class_name CutsceneEngravingClear
extends CutsceneStep
## Dithers the engraved still out to bare paper; the paper stays until the scene's end hides the view.

const SUBJECT := CutsceneEngraving.SUBJECT

## Scaled seconds.
@export var seconds: float = 1.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.clear_engraving(seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.clear_engraving(0.0)

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
