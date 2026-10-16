class_name CutscenePlace
extends CutsceneStep
## Puts an actor or Ivo on a mark at once (a cut).

@export var actor: StringName = &""
@export var mark: StringName = &""
## Px added to the mark's point.
@export var offset: Vector2 = Vector2.ZERO


func begin(context: CutsceneContext) -> CutsceneTask:
	land(context)
	return CutsceneTask.new()

func land(context: CutsceneContext) -> void:
	context.place(actor, context.point_of(mark) + offset)

func subjects() -> Array[StringName]:
	return [actor]

func names() -> Array[StringName]:
	return [actor, mark]
