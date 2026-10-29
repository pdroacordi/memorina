class_name BatAnimationResolver
extends AnimationResolver
## No death or waking clip: the corruption edge dissolves the bat (systems/creatures). It hangs asleep, and again
## once back at its anchor; the drop is its tell.

const HANG := &"hang"
const DROP := &"drop"
const FLY := &"fly"
const SWOOP := &"swoop"
const HURT := &"hurt"

@onready var _bat: Enemy = get_parent()


func resolve() -> StringName:
	if _bat.is_dead():
		return HURT
	if _bat.just_hit() or driver.holding(HURT):
		return HURT
	if _bat.is_dormant():
		return HANG
	if _bat.is_telegraphing():
		return DROP
	if _bat.is_attacking():
		return SWOOP
	if _bat.is_recovering() or _bat.is_in_knockback() or not _bat.is_home():
		return FLY
	return HANG
