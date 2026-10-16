class_name ElderAnimationResolver
extends StoryAnimationResolver
## The elder's clips, each named like the `Elder` staging child it stands for (systems/cutscenes). He never walks;
## `turned` is his idle facing the painting.

const IDLE := &"idle"
const TURNED := &"turned"

const CLIPS: Array[StringName] = [IDLE, TURNED]


func clips() -> Array[StringName]:
	return CLIPS

func walk_clip() -> StringName:
	return IDLE

func idle_clip() -> StringName:
	return IDLE
