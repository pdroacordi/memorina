class_name FrostShellTest extends GdUnitTestSuite

## A body leaves the ring only when its whole rect is outside it, whichever way it goes.

const CENTRE := Vector2(100, 100)
const RADIUS := 50.0
## 16x48 px standing on its feet.
const BODY := Vector2(16, 48)


func _body_at(feet: Vector2) -> Rect2:
	return Rect2(feet - Vector2(BODY.x * 0.5, BODY.y), BODY)

func test_leaving_upward_needs_the_feet_out() -> void:
	assert_bool(FrostShell.clear_of(CENTRE, RADIUS, _body_at(Vector2(100, 55)))).is_false()
	assert_bool(FrostShell.clear_of(CENTRE, RADIUS, _body_at(Vector2(100, 45)))).is_true()

func test_leaving_downward_needs_the_head_out() -> void:
	# Feet well below the ring, head still inside: by the feet this counted as out.
	assert_bool(FrostShell.clear_of(CENTRE, RADIUS, _body_at(Vector2(100, 190)))).is_false()
	assert_bool(FrostShell.clear_of(CENTRE, RADIUS, _body_at(Vector2(100, 200)))).is_true()

func test_a_body_over_the_centre_is_never_clear() -> void:
	assert_bool(FrostShell.clear_of(CENTRE, RADIUS, _body_at(Vector2(100, 110)))).is_false()
