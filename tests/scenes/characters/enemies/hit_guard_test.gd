class_name HitGuardTest extends GdUnitTestSuite

## The crab's shell turns away a hit from in front at body height, never one from behind or from above.

## A 36x22 body standing on y 0, centred on x 0.
const BODY := Rect2(-18.0, -22.0, 36.0, 22.0)


func test_a_hit_from_in_front_at_body_height_is_blocked() -> void:
	assert_bool(HitGuard.blocks(1.0, BODY, Vector2(30.0, 0.0))).is_true()
	assert_bool(HitGuard.blocks(-1.0, BODY, Vector2(-30.0, 0.0))).is_true()
	assert_bool(HitGuard.blocks(1.0, BODY, Vector2(30.0, -10.0))).is_true()

func test_a_hit_from_behind_lands() -> void:
	assert_bool(HitGuard.blocks(1.0, BODY, Vector2(-30.0, 0.0))).is_false()
	assert_bool(HitGuard.blocks(-1.0, BODY, Vector2(30.0, 0.0))).is_false()

## A pogo: Ivo's hitbox origin is his feet, above the shell.
func test_a_hit_from_above_lands_on_either_side() -> void:
	assert_bool(HitGuard.blocks(1.0, BODY, Vector2(10.0, -30.0))).is_false()
	assert_bool(HitGuard.blocks(-1.0, BODY, Vector2(-10.0, -30.0))).is_false()
	assert_bool(HitGuard.blocks(1.0, BODY, Vector2(10.0, -22.0))).is_false()
