class_name GuardianGustTest extends GdUnitTestSuite

## A gust carries a body in front of its guardian along the floor while the move swings, up past a jump's apex, and
## nothing behind it, above `push_height` or outside the swing (GRD-04, architecture/grd-04-autumn-and-summer-guardians).


func _gust(speed: float = 1700.0) -> GuardianAttack:
	var attack := GuardianAttack.new()
	attack.push_speed = speed
	return attack

func test_it_pushes_a_body_in_front_away_from_the_guardian() -> void:
	var push := GuardianGust.push_for(_gust(), true, 1, Vector2(800, 288), Vector2(1000, 288))
	assert_vector(push).is_equal(Vector2(1700, 0))
	push = GuardianGust.push_for(_gust(), true, -1, Vector2(800, 288), Vector2(300, 250))
	assert_vector(push).is_equal(Vector2(-1700, 0))

func test_nothing_behind_above_or_outside_the_swing() -> void:
	var origin := Vector2(800, 288)
	assert_vector(GuardianGust.push_for(_gust(), true, 1, origin, Vector2(600, 288))).is_equal(Vector2.ZERO)
	assert_vector(GuardianGust.push_for(_gust(), true, 1, origin, Vector2(1000, 288 - 250))).is_equal(Vector2.ZERO)
	# A jump's apex (144 px up) is still carried, so a body jumping at the wall stays pressed to it.
	assert_vector(GuardianGust.push_for(_gust(), true, 1, origin, Vector2(1000, 288 - 150))).is_equal(Vector2(1700, 0))
	assert_vector(GuardianGust.push_for(_gust(), false, 1, origin, Vector2(1000, 288))).is_equal(Vector2.ZERO)
	assert_vector(GuardianGust.push_for(_gust(0.0), true, 1, origin, Vector2(1000, 288))).is_equal(Vector2.ZERO)
	assert_vector(GuardianGust.push_for(null, true, 1, origin, Vector2(1000, 288))).is_equal(Vector2.ZERO)
