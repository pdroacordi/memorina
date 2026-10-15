class_name LandingRule
extends RefCounted
## Whether a landing is a hard landing (systems/rooms "Soft landing").


## A landing at `fall_speed` (px/s, down positive) is hard at or over `hard_speed`, unless the body is inside at least
## one soft-landing zone (`soft_zones`).
static func is_hard(fall_speed: float, hard_speed: float, soft_zones: int) -> bool:
	return soft_zones <= 0 and fall_speed >= hard_speed
