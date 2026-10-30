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

const ATTACK_CLIPS: Array[StringName] = [ATTACK_1, ATTACK_2, ATTACK_3]
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
