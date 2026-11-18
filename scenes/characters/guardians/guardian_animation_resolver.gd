class_name GuardianAnimationResolver
extends AnimationResolver
## Resolves shared guardian clips with encounter phase precedence.

const IDLE := &"idle"
const WALK := &"walk"
## Strike slots, `GuardianAttack.clip_index`; 4..8 exist in a tree only when its data uses them.
const ATTACK_1 := &"attack_1"
const ATTACK_2 := &"attack_2"
const ATTACK_3 := &"attack_3"
const ATTACK_4 := &"attack_4"
const ATTACK_5 := &"attack_5"
const ATTACK_6 := &"attack_6"
const ATTACK_7 := &"attack_7"
const ATTACK_8 := &"attack_8"
## Wind-up slots, `GuardianAttack.windup_index`, played through the telegraph; each holds its last frame.
const WINDUP_1 := &"windup_1"
const WINDUP_2 := &"windup_2"
const WINDUP_3 := &"windup_3"
const WINDUP_4 := &"windup_4"
const WINDUP_5 := &"windup_5"
const WINDUP_6 := &"windup_6"
const WINDUP_7 := &"windup_7"
const WINDUP_8 := &"windup_8"
## Recovery slots, `GuardianAttack.recovery_index`, played through the recovery; each holds its last frame.
const RECOVER_1 := &"recover_1"
const RECOVER_2 := &"recover_2"
const RECOVER_3 := &"recover_3"
const RECOVER_4 := &"recover_4"
const RECOVER_5 := &"recover_5"
const RECOVER_6 := &"recover_6"
const RECOVER_7 := &"recover_7"
const RECOVER_8 := &"recover_8"
const HURT := &"hurt"
## The tremble between corrupted and lucid; the shield does the colour.
const LUCID := &"lucid"
## One-shot as lucidity opens, during `Guardian.lucidity_delay`; settles on `lucid` frame 0.
const LUCID_ENTER := &"lucid_enter"
## Loop while the call sounds: the guardian plays its season's flute.
const PLAY_SONG := &"play_song"
## One-shot as a relapse begins; settles on `idle` frame 0.
const RELAPSE := &"relapse"
## The deep loop played through the lesson, then `perform_end` (one-shot) settling on `restored` frame 0.
const PERFORM := &"perform"
const PERFORM_END := &"perform_end"
const RESTORED := &"restored"
## The lucidity leap, in four one-shots that each hold their last frame: the
## crouch ends on take-off, rise and fall follow the arc, land plays on touchdown.
const LEAP_CROUCH := &"leap_crouch"
const LEAP_RISE := &"leap_rise"
const LEAP_FALL := &"leap_fall"
const LEAP_LAND := &"leap_land"

const ATTACK_CLIPS: Array[StringName] = [ATTACK_1, ATTACK_2, ATTACK_3, ATTACK_4, ATTACK_5, ATTACK_6, ATTACK_7, ATTACK_8]
const WINDUP_CLIPS: Array[StringName] = [WINDUP_1, WINDUP_2, WINDUP_3, WINDUP_4, WINDUP_5, WINDUP_6, WINDUP_7, WINDUP_8]
const RECOVER_CLIPS: Array[StringName] = [RECOVER_1, RECOVER_2, RECOVER_3, RECOVER_4, RECOVER_5, RECOVER_6, RECOVER_7,
		RECOVER_8]
## Every clip a guardian's tree must hold (guardian_voice_test).
const CLIPS: Array[StringName] = [IDLE, WALK, ATTACK_1, ATTACK_2, ATTACK_3, HURT, LUCID, LUCID_ENTER, PLAY_SONG,
		RELAPSE, PERFORM, PERFORM_END, RESTORED, LEAP_CROUCH, LEAP_RISE, LEAP_FALL, LEAP_LAND]

@onready var _guardian: Guardian = get_parent()


func resolve() -> StringName:
	var leap := _leap_clip()
	if leap != &"":
		return leap
	if _guardian.is_teaching():
		return PERFORM
	match _guardian.phase():
		GuardianFight.Phase.RESTORED:
			if driver.current == PERFORM or driver.holding(PERFORM_END):
				return PERFORM_END
			return RESTORED
		GuardianFight.Phase.LUCIDITY:
			# Before the leap the window has just opened: the one-shot, then the tremble until the crouch.
			if _guardian.seconds_to_leap() < INF:
				return driver.sequence(LUCID_ENTER, LUCID)
			return PLAY_SONG if _guardian.is_sounding() else LUCID
		GuardianFight.Phase.RELAPSE:
			return driver.sequence(RELAPSE, IDLE)
	if _guardian.is_swinging():
		return attack_clip_for(_guardian.current_attack().clip_index)
	if _guardian.is_recovering():
		return _or_idle(recover_clip_for(_guardian.current_attack().recovery_index))
	# The telegraph tint is the accent; a move with no wind-up slot shows the idle pose under it.
	if _guardian.is_telegraphing():
		return _or_idle(windup_clip_for(_guardian.current_attack().windup_index))
	if _guardian.just_hit() or driver.holding(HURT):
		return HURT
	if _guardian.wants_to_move():
		return WALK
	return IDLE

## Maps attack indices to clips; Guardian's duration assertion uses this mapping too.
static func attack_clip_for(index: int) -> StringName:
	return ATTACK_CLIPS[clampi(index, 0, ATTACK_CLIPS.size() - 1)]

## The wind-up clip of `index`, or empty for -1.
static func windup_clip_for(index: int) -> StringName:
	return _slot(WINDUP_CLIPS, index)

## The recovery clip of `index`, or empty for -1.
static func recover_clip_for(index: int) -> StringName:
	return _slot(RECOVER_CLIPS, index)

static func _slot(slots: Array[StringName], index: int) -> StringName:
	return slots[index] if index >= 0 and index < slots.size() else &""

func _or_idle(clip: StringName) -> StringName:
	return clip if clip != &"" else IDLE

## The leap's clip, or empty when no leap is under way.
func _leap_clip() -> StringName:
	if _guardian.is_leaping():
		if driver.holding(LEAP_CROUCH):
			return LEAP_CROUCH
		return LEAP_RISE if _guardian.velocity.y < 0.0 else LEAP_FALL
	if driver.current == LEAP_RISE or driver.current == LEAP_FALL or driver.holding(LEAP_LAND):
		return LEAP_LAND
	# Started this early, the crouch's last frame (the spring) meets the take-off.
	if _guardian.seconds_to_leap() <= driver.clip_length(LEAP_CROUCH):
		return LEAP_CROUCH
	return &""
