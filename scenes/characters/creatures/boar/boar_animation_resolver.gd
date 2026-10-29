class_name BoarAnimationResolver
extends AnimationResolver
## No death or waking clip: the corruption edge dissolves the boar (systems/creatures).

const IDLE := &"idle"
const WALK := &"walk"
const TELL := &"tell"
const CHARGE := &"charge"
const DAZE := &"daze"
const HURT := &"hurt"

@onready var _boar: Enemy = get_parent()


func resolve() -> StringName:
	if _boar.is_dead():
		return HURT
	if (_boar.just_hit() or driver.holding(HURT)) and not _boar.is_armoured():
		return HURT
	if _boar.is_dormant() or _boar.is_in_knockback():
		return IDLE
	if _boar.is_telegraphing():
		return TELL
	if _boar.is_attacking():
		return CHARGE
	if _boar.is_recovering():
		return DAZE
	if _boar.wants_to_move():
		return WALK
	return IDLE
