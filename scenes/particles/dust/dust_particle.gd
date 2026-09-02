class_name DustParticle
extends AnimatedSprite2D

@export var fade_out : bool = true

func _ready() -> void:
	animation_finished.connect(queue_free)
	play()

	if fade_out:
		create_tween().tween_property(self, "self_modulate:a", 0.0, _lifetime())

func _lifetime() -> float:
	var fps := sprite_frames.get_animation_speed(animation)
	if fps <= 0.0:
		return 0.0

	return sprite_frames.get_frame_count(animation) / fps
