class_name HelixProjectionTest extends GdUnitTestSuite

## The turning tower's projection: Ivo's plane maps 1:1, the silhouette is the wall's widest point, perspective below
## and above the eye, near and far points move opposite ways as the tower turns, and the stair is screw-symmetric.

const SHAPE := preload("res://resources/world/helix/bell_tower_helix.tres")
const LOOK := preload("res://resources/world/helix/bell_tower_look.tres")
const EPSILON := 0.001


func test_ivos_plane_maps_one_to_one_for_any_eye_and_turn() -> void:
	for eye: float in [-1300.0, -600.0, 0.0, 200.0]:
		for phi: float in [0.0, 1.3, 4.0]:
			for x: float in [-80.0, 0.0, 50.0]:
				var point := Vector3(x, -500.0, SHAPE.walk_radius)
				var screen := HelixProjection.project(SHAPE, point, eye)
				assert_float(screen.x).is_equal_approx(x, EPSILON)
				assert_float(screen.y).is_equal_approx(-500.0, EPSILON)

func test_the_silhouette_is_the_widest_point_of_the_wall() -> void:
	var widest := 0.0
	for n: int in 20000:
		var beta := TAU * n / 20000.0
		widest = maxf(widest, absf(HelixProjection.project_polar(SHAPE, 1, beta, SHAPE.wall_radius, 0.0, 0.0, 0.0).x))
	assert_float(HelixProjection.silhouette(SHAPE)).is_equal_approx(widest, 0.01)
	assert_float(HelixProjection.silhouette(SHAPE)).is_equal_approx(127.95, 0.01)

func test_below_the_eye_the_front_of_a_ring_is_lower_than_its_back() -> void:
	var front := HelixProjection.project_polar(SHAPE, 1, 0.0, SHAPE.inner_radius, 0.0, 0.0, -400.0)
	var back := HelixProjection.project_polar(SHAPE, 1, PI, SHAPE.inner_radius, 0.0, 0.0, -400.0)
	assert_float(front.y).is_greater(back.y)
	var front_above := HelixProjection.project_polar(SHAPE, 1, 0.0, SHAPE.inner_radius, -800.0, 0.0, -400.0)
	var back_above := HelixProjection.project_polar(SHAPE, 1, PI, SHAPE.inner_radius, -800.0, 0.0, -400.0)
	assert_float(front_above.y).is_less(back_above.y)

func test_as_the_tower_turns_near_and_far_points_move_opposite_ways() -> void:
	var near_before := HelixProjection.project_polar(SHAPE, 1, 0.0, SHAPE.walk_radius, -300.0, 0.0, -300.0)
	var near_after := HelixProjection.project_polar(SHAPE, 1, 0.0, SHAPE.walk_radius, -300.0, 0.1, -300.0)
	var far_before := HelixProjection.project_polar(SHAPE, 1, PI, SHAPE.wall_radius, -300.0, 0.0, -300.0)
	var far_after := HelixProjection.project_polar(SHAPE, 1, PI, SHAPE.wall_radius, -300.0, 0.1, -300.0)
	assert_float(signf(near_after.x - near_before.x)).is_equal(-signf(far_after.x - far_before.x))

func test_the_stair_is_screw_symmetric() -> void:
	var step := TAU / SHAPE.steps_per_turn
	var riser := SHAPE.riser()
	for index: int in [10, 40, 70]:
		var here := HelixFaces.step_faces(SHAPE, LOOK, 1, 2.0, -600.0, index)
		var there := HelixFaces.step_faces(SHAPE, LOOK, 1, 2.0 + step, -600.0 - riser, index + 1)
		assert_int(there.size()).is_equal(here.size())
		for f: int in here.size():
			assert_int(there[f].points.size()).is_equal(here[f].points.size())
			for p: int in here[f].points.size():
				var moved := here[f].points[p] + Vector2(0.0, -riser)
				assert_float(there[f].points[p].distance_to(moved)).is_less(0.01)
