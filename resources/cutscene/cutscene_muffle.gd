class_name CutsceneMuffle
extends CutsceneStep
## Muffles the music, as if under water, for the rest of the scene; the scene's end lifts it (systems/music, "Muffles").

const SUBJECT := &"muffle"

## 0..1; 0 lifts it. Music eases toward it on its own.
@export_range(0.0, 1.0) var amount: float = 1.0


func begin(context: CutsceneContext) -> CutsceneTask:
	land(context)
	return CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.muffle(amount)

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []
