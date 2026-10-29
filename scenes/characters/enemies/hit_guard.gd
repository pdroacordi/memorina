class_name HitGuard
extends RefCounted
## Whether a front guard (the crab's shell) turns a hit away; pure.


## A hit whose source is ahead of `body` on the side `facing` (-1/1) looks to, and below the body's top, is blocked;
## one from behind or from above is not. `body` and `source` in world px; Ivo's hitbox origin is his feet.
static func blocks(facing: float, body: Rect2, source: Vector2) -> bool:
	var ahead := (source.x - body.get_center().x) * facing > 0.0
	return ahead and source.y > body.position.y
