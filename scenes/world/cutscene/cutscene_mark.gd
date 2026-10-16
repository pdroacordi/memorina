class_name CutsceneMark
extends Marker2D
## A named point in a contents scene that cutscene steps walk to, place on or frame (systems/cutscenes).

const GROUP := &"cutscene_marks"

## Unique among the marks of one contents scene.
@export var mark_id: StringName = &""


func _enter_tree() -> void:
	add_to_group(GROUP)
