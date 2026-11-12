class_name CutsceneFade
extends CutsceneStep
## Covers the screen in `colour` or clears it; a scene that ends covered clears it itself.

const SUBJECT := &"fade"

## Covers the screen; false clears it.
@export var to_black: bool = true
## The cover's colour; white for a flashback's crossing. Ignored when clearing.
@export var colour: Color = Color.BLACK
## Scaled seconds.
@export var seconds: float = 0.5


func begin(context: CutsceneContext) -> CutsceneTask:
	context.fade(to_black, seconds, colour)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.fade(to_black, 0.0, colour)

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
