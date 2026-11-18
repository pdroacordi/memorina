class_name CutsceneEngravingClear
extends CutsceneStep
## Dithers the engraved still out to bare paper; the paper stays until the scene's end hides the view.

const SUBJECT := CutsceneEngraving.SUBJECT

## Scaled seconds.
@export var seconds: float = 1.0
## Hides the view at once, paper included, so a fade clearing after it shows the world.
@export var hide: bool = false


func begin(context: CutsceneContext) -> CutsceneTask:
	if hide:
		context.hide_engraving()
		return CutsceneTask.new()
	context.clear_engraving(seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	if hide:
		context.hide_engraving()
	else:
		context.clear_engraving(0.0)

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
