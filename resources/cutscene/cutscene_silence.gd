class_name CutsceneSilence
extends CutsceneStep
## Cuts every voice and melody the scene started.


func begin(context: CutsceneContext) -> CutsceneTask:
	land(context)
	return CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.silence()
