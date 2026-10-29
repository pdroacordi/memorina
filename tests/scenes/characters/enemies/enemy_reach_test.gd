class_name EnemyReachTest extends GdUnitTestSuite

## A move's reach is a box authored facing east, mirrored with the facing; its edges count.

const FORWARD := Rect2(0, -40, 60, 48)
const BELOW := Rect2(-20, 0, 40, 120)
const OVERHEAD := Rect2(-24, -120, 48, 80)
const ORIGIN := Vector2(100, 50)


func test_a_forward_box_holds_in_front_only() -> void:
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(30, 0))).is_true()
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(-30, 0))).is_false()

func test_the_box_mirrors_with_the_facing() -> void:
	assert_bool(EnemyReach.holds(FORWARD, -1.0, ORIGIN, ORIGIN + Vector2(-30, 0))).is_true()
	assert_bool(EnemyReach.holds(FORWARD, -1.0, ORIGIN, ORIGIN + Vector2(30, 0))).is_false()
	assert_that(EnemyReach.mirrored(FORWARD, -1.0)).is_equal(Rect2(-60, -40, 60, 48))
	assert_that(EnemyReach.mirrored(FORWARD, 1.0)).is_equal(FORWARD)

func test_edges_are_inside() -> void:
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(60, 8))).is_true()
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(0, -40))).is_true()
	assert_bool(EnemyReach.holds(FORWARD, -1.0, ORIGIN, ORIGIN + Vector2(-60, 8))).is_true()
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(60.5, 0))).is_false()

func test_height_bounds_a_forward_box() -> void:
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(30, -41))).is_false()
	assert_bool(EnemyReach.holds(FORWARD, 1.0, ORIGIN, ORIGIN + Vector2(30, 9))).is_false()

func test_below_and_overhead_boxes() -> void:
	assert_bool(EnemyReach.holds(BELOW, 1.0, ORIGIN, ORIGIN + Vector2(10, 100))).is_true()
	assert_bool(EnemyReach.holds(BELOW, -1.0, ORIGIN, ORIGIN + Vector2(10, 100))).is_true()
	assert_bool(EnemyReach.holds(BELOW, 1.0, ORIGIN, ORIGIN + Vector2(10, -1))).is_false()
	assert_bool(EnemyReach.holds(OVERHEAD, 1.0, ORIGIN, ORIGIN + Vector2(0, -100))).is_true()
	assert_bool(EnemyReach.holds(OVERHEAD, 1.0, ORIGIN, ORIGIN + Vector2(0, 0))).is_false()
