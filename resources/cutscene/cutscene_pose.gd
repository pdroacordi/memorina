class_name CutscenePose
extends CutsceneStep
## What Ivo holds until the next pose or the scene's end (DialogueBeat.Pose).

@export var pose: DialogueBeat.Pose = DialogueBeat.Pose.NONE


func begin(context: CutsceneContext) -> CutsceneTask:
	land(context)
	return CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.pose(pose)

func subjects() -> Array[StringName]:
	return [IVO]
