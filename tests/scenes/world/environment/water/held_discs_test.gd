class_name HeldDiscsTest extends GdUnitTestSuite

## The water a shell holds out rises around it (design 02 section 7.4, Redoma then Congelar).

const WIDTH := 2.0

func _floors(count: int, y: float) -> PackedFloat32Array:
	var floors := PackedFloat32Array()
	floors.resize(count)
	floors.fill(y)
	return floors

func test_a_point_inside_a_disc_is_held() -> void:
	var discs := [Vector3(0, 0, 10)]
	assert_bool(HeldDiscs.contains(Vector2(9, 0), discs)).is_true()
	assert_bool(HeldDiscs.contains(Vector2(10, 0), discs)).is_false()

func test_no_disc_raises_nothing() -> void:
	assert_float(HeldDiscs.displaced_rise(0.0, WIDTH, 0.0, _floors(100, 100.0), [], 50.0)).is_equal(0.0)

func test_a_disc_above_the_water_raises_nothing() -> void:
	var discs := [Vector3(100, -60, 40)]
	assert_float(HeldDiscs.held_area(0.0, WIDTH, 0.0, _floors(100, 100.0), discs)).is_equal(0.0)

func test_a_submerged_disc_holds_out_its_area() -> void:
	var discs := [Vector3(100, 50, 20)]
	var area := HeldDiscs.held_area(0.0, WIDTH, 0.0, _floors(100, 100.0), discs)
	assert_float(area).is_equal_approx(PI * 400.0, 20.0)

func test_the_rise_spreads_the_held_water_over_the_wet_width() -> void:
	var discs := [Vector3(100, 50, 20)]
	var rise := HeldDiscs.displaced_rise(0.0, WIDTH, 0.0, _floors(100, 100.0), discs, 50.0)
	assert_float(rise).is_equal_approx(PI * 400.0 / 200.0, 0.5)

func test_the_rise_stops_at_the_cap() -> void:
	var discs := [Vector3(0, 0, 150)]
	assert_float(HeldDiscs.displaced_rise(0.0, WIDTH, 0.0, _floors(100, 100.0), discs, 30.0)).is_equal(30.0)
