class_name CutsceneVisual
extends Node2D
## Something only a cutscene shows (a light through a window): hidden at rest, brought in by CutsceneShow, hidden again
## at the scene's end. Its children are its picture; no PointLight2D (systems/cutscenes).

const GROUP := &"cutscene_visuals"

## Unique among the visuals of one contents scene.
@export var visual_id: StringName = &""

var _tween: Tween


func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	reset()

## Eases its alpha to `alpha` (0..1) over `seconds` scaled seconds; 0 cuts.
func fade_to(alpha: float, seconds: float) -> void:
	_kill()
	visible = true
	if seconds <= 0.0:
		modulate.a = alpha
		return
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, seconds)

## Hidden, at rest.
func reset() -> void:
	_kill()
	modulate.a = 0.0
	visible = false

func _kill() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
