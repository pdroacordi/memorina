class_name BruteShadowAnimationResolver
extends AnimationResolver

const SPAWN := &"spawn"
const IDLE := &"idle"
const WALK := &"walk"
const ATTACK := &"attack"
const HURT := &"hurt"
const DEATH := &"death"

@onready var _brute: BruteShadow = get_parent()


func resolve() -> StringName:
	if _brute.is_dead():
		return DEATH
	if _brute.is_spawning():
		return SPAWN
	if _brute.just_hit() or driver.holding(HURT):
		return HURT
	# Staggered: the flinch is over but control hasn't come back yet.
	if _brute.is_in_knockback():
		return IDLE
	if _brute.is_attacking():
		return ATTACK
	if _brute.wants_to_move():
		return WALK
	return IDLE

func is_death_finished() -> bool:
	return driver.finished(DEATH)

func is_spawn_finished() -> bool:
	return driver.finished(SPAWN)
