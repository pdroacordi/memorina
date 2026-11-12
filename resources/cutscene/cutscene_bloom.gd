class_name CutsceneBloom
extends CutsceneStep
## Grows or shrinks a MemoryBloom's source to a shape, size and strength; the scene's end hides it (systems/cutscenes).

@export var bloom_id: StringName = &""
## The id the source centres on (an actor, mark, visual or bloom); empty is the bloom itself, read when the step begins.
@export var at: StringName = &""
## World px from that point.
@export var offset: Vector2 = Vector2.ZERO
@export var shape: MemoryFieldMath.Shape = MemoryFieldMath.Shape.CIRCLE
## RECT: full width and height, px.
@export var rect_size: Vector2 = Vector2.ZERO
## CIRCLE and CAPSULE: px.
@export var radius: float = 0.0
## Positive gives memory, negative takes it, -1..1.
@export_range(-1.0, 1.0) var strength: float = 1.0
## Leading-ring brightness, 0..1.
@export_range(0.0, 1.0) var ring: float = 0.0
## Scaled seconds.
@export var seconds: float = 1.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.bloom(self, centre(context), seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.bloom(self, centre(context), 0.0)

## Where the source centres, world px.
func centre(context: CutsceneContext) -> Vector2:
	return context.point_of(at if at != &"" else bloom_id) + offset

func subjects() -> Array[StringName]:
	return [bloom_id]

func names() -> Array[StringName]:
	var found: Array[StringName] = [bloom_id]
	if at != &"":
		found.append(at)
	return found
