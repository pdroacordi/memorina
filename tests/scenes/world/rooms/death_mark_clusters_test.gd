class_name DeathMarkClustersTest extends GdUnitTestSuite

## Deaths close together merge into one mark that deepens; far apart, they
## leave their own; a region never shows more than max_marks (the user's
## decision, 2026-10-01 - and the field draws at most 32 sources on screen).

func test_no_deaths_no_marks() -> void:
	assert_array(DeathMarkClusters.cluster(PackedVector2Array(), 48.0, 6)).is_empty()

func test_deaths_close_together_deepen_one_mark() -> void:
	var marks := DeathMarkClusters.cluster(PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 10)]), 48.0, 6)
	assert_int(marks.size()).is_equal(1)
	assert_int(marks[0]["deaths"]).is_equal(3)
	assert_vector(marks[0]["centre"]).is_equal_approx(Vector2(10, 10.0 / 3.0), Vector2(0.001, 0.001))

func test_deaths_far_apart_leave_their_own_marks() -> void:
	var marks := DeathMarkClusters.cluster(PackedVector2Array([Vector2(0, 0), Vector2(500, 0)]), 48.0, 6)
	assert_int(marks.size()).is_equal(2)

func test_past_the_cap_a_death_deepens_the_nearest_mark() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(500, 0), Vector2(1000, 0), Vector2(900, 0)])
	var marks := DeathMarkClusters.cluster(points, 48.0, 2)
	assert_int(marks.size()).is_equal(2)
	assert_int(marks[1]["deaths"]).is_equal(3)

func test_the_same_deaths_always_draw_the_same_marks() -> void:
	var points := PackedVector2Array([Vector2(3, 4), Vector2(300, 9), Vector2(30, 4), Vector2(320, 40)])
	assert_array(DeathMarkClusters.cluster(points, 48.0, 6)).is_equal(DeathMarkClusters.cluster(points, 48.0, 6))

func test_a_mark_deepens_up_to_its_cap() -> void:
	var stats := DeathMarkStats.new()
	assert_float(stats.strength_for(1)).is_equal(stats.strength)
	assert_float(stats.strength_for(2)).is_greater(stats.strength_for(1))
	assert_float(stats.strength_for(100)).is_equal(stats.max_strength)
	assert_float(stats.radius_for(100)).is_equal(stats.max_radius)
