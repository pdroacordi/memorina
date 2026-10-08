class_name IceSheetShapeTest extends GdUnitTestSuite

## Ice keeps the shape it was captured in: flat, a wedge, or a steep face.

const WIDTH := 4.0

func _shape(tops: Array[float], thickness := 6.0) -> IceSheetShape:
	var shape := IceSheetShape.new(tops.size(), WIDTH, 100.0)
	for column in tops.size():
		shape.capture(column, tops[column], tops[column] + thickness)
	return shape

func test_flat_ice_is_a_flat_chain() -> void:
	var points := _shape([50.0, 50.0, 50.0, 50.0]).segment_points(2)
	assert_int(points.size()).is_equal(3)
	for point: Vector2 in points:
		assert_float(point.y).is_equal(50.0)
	assert_float(points[0].x).is_equal(100.0)
	assert_float(points[2].x).is_equal(116.0)

func test_a_wedge_keeps_a_constant_slope() -> void:
	var points := _shape([60.0, 56.0, 52.0, 48.0, 44.0, 40.0, 36.0, 32.0]).segment_points(2)
	for joint in range(1, points.size() - 2):
		assert_float(points[joint + 1].y - points[joint].y).is_equal(-8.0)
	for joint in points.size() - 1:
		assert_float(points[joint + 1].y).is_less(points[joint].y)

func test_a_steep_run_is_one_face() -> void:
	var shape := _shape([40.0, 10.0], 4.0)
	assert_float(shape.band(1).y).is_equal(40.0)
	assert_float(shape.band(0).y).is_equal(44.0)

func test_a_released_column_leaves_no_ice() -> void:
	var shape := _shape([30.0, 30.0])
	shape.release(0)
	assert_bool(shape.has(0)).is_false()
	assert_vector(shape.y_range()).is_equal(Vector2(30.0, 36.0))
	shape.release(1)
	assert_vector(shape.y_range()).is_equal(Vector2.ZERO)

func test_a_joint_beside_a_column_without_ice_takes_the_other() -> void:
	var shape := _shape([20.0, 30.0])
	shape.release(0)
	assert_float(shape.segment_points(1)[1].y).is_equal(30.0)

func test_up_to_45_degrees_is_walkable() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(8, -8), Vector2(12, -20)])
	assert_bool(IceSheetShape.walkable(points, 0, deg_to_rad(45.0))).is_true()
	assert_bool(IceSheetShape.walkable(points, 1, deg_to_rad(45.0))).is_false()
