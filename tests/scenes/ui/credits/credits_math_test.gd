class_name CreditsMathTest extends GdUnitTestSuite

## The roll moves in whole art px, stops with its last row centred, lasts its travel plus the hold, and fades rows at
## both edges.


func test_the_travel_ends_with_the_last_row_centred() -> void:
	# A 400 px column through a 180 px view, a 48 px logo last: its top ends at 90 - 24 = 66 px.
	var rolled := CreditsMath.travel(400.0, 180.0, 48.0)
	assert_float(rolled).is_equal(466.0)
	assert_float(180.0 - rolled + 400.0 - 48.0).is_equal(66.0)

func test_the_offset_is_whole_art_px_and_holds_at_the_travel() -> void:
	assert_int(CreditsMath.offset(0.0, 12.0, 466.0)).is_equal(0)
	assert_int(CreditsMath.offset(0.99, 12.0, 466.0)).is_equal(11)
	assert_int(CreditsMath.offset(1.0, 12.0, 466.0)).is_equal(12)
	assert_int(CreditsMath.offset(100.0, 12.0, 466.0)).is_equal(466)
	assert_int(CreditsMath.offset(-1.0, 12.0, 466.0)).is_equal(0)

func test_the_duration_is_the_travel_at_the_speed_plus_the_hold() -> void:
	assert_float(CreditsMath.duration(400.0, 180.0, 48.0, 12.0, 4.0)).is_equal_approx(466.0 / 12.0 + 4.0, 0.0001)
	assert_float(CreditsMath.duration(400.0, 180.0, 48.0, 0.0, 4.0)).is_equal(4.0)

func test_rows_fade_in_at_the_bottom_and_out_at_the_top() -> void:
	assert_float(CreditsMath.edge_alpha(180.0, 180.0, 24.0)).is_equal(0.0)
	assert_float(CreditsMath.edge_alpha(168.0, 180.0, 24.0)).is_equal(0.5)
	assert_float(CreditsMath.edge_alpha(90.0, 180.0, 24.0)).is_equal(1.0)
	assert_float(CreditsMath.edge_alpha(12.0, 180.0, 24.0)).is_equal(0.5)
	assert_float(CreditsMath.edge_alpha(-5.0, 180.0, 24.0)).is_equal(0.0)
	assert_float(CreditsMath.edge_alpha(200.0, 180.0, 24.0)).is_equal(0.0)
