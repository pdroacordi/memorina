class_name MemoryFieldMathTest extends GdUnitTestSuite

## Must match `gh_shape_distance()` and `gh_influence()` in greyhush_common.gdshaderinc.

const CORE := 100.0
const FEATHER := 20.0

func _circle(r: float) -> Vector2:
	return Vector2(r, r)

# --- the falloff ------------------------------------------------------------

func test_the_core_is_flat_at_full_strength() -> void:
	assert_float(MemoryFieldMath.disc_influence(-50.0, FEATHER, 1.0)).is_equal_approx(1.0, 0.0001)
	assert_float(MemoryFieldMath.disc_influence(0.0, FEATHER, 1.0)).is_equal_approx(1.0, 0.0001)

func test_the_feather_falls_linearly_to_nothing() -> void:
	assert_float(MemoryFieldMath.disc_influence(FEATHER * 0.5, FEATHER, 1.0)).is_equal_approx(0.5, 0.0001)
	assert_float(MemoryFieldMath.disc_influence(FEATHER * 0.25, FEATHER, 1.0)).is_equal_approx(0.75, 0.0001)

func test_nothing_reaches_past_the_feather() -> void:
	assert_float(MemoryFieldMath.disc_influence(FEATHER, FEATHER, 1.0)).is_equal_approx(0.0, 0.0001)
	assert_float(MemoryFieldMath.disc_influence(FEATHER + 1.0, FEATHER, 1.0)).is_equal_approx(0.0, 0.0001)

func test_a_zero_feather_gives_a_hard_edge() -> void:
	assert_float(MemoryFieldMath.disc_influence(0.0, 0.0, 1.0)).is_equal_approx(1.0, 0.0001)
	assert_float(MemoryFieldMath.disc_influence(0.01, 0.0, 1.0)).is_equal_approx(0.0, 0.0001)

func test_a_negative_source_takes_memory_away() -> void:
	assert_float(MemoryFieldMath.disc_influence(-1.0, FEATHER, -0.5)).is_equal_approx(-0.5, 0.0001)
	assert_float(MemoryFieldMath.disc_influence(FEATHER * 0.5, FEATHER, -0.5)).is_equal_approx(-0.25, 0.0001)

# --- circle distance --------------------------------------------------------

func test_a_circle_is_solid_inside_its_radius() -> void:
	var d := MemoryFieldMath.source_distance(Vector2(30.0, 0.0), _circle(CORE), MemoryFieldMath.Shape.CIRCLE)
	assert_float(d).is_less(0.0)

func test_a_circle_measures_outward_from_its_rim() -> void:
	var d := MemoryFieldMath.source_distance(Vector2(CORE + 15.0, 0.0), _circle(CORE), MemoryFieldMath.Shape.CIRCLE)
	assert_float(d).is_equal_approx(15.0, 0.0001)

# --- rect distance ----------------------------------------------------------

func test_a_rect_is_solid_inside_its_half_extents() -> void:
	var half := Vector2(80.0, 40.0)
	var d := MemoryFieldMath.source_distance(Vector2(70.0, 30.0), half, MemoryFieldMath.Shape.RECT)
	assert_float(d).is_less(0.0)

func test_a_rect_measures_outward_from_its_face() -> void:
	var half := Vector2(80.0, 40.0)
	var d := MemoryFieldMath.source_distance(Vector2(100.0, 0.0), half, MemoryFieldMath.Shape.RECT)
	assert_float(d).is_equal_approx(20.0, 0.0001)

## Rect distance at a corner is diagonal, not the larger axis distance.
func test_a_rect_corner_measures_diagonally() -> void:
	var half := Vector2(80.0, 40.0)
	var d := MemoryFieldMath.source_distance(Vector2(83.0, 44.0), half, MemoryFieldMath.Shape.RECT)
	assert_float(d).is_equal_approx(5.0, 0.0001)

func test_a_rect_covers_a_corner_a_circle_would_miss() -> void:
	var half := Vector2(80.0, 40.0)
	var corner := Vector2(79.0, 39.0)
	var rect_d := MemoryFieldMath.source_distance(corner, half, MemoryFieldMath.Shape.RECT)
	var circle_d := MemoryFieldMath.source_distance(corner, _circle(40.0), MemoryFieldMath.Shape.CIRCLE)
	assert_float(rect_d).is_less(0.0)
	assert_float(circle_d).is_greater(0.0)

# --- capsule distance ------------------------------------------------------

## Capsule extent.y is the straight section's half-height; extent.x is its cap radius.
func test_a_capsule_is_solid_along_its_straight_section() -> void:
	var extent := Vector2(12.0, 16.0)
	var d := MemoryFieldMath.source_distance(Vector2(5.0, 10.0), extent, MemoryFieldMath.Shape.CAPSULE)
	assert_float(d).is_less(0.0)

func test_a_capsule_measures_sideways_from_its_flank() -> void:
	var extent := Vector2(12.0, 16.0)
	var d := MemoryFieldMath.source_distance(Vector2(20.0, 0.0), extent, MemoryFieldMath.Shape.CAPSULE)
	assert_float(d).is_equal_approx(8.0, 0.0001)

func test_a_capsule_is_rounded_at_its_ends() -> void:
	var extent := Vector2(12.0, 16.0)
	var d := MemoryFieldMath.source_distance(Vector2(0.0, 28.0), extent, MemoryFieldMath.Shape.CAPSULE)
	assert_float(d).is_equal_approx(0.0, 0.0001)

func test_a_capsule_excludes_the_corner_a_rect_would_include() -> void:
	var extent := Vector2(12.0, 16.0)
	var corner := Vector2(11.0, 26.0)
	var capsule_d := MemoryFieldMath.source_distance(corner, extent, MemoryFieldMath.Shape.CAPSULE)
	var rect_d := MemoryFieldMath.source_distance(corner, Vector2(12.0, 28.0), MemoryFieldMath.Shape.RECT)
	assert_float(capsule_d).is_greater(0.0)
	assert_float(rect_d).is_less(0.0)

# --- the falloff position a Curve is sampled at ----------------------------

func test_the_falloff_position_spans_the_feather() -> void:
	assert_float(MemoryFieldMath.falloff_position(0.0, 20.0)).is_equal_approx(0.0, 0.0001)
	assert_float(MemoryFieldMath.falloff_position(10.0, 20.0)).is_equal_approx(0.5, 0.0001)
	assert_float(MemoryFieldMath.falloff_position(20.0, 20.0)).is_equal_approx(1.0, 0.0001)

func test_the_falloff_position_is_clamped() -> void:
	assert_float(MemoryFieldMath.falloff_position(-5.0, 20.0)).is_equal_approx(0.0, 0.0001)
	assert_float(MemoryFieldMath.falloff_position(999.0, 20.0)).is_equal_approx(1.0, 0.0001)

# --- culling reach ----------------------------------------------------------

## Reach must include feather; capsule extent is radius plus straight half-height.
func test_reach_covers_the_furthest_point_of_every_shape() -> void:
	var feather := 12.0
	for shape: MemoryFieldMath.Shape in [
			MemoryFieldMath.Shape.CIRCLE,
			MemoryFieldMath.Shape.RECT,
			MemoryFieldMath.Shape.CAPSULE]:
		var source: MemorySource = auto_free(MemorySource.new())
		source.shape = shape
		source.radius = 12.0
		source.height = 16.0
		source.rect_size = Vector2(24.0, 32.0)
		source.feather = feather
		var reach := source.reach()
		# Walk the rim and check nothing influential lies outside reach().
		for step: int in 32:
			var dir := Vector2.RIGHT.rotated(TAU * float(step) / 32.0)
			var probe: Vector2 = dir * reach
			var dist: float = MemoryFieldMath.source_distance(probe, source.extent(), shape)
			assert_float(dist).override_failure_message(
				"shape %d leaks influence at its reach()" % shape).is_greater_equal(feather)

# --- combining ---# --- combining --------------------------------------------------------------

func test_sources_add_on_top_of_the_baseline() -> void:
	assert_float(MemoryFieldMath.combine(0.5, PackedFloat32Array([0.25]))).is_equal_approx(0.75, 0.0001)

func test_the_result_never_leaves_zero_to_one() -> void:
	assert_float(MemoryFieldMath.combine(0.8, PackedFloat32Array([0.5, 0.5]))).is_equal_approx(1.0, 0.0001)
	assert_float(MemoryFieldMath.combine(0.2, PackedFloat32Array([-0.9]))).is_equal_approx(0.0, 0.0001)

func test_no_sources_leaves_the_baseline_alone() -> void:
	assert_float(MemoryFieldMath.combine(0.8, PackedFloat32Array())).is_equal_approx(0.8, 0.0001)
