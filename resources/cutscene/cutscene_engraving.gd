class_name CutsceneEngraving
extends CutsceneStep
## Shows one engraved still on the EngravingView and holds it for its seconds (architecture/story-04-bearer-fragments).

const SUBJECT := &"engraving"

@export var frame: EngravingFrame
## The season whose tint inks the frame's key #FF00FF.
@export var ink: SeasonPalette
## The ink of key #00FFFF; null draws it in `ink` (the one-ink bearer look).
@export var second_ink: EngravingInk
## Dithers in over the frame before it; false reveals it from bare paper (a scene's first frame).
@export var dissolve: bool = true


func begin(context: CutsceneContext) -> CutsceneTask:
	context.engrave(frame, _tint(), dissolve, _second_tint())
	return CutsceneWaitTask.new(frame.seconds if frame != null else 0.0)

func land(context: CutsceneContext) -> void:
	context.engrave(frame, _tint(), false, _second_tint())
	context.land_engraving()

func subjects() -> Array[StringName]:
	return [SUBJECT]

func names() -> Array[StringName]:
	return []

func _tint() -> Color:
	return ink.tint if ink != null else Color.WHITE

func _second_tint() -> Color:
	return second_ink.colour if second_ink != null else _tint()
