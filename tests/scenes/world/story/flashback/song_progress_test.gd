class_name SongProgressTest extends GdUnitTestSuite

## Progress is 0 up to its first mark, 1 from its last, linear between; a zero span is a step.


func test_it_runs_from_zero_to_one_between_its_marks() -> void:
	assert_float(SongProgress.at(0.0, 1.0, 3.0)).is_equal(0.0)
	assert_float(SongProgress.at(1.0, 1.0, 3.0)).is_equal(0.0)
	assert_float(SongProgress.at(2.0, 1.0, 3.0)).is_equal_approx(0.5, 0.0001)
	assert_float(SongProgress.at(3.0, 1.0, 3.0)).is_equal(1.0)
	assert_float(SongProgress.at(40.0, 1.0, 3.0)).is_equal(1.0)

func test_a_zero_span_is_a_step() -> void:
	assert_float(SongProgress.at(1.9, 2.0, 2.0)).is_equal(0.0)
	assert_float(SongProgress.at(2.0, 2.0, 2.0)).is_equal(1.0)
