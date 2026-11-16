class_name CutsceneExit
extends CutsceneStep
## An actor leaves the scene at once (a cut, so the frame should be off it); the scene's end gives its place back to its
## staging (architecture/story-07-epilogue).

@export var actor: StringName = &""


func begin(context: CutsceneContext) -> CutsceneTask:
	land(context)
	return CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.exit(actor)

func subjects() -> Array[StringName]:
	return [actor]
