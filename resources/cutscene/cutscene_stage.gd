class_name CutsceneStage
extends CutsceneStep
## A FactStaging (named by its `staging_id`) stands in `child` mid-scene, e.g. the guitar leaving its hook; the stand-in
## lasts until the staging's picked stage next changes, as a beat's does.

@export var staging: StringName = &""
## A child of the staging; empty shows nothing.
@export var child: StringName = &""
## Scaled seconds of cross-fade; 0 cuts.
@export var seconds: float = 0.0


func begin(context: CutsceneContext) -> CutsceneTask:
	context.stage(staging, child, seconds)
	return CutsceneWaitTask.new(seconds)

func land(context: CutsceneContext) -> void:
	context.stage(staging, child, 0.0)

func subjects() -> Array[StringName]:
	return [staging]
