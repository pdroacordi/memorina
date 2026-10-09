class_name ForegroundMathTest extends GdUnitTestSuite

## A near piece crosses the screen scroll_scale times as fast as the world, wherever the room sits;
## coverage is the covered share of a body; the fade moves at one rate and holds at delta 0.


func test_the_offset_is_zero_at_the_play_plane_and_at_the_anchor() -> void:
	assert_vector(ForegroundMath.parallax_offset(Vector2(10, 20), Vector2(500, 90), Vector2.ONE)).is_equal(Vector2.ZERO)
	assert_vector(ForegroundMath.parallax_offset(Vector2(10, 20), Vector2(10, 20), Vector2(1.5, 1.5))).is_equal(Vector2.ZERO)

func test_a_centre_100_px_left_moves_a_1_5_piece_50_px_right() -> void:
	var offset := ForegroundMath.parallax_offset(Vector2(300, 0), Vector2(200, 0), Vector2(1.5, 1.0))
	assert_vector(offset).is_equal(Vector2(50, 0))

func test_screen_speed_is_scale_times_world_speed() -> void:
	var anchor := Vector2(800, 100)
	var scale := Vector2(1.4, 1.2)
	var screen_a := anchor + ForegroundMath.parallax_offset(anchor, Vector2(600, 100), scale) - Vector2(600, 100)
	var screen_b := anchor + ForegroundMath.parallax_offset(anchor, Vector2(610, 105), scale) - Vector2(610, 105)
	assert_vector(screen_b - screen_a).is_equal_approx(Vector2(-14, -6), Vector2(0.001, 0.001))

func test_moving_anchor_and_centre_together_changes_nothing() -> void:
	var near := ForegroundMath.parallax_offset(Vector2(100, 50), Vector2(40, 10), Vector2(1.3, 1.3))
	var far := ForegroundMath.parallax_offset(Vector2(7300, 6050), Vector2(7240, 6010), Vector2(1.3, 1.3))
	assert_vector(far).is_equal_approx(near, Vector2(0.001, 0.001))

func test_a_horizontal_scale_leaves_y_alone() -> void:
	assert_float(ForegroundMath.parallax_offset(Vector2(0, 300), Vector2(0, 0), Vector2(1.3, 1.0)).y).is_equal(0.0)

func test_coverage() -> void:
	var body := Rect2(0, 0, 10, 20)
	assert_float(ForegroundMath.coverage(Rect2(50, 50, 10, 10), body)).is_equal(0.0)
	assert_float(ForegroundMath.coverage(Rect2(-5, -5, 40, 40), body)).is_equal(1.0)
	assert_float(ForegroundMath.coverage(Rect2(5, -5, 40, 40), body)).is_equal_approx(0.5, 0.0001)
	assert_float(ForegroundMath.coverage(Rect2(0, 0, 40, 40), Rect2(1, 1, 0, 10))).is_equal(0.0)

func test_the_fade() -> void:
	# 1 -> 0.3 in 0.25 s is 2.8 alpha per second.
	assert_float(ForegroundMath.fade_toward(1.0, 0.3, 0.3, 0.25, 0.1)).is_equal_approx(0.72, 0.0001)
	assert_float(ForegroundMath.fade_toward(0.35, 0.3, 0.3, 0.25, 0.1)).is_equal(0.3)
	assert_float(ForegroundMath.fade_toward(1.0, 0.3, 0.3, 0.0, 0.1)).is_equal(0.3)
	assert_float(ForegroundMath.fade_toward(0.6, 0.3, 0.3, 0.25, 0.0)).is_equal(0.6)
