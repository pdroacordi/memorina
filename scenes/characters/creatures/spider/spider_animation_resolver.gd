class_name SpiderAnimationResolver
extends AnimationResolver
## No death or waking clip: the corruption edge dissolves the spider (systems/creatures). It has no tell clip: it
## bobs on its thread while it holds, and that bob is its tell.

const IDLE := &"idle"
const CLIMB := &"climb"
const BOB := &"bob"
const BITE := &"bite"
const HURT := &"hurt"

@onready var _spider: Enemy = get_parent()


func resolve() -> StringName:
	if _spider.is_dead():
		return HURT
	if _spider.just_hit() or driver.holding(HURT):
		return HURT
	if _spider.is_dormant():
		return IDLE
	if _spider.is_telegraphing() or _spider.is_recovering() or _spider.is_in_knockback():
		return BOB
	if _spider.is_attacking():
		return BITE
	if _spider.wants_to_move():
		return CLIMB
	if _spider.is_home():
		return IDLE
	return BOB
