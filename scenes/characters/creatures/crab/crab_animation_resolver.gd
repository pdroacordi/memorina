class_name CrabAnimationResolver
extends AnimationResolver
## No death or waking clip: the corruption edge dissolves the crab (systems/creatures). A blocked hit flashes the
## shell white and plays no clip.

const IDLE := &"idle"
const SIDESTEP := &"sidestep"
const TELL := &"tell"
const SNAP := &"snap"
const HURT := &"hurt"

@onready var _crab: Enemy = get_parent()


func resolve() -> StringName:
	if _crab.is_dead():
		return HURT
	if _crab.just_hit() or driver.holding(HURT):
		return HURT
	if _crab.is_dormant() or _crab.is_in_knockback():
		return IDLE
	if _crab.is_telegraphing():
		return TELL
	if _crab.is_attacking():
		return SNAP
	if _crab.is_recovering():
		return IDLE
	if _crab.wants_to_move():
		return SIDESTEP
	return IDLE
