class_name GuardianAnimationResolver
extends AnimationResolver
## The clip vocabulary every guardian shares. A guardian scene must author
## all of these; one with moves of its own beyond three attack clips
## subclasses this and extends the chain. The phase outranks everything:
## a restored guardian is never seen flinching, and a lucid one never swings.

const IDLE := &"idle"
const WALK := &"walk"
const ATTACK_1 := &"attack_1"
const ATTACK_2 := &"attack_2"
const ATTACK_3 := &"attack_3"
const HURT := &"hurt"
## The tremble between corrupted and lucid; the shield does the colour.
const LUCID := &"lucid"
const RESTORED := &"restored"

const ATTACK_CLIPS: Array[StringName] = [ATTACK_1, ATTACK_2, ATTACK_3]

@onready var _guardian: Guardian = get_parent()


func resolve() -> StringName:
	match _guardian.phase():
		GuardianFight.Phase.RESTORED:
			return RESTORED
		GuardianFight.Phase.LUCIDITY:
			return LUCID
	if _guardian.is_swinging():
		return attack_clip_for(_guardian.current_attack().clip_index)
	# The wind-up is the idle pose held still; the telegraph tint does the rest.
	if _guardian.is_telegraphing():
		return IDLE
	if _guardian.just_hit() or driver.holding(HURT):
		return HURT
	if _guardian.wants_to_move():
		return WALK
	return IDLE

## The clip a GuardianAttack's clip_index plays; Guardian's duration assert
## walks this same mapping so the two cannot drift apart.
func attack_clip_for(index: int) -> StringName:
	return ATTACK_CLIPS[clampi(index, 0, ATTACK_CLIPS.size() - 1)]
