class_name BakerAnimationResolver
extends StoryAnimationResolver
## The baker's clips, each named like the `Baker` staging child it stands for (systems/cutscenes). She never walks.

const IDLE := &"idle"
const TWO_LOAVES := &"two_loaves"
const ONE_LOAF := &"one_loaf"

const CLIPS: Array[StringName] = [IDLE, TWO_LOAVES, ONE_LOAF]


func clips() -> Array[StringName]:
	return CLIPS

func walk_clip() -> StringName:
	return IDLE

func idle_clip() -> StringName:
	return IDLE
