class_name GuardianAnimationResolver
extends AnimationResolver
## Resolves shared guardian clips with encounter phase precedence.

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
		GuardianFight.Phase.RELAPSE:
			# Keep the relapse stagger while the hit signal is active, then return to idle.
			return HURT if _guardian.just_hit() or driver.holding(HURT) else IDLE
	if _guardian.is_swinging():
		return attack_clip_for(_guardian.current_attack().clip_index)
	# Telegraphing uses the idle pose; the telegraph tint communicates the wind-up.
	if _guardian.is_telegraphing():
		return IDLE
	if _guardian.just_hit() or driver.holding(HURT):
		return HURT
	if _guardian.wants_to_move():
		return WALK
	return IDLE

## Maps attack indices to clips; Guardian's duration assertion uses this mapping too.
func attack_clip_for(index: int) -> StringName:
	return ATTACK_CLIPS[clampi(index, 0, ATTACK_CLIPS.size() - 1)]
