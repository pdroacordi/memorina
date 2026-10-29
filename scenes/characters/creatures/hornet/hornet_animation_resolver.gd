class_name HornetAnimationResolver
extends AnimationResolver
## No death or waking clip: the corruption edge dissolves the hornet (systems/creatures). It always beats its wings:
## hovering and flying share one clip.

const HOVER := &"hover"
const TELL := &"tell"
const DASH := &"dash"
const RECOVER := &"recover"
const HURT := &"hurt"

@onready var _hornet: Enemy = get_parent()


func resolve() -> StringName:
	if _hornet.is_dead():
		return HURT
	if _hornet.just_hit() or driver.holding(HURT):
		return HURT
	if _hornet.is_dormant() or _hornet.is_in_knockback():
		return HOVER
	if _hornet.is_telegraphing():
		return TELL
	if _hornet.is_attacking():
		return DASH
	if _hornet.is_recovering():
		return RECOVER
	return HOVER
