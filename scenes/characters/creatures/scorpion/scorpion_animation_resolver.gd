class_name ScorpionAnimationResolver
extends AnimationResolver
## No death or waking clip: the corruption edge dissolves the scorpion (systems/creatures).

const IDLE := &"idle"
const WALK := &"walk"
const TELL := &"tell"
const STRIKE := &"strike"
const STUCK := &"stuck"
const HURT := &"hurt"

@onready var _scorpion: Enemy = get_parent()


func resolve() -> StringName:
	if _scorpion.is_dead():
		return HURT
	if (_scorpion.just_hit() or driver.holding(HURT)) and not _scorpion.is_armoured():
		return HURT
	if _scorpion.is_dormant() or _scorpion.is_in_knockback():
		return IDLE
	if _scorpion.is_telegraphing():
		return TELL
	if _scorpion.is_attacking():
		return STRIKE
	if _scorpion.is_recovering():
		return STUCK
	if _scorpion.wants_to_move():
		return WALK
	return IDLE
