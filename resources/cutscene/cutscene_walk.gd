class_name CutsceneWalk
extends CutsceneStep
## An actor or Ivo walks to a mark (or an x) and stops on it, facing the way it walked.

@export var actor: StringName = &""
## Empty walks to `x`.
@export var mark: StringName = &""
## World px when `mark` is empty; px added to the mark's x otherwise.
@export var x: float = 0.0
## 0..1 of the walker's move speed.
@export_range(0.05, 1.0) var pace: float = 1.0


func begin(context: CutsceneContext) -> CutsceneTask:
	return context.walk(actor, target_x(context), pace)

func land(context: CutsceneContext) -> void:
	var from := context.point_of(actor)
	var to := target_x(context)
	if not is_equal_approx(to, from.x):
		context.face(actor, 1 if to > from.x else -1)
	context.place(actor, Vector2(to, from.y))

## The world x the walk ends on.
func target_x(context: CutsceneContext) -> float:
	return x if mark == &"" else context.point_of(mark).x + x

func subjects() -> Array[StringName]:
	return [actor]

func names() -> Array[StringName]:
	return [actor] if mark == &"" else [actor, mark]
