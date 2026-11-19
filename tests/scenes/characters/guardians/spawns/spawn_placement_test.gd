class_name SpawnPlacementTest extends GdUnitTestSuite

## Where each spawned instance goes (architecture/grd-12-guardian-fight-engine).

const ARENA := Rect2(0.0, 0.0, 1000.0, 400.0)

var _ctx: SpawnContext


func before_test() -> void:
	_ctx = SpawnContext.make(Vector2(300.0, 400.0), 1, Vector2(600.0, 400.0), ARENA, 400.0)

func test_front_lines_up_ahead_of_the_feet() -> void:
	var spawn := _spawn(GuardianSpawn.Placement.FRONT, 3, 50.0)
	spawn.offset = Vector2(20.0, -10.0)
	assert_array(SpawnPlacement.points(spawn, _ctx)).is_equal([Vector2(320.0, 390.0), Vector2(370.0, 390.0),
			Vector2(420.0, 390.0)])
	_ctx.facing = -1
	assert_vector(SpawnPlacement.points(spawn, _ctx)[1]).is_equal(Vector2(230.0, 390.0))

func test_at_ivo_and_around_ivo_aim_at_his_feet_on_the_floor() -> void:
	assert_array(SpawnPlacement.points(_spawn(GuardianSpawn.Placement.AT_IVO, 2, 0.0), _ctx)).is_equal(
			[Vector2(600.0, 400.0), Vector2(600.0, 400.0)])
	assert_array(SpawnPlacement.points(_spawn(GuardianSpawn.Placement.AROUND_IVO, 3, 80.0), _ctx)).is_equal(
			[Vector2(520.0, 400.0), Vector2(600.0, 400.0), Vector2(680.0, 400.0)])

## The landing spot is the motion's, not Ivo's: a leap clamped off a wall lands short of an Ivo against it.
func test_at_landing_marks_where_the_motion_comes_down_on_the_floor() -> void:
	var spawn := _spawn(GuardianSpawn.Placement.AT_LANDING, 1, 0.0)
	assert_array(SpawnPlacement.points(spawn, _ctx)).override_failure_message("no motion: the origin").is_equal(
			[Vector2(300.0, 400.0)])
	_ctx.landing = Vector2(904.0, 330.0)
	assert_array(SpawnPlacement.points(spawn, _ctx)).is_equal([Vector2(904.0, 400.0)])

func test_across_the_arena_sweeps_away_from_the_guardian() -> void:
	var points := SpawnPlacement.points(_spawn(GuardianSpawn.Placement.ACROSS_ARENA, 4, 0.0), _ctx)
	assert_float(points[0].x).is_less(points[3].x)
	_ctx.facing = -1
	points = SpawnPlacement.points(_spawn(GuardianSpawn.Placement.ACROSS_ARENA, 4, 0.0), _ctx)
	assert_float(points[0].x).is_greater(points[3].x)

func test_both_sides_pairs_the_facing_side_first() -> void:
	var spawn := _spawn(GuardianSpawn.Placement.BOTH_SIDES, 2, 40.0)
	spawn.offset = Vector2(24.0, 0.0)
	var points := SpawnPlacement.points(spawn, _ctx)
	assert_array(points).is_equal([Vector2(324.0, 400.0), Vector2(276.0, 400.0), Vector2(364.0, 400.0),
			Vector2(236.0, 400.0)])
	assert_int(SpawnPlacement.facing_at(points[1], _ctx)).is_equal(-1)

func test_every_point_stays_inside_the_arena() -> void:
	_ctx.target = Vector2(990.0, 400.0)
	for point: Vector2 in SpawnPlacement.points(_spawn(GuardianSpawn.Placement.AROUND_IVO, 3, 80.0), _ctx):
		assert_float(point.x).is_between(SpawnPlacement.EDGE_MARGIN, ARENA.end.x - SpawnPlacement.EDGE_MARGIN)

## Against a wall a spread slides whole, so its gaps keep the spacing.
func test_a_spread_around_ivo_slides_off_a_wall_whole() -> void:
	for x: float in [5.0, 995.0]:
		_ctx.target = Vector2(x, 400.0)
		var points := SpawnPlacement.points(_spawn(GuardianSpawn.Placement.AROUND_IVO, 3, 96.0), _ctx)
		assert_float(points[1].x - points[0].x).is_equal(96.0)
		assert_float(points[2].x - points[1].x).is_equal(96.0)

func _spawn(placement: GuardianSpawn.Placement, count: int, spacing: float) -> GuardianSpawn:
	var spawn := GuardianSpawn.new()
	spawn.placement = placement
	spawn.count = count
	spawn.spacing = spacing
	return spawn
