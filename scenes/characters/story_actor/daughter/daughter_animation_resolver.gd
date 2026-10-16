class_name DaughterAnimationResolver
extends StoryAnimationResolver
## The daughter's clips. Each rest clip is named like the `Daughter` staging child it stands for (systems/cutscenes).

const STANDING := &"standing"
const LISTENING := &"listening"
const HOLDING_OUT := &"holding_out"
const AT_GUITAR := &"at_guitar"
const ASLEEP := &"asleep"
const IN_BED_TURNED := &"in_bed_turned"
const WALK := &"walk"
const LOWER_EYES := &"lower_eyes"
const EYES_LOWERED := &"eyes_lowered"
const SIT := &"sit"
const SEATED := &"seated"
const LIE_DOWN := &"lie_down"
const REACH_UP := &"reach_up"
const GUITAR_AT_CHEST := &"guitar_at_chest"

const CLIPS: Array[StringName] = [
	STANDING, LISTENING, HOLDING_OUT, AT_GUITAR, ASLEEP, IN_BED_TURNED, WALK, LOWER_EYES, EYES_LOWERED, SIT, SEATED,
	LIE_DOWN, REACH_UP, GUITAR_AT_CHEST,
]
const SETTLES: Dictionary[StringName, StringName] = {
	LOWER_EYES: EYES_LOWERED,
	SIT: SEATED,
	LIE_DOWN: IN_BED_TURNED,
	REACH_UP: GUITAR_AT_CHEST,
}


func clips() -> Array[StringName]:
	return CLIPS

func settles() -> Dictionary[StringName, StringName]:
	return SETTLES

func walk_clip() -> StringName:
	return WALK

func idle_clip() -> StringName:
	return STANDING
