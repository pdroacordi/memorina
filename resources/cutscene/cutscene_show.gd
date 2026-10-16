class_name CutsceneShow
extends CutsceneStep
## Brings a CutsceneVisual (a light through a window) to `alpha`; every visual hides at the scene's end.

@export var visual: StringName = &""
## 0..1.
@export_range(0.0, 1.0) var alpha: float = 1.0
## Scaled seconds.
@export var seconds: float = 0.5


func begin(context: CutsceneContext) -> CutsceneTask:
	context.show_visual(visual, alpha, seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.show_visual(visual, alpha, 0.0)

func subjects() -> Array[StringName]:
	return [visual]
