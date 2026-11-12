class_name CutsceneFray
extends CutsceneStep
## Frays an actor's edge (its CorruptionEdge agitated) for `seconds`, then calms it (systems/cutscenes).

@export var actor: StringName = &""
## Scaled seconds.
@export var seconds: float = 0.5


func begin(context: CutsceneContext) -> CutsceneTask:
	context.fray(actor, true)
	return CutsceneWaitTask.new(seconds, context.fray.bind(actor, false))

func land(context: CutsceneContext) -> void:
	context.fray(actor, false)

func subjects() -> Array[StringName]:
	return [actor]
