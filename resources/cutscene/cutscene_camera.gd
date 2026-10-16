class_name CutsceneCamera
extends CutsceneStep
## Frames the mean of its targets' feet plus `offset`, at `zoom`; the scene's end returns the frame to Ivo.

const SUBJECT := &"camera"

## Actor, mark or visual ids, or `&"ivo"`.
@export var targets: Array[StringName] = []
## Px from the targets' mean feet to the frame's centre.
@export var offset: Vector2 = Vector2(0.0, -40.0)
## 0 keeps the zoom; prefer integers (1.5 draws uneven pixels).
@export var zoom: float = 0.0
## Scaled seconds of the move.
@export var seconds: float = 1.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.frame(centre(context), zoom, seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.frame(centre(context), zoom, 0.0)

## The world point the frame centres on.
func centre(context: CutsceneContext) -> Vector2:
	var sum := Vector2.ZERO
	for target: StringName in targets:
		sum += context.point_of(target)
	return sum / maxf(float(targets.size()), 1.0) + offset

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return targets.duplicate()
