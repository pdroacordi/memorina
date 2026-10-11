class_name HelixSteerTest extends GdUnitTestSuite

## Up or the hand side climbs, Down or the other side descends, vertical wins a diagonal from 0.5, mirrored for hand -1.

const RIGHT := Vector2(1.0, 0.0)
const LEFT := Vector2(-1.0, 0.0)


func test_up_and_the_hand_side_climb() -> void:
	assert_int(HelixSteer.direction(Vector2(0.0, -1.0), 1)).is_equal(1)
	assert_int(HelixSteer.direction(RIGHT, 1)).is_equal(1)

func test_down_and_the_other_side_descend() -> void:
	assert_int(HelixSteer.direction(Vector2(0.0, 1.0), 1)).is_equal(-1)
	assert_int(HelixSteer.direction(LEFT, 1)).is_equal(-1)

func test_nothing_held_is_still() -> void:
	assert_int(HelixSteer.direction(Vector2.ZERO, 1)).is_equal(0)

func test_vertical_wins_a_diagonal_from_half_way() -> void:
	assert_int(HelixSteer.direction(Vector2(-0.8, -0.5), 1)).is_equal(1)
	assert_int(HelixSteer.direction(Vector2(-0.8, -0.4), 1)).is_equal(-1)

func test_a_mirrored_stair_mirrors_the_sides() -> void:
	assert_int(HelixSteer.direction(LEFT, -1)).is_equal(1)
	assert_int(HelixSteer.direction(RIGHT, -1)).is_equal(-1)
	assert_int(HelixSteer.direction(Vector2(0.0, -1.0), -1)).is_equal(1)
