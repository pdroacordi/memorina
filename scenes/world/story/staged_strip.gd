class_name StagedStrip
extends AnimatedSprite2D
## A FactStaging child that moves while shown: `intro` once, then `loop`, from the first frame each time it is shown
## (systems/story). Pausable and scaled, like the beat that stands it in.

@export var intro: StringName = &""
@export var loop: StringName = &""


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	animation_finished.connect(_on_animation_finished)
	_on_visibility_changed()

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		stop()
		return
	play(intro if not intro.is_empty() else loop)

func _on_animation_finished() -> void:
	if animation == intro and not loop.is_empty():
		play(loop)
