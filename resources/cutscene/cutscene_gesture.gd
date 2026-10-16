class_name CutsceneGesture
extends CutsceneStep
## An actor plays a clip its resolver names; a one-shot ends held on its settle clip.

@export var actor: StringName = &""
## A clip of the actor's resolver (`StoryAnimationResolver.clips()`).
@export var clip: StringName = &""
## Waits until a one-shot has settled.
@export var wait: bool = true


func begin(context: CutsceneContext) -> CutsceneTask:
	var task := context.gesture(actor, clip)
	return task if wait else CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.land_gesture(actor, clip)

func subjects() -> Array[StringName]:
	return [actor]
