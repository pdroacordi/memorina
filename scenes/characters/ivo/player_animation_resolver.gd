class_name PlayerAnimationResolver
extends AnimationResolver

const IDLE := &"idle"
const RUN := &"run"
const JUMP_START := &"jump_start"
const JUMP_IDLE := &"jump_idle"
const AIR_SPIN := &"air_spin"
const FALL_START := &"fall_start"
const FALL_IDLE := &"fall_idle"
const LAND := &"land"
const WALL_LANDING := &"wall_landing"
const WALL_SLIDE := &"wall_slide"
const ROLL := &"roll"
const ATTACK_IDLE_1 := &"attack_idle_1"
const ATTACK_IDLE_2 := &"attack_idle_2"
const ATTACK_RUN_1 := &"attack_run_1"
const ATTACK_RUN_2 := &"attack_run_2"
const ATTACK_JUMP := &"attack_jump"
const ATTACK_FALL := &"attack_fall"
const ATTACK_POGO := &"attack_pogo"
const MEMORINA_DRAW := &"memorina_draw"
const MEMORINA_IDLE := &"memorina_idle"
const HURT := &"hurt"
const DEATH := &"death"

## Coming out of these Ivo is already mid-motion, so the jump/fall intros are
## skipped rather than crouching or tucking in mid-air.
const INTRO_SKIPPING_CLIPS: Array[StringName] = [AIR_SPIN, ATTACK_JUMP, ATTACK_FALL, ATTACK_POGO, HURT]
const FALL_CLIPS: Array[StringName] = [FALL_START, FALL_IDLE]

@onready var _player: Player = get_parent()


func resolve() -> StringName:
	var on_floor := _player.is_on_floor()

	if _player.is_dead():
		return DEATH
	if _player.just_hit() or driver.holding(HURT):
		return HURT
	if _player.is_rolling():
		return ROLL
	if _player.is_attacking():
		var clip := _attack_clip(on_floor)
		if clip != &"":
			return clip

	if not on_floor:
		if _player.is_wall_sliding():
			return driver.sequence(WALL_LANDING, WALL_SLIDE)
		if _player.just_double_jumped() or driver.holding(AIR_SPIN):
			return AIR_SPIN
		# The launch pose plays out even on a hop that peaks before it ends.
		if driver.holding(JUMP_START):
			return JUMP_START
		var skip_intro := driver.current in INTRO_SKIPPING_CLIPS
		if _player.is_jumping():
			return driver.sequence(JUMP_START, JUMP_IDLE, skip_intro or driver.current in FALL_CLIPS)
		return driver.sequence(FALL_START, FALL_IDLE, skip_intro)

	# Below the airborne block because being drawn already implies standing on
	# the floor, and above locomotion because holding the instrument outranks
	# idling. Hurt and death still win, which is the point of interruption.
	if _player.is_memorina_drawn():
		return driver.sequence(MEMORINA_DRAW, MEMORINA_IDLE)

	if _player.wants_to_move():
		return RUN
	if _player.just_landed() or driver.holding(LAND):
		return LAND
	return IDLE

func is_death_finished() -> bool:
	return driver.finished(DEATH)

## The clip for one attack context and phase; Player's duration assert walks
## this same mapping so the two cannot drift apart.
func attack_clip_for(context: StringName, phase: int) -> StringName:
	match context:
		Player.CTX_IDLE:
			return ATTACK_IDLE_2 if phase > 0 else ATTACK_IDLE_1
		Player.CTX_RUN:
			return ATTACK_RUN_2 if phase > 0 else ATTACK_RUN_1
		Player.CTX_JUMP:
			return ATTACK_JUMP
		Player.CTX_FALL:
			return ATTACK_FALL
		Player.CTX_POGO:
			return ATTACK_POGO
	return &""

## Ground combos are the same clip family wherever Ivo ends up; air attacks
## yield to the ground the moment he lands, so landing mid-swing reads as a
## landing rather than a swing frozen on the floor.
func _attack_clip(on_floor: bool) -> StringName:
	var context := _player.attack_context()
	if on_floor and context in Player.AIR_ATTACK_CONTEXTS:
		return &""
	return attack_clip_for(context, _player.attack_phase_index())
