class_name HelixStairShapeTest extends GdUnitTestSuite

## A shape refuses numbers that cannot make a turning stair.

const BELL_TOWER := preload("res://resources/world/helix/bell_tower_helix.tres")


func test_the_bell_tower_shape_is_sound() -> void:
	assert_array(Array(BELL_TOWER.problems())).is_empty()
	assert_float(BELL_TOWER.head_rise()).is_equal(1120.0)
	assert_int(BELL_TOWER.step_count()).is_equal(112)

func test_the_radii_must_grow_out_to_the_eye() -> void:
	var shape := BELL_TOWER.duplicate() as HelixStairShape
	shape.walk_radius = 150.0
	assert_str("\n".join(shape.problems())).contains("radii must grow")
	shape = BELL_TOWER.duplicate() as HelixStairShape
	shape.eye_distance = 100.0
	assert_str("\n".join(shape.problems())).contains("radii must grow")

func test_the_head_rise_must_land_on_the_cell_grid() -> void:
	var shape := BELL_TOWER.duplicate() as HelixStairShape
	shape.turns = 3.25
	assert_str("\n".join(shape.problems())).contains("multiple of 32")

func test_a_whole_or_fractional_turn_count_is_fine_on_the_grid() -> void:
	var shape := BELL_TOWER.duplicate() as HelixStairShape
	shape.turns = 3.25
	shape.pitch = 128.0
	assert_array(Array(shape.problems())).is_empty()

func test_the_turns_must_hold_a_whole_number_of_steps() -> void:
	var shape := BELL_TOWER.duplicate() as HelixStairShape
	shape.turns = 3.2
	assert_str("\n".join(shape.problems())).contains("whole number of steps")
	shape.steps_per_turn = 30
	assert_array(Array(shape.problems())).is_empty()

func test_a_stair_needs_eight_steps_a_turn_and_a_speed() -> void:
	var shape := BELL_TOWER.duplicate() as HelixStairShape
	shape.steps_per_turn = 6
	shape.speed_scale = 0.0
	assert_int(shape.problems().size()).is_equal(2)
