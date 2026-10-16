class_name CutsceneFade
extends CutsceneStep
## Fades the screen to black or back to clear; a scene that ends black clears it itself.

const SUBJECT := &"fade"

@export var to_black: bool = true
## Scaled seconds.
@export var seconds: float = 0.5


func begin(context: CutsceneContext) -> CutsceneTask:
	context.fade(to_black, seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.fade(to_black, 0.0)

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
