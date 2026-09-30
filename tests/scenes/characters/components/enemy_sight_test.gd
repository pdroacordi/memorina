class_name EnemySightTest extends GdUnitTestSuite

## A creature goes for the nearest presence it sees: Ivo, or his shadow.

func test_the_nearest_presence_wins() -> void:
	var points := PackedVector2Array([Vector2(300, 0), Vector2(-80, 0), Vector2(120, 0)])
	assert_int(EnemySight.nearest_index(Vector2.ZERO, points)).is_equal(1)

func test_a_tie_keeps_the_first() -> void:
	var points := PackedVector2Array([Vector2(50, 0), Vector2(-50, 0)])
	assert_int(EnemySight.nearest_index(Vector2.ZERO, points)).is_equal(0)

func test_nothing_seen_is_no_one() -> void:
	assert_int(EnemySight.nearest_index(Vector2.ZERO, PackedVector2Array())).is_equal(-1)
