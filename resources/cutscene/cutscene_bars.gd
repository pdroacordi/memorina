class_name CutsceneBars
extends CutsceneStep
## Brings the letterbox bars in or out; the scene's end closes them.

const SUBJECT := &"bars"

@export var open: bool = true
## Scaled seconds of the slide.
@export var seconds: float = 0.6


func begin(context: CutsceneContext) -> CutsceneTask:
	context.bars(open, seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.bars(open, 0.0)

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
