class_name GrassContactTest extends GdUnitTestSuite

## Bodies on the walk line push grass away from their centre, fading past their width (architecture/generated-grass).

const WALK := 100.0


func _xs() -> PackedFloat32Array:
	return PackedFloat32Array([0.0, 8.0, 12.0, 20.0, 40.0])

func test_each_side_leans_away_from_the_centre() -> void:
	var targets := GrassContact.targets(_xs(), WALK, [Rect2(0, 60, 24, 40)], 0.85, 8.0)
	assert_float(targets[0]).is_less(0.0)
	assert_float(targets[3]).is_greater(0.0)

func test_the_push_fades_to_nothing_past_the_reach() -> void:
	var targets := GrassContact.targets(_xs(), WALK, [Rect2(0, 60, 24, 40)], 0.85, 8.0)
	assert_float(targets[4]).is_equal(0.0)

func test_a_body_off_the_walk_line_pushes_nothing() -> void:
	var targets := GrassContact.targets(_xs(), WALK, [Rect2(0, 20, 24, 40)], 0.85, 8.0)
	for value: float in targets:
		assert_float(value).is_equal(0.0)

func test_an_empty_rect_pushes_nothing() -> void:
	var targets := GrassContact.targets(_xs(), WALK, [Rect2()], 0.85, 8.0)
	assert_float(targets[1]).is_equal(0.0)
