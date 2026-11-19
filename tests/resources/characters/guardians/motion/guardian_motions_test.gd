class_name GuardianMotionsTest extends GdUnitTestSuite

## Every motion lands inside the arena's margins and finishes inside the strike (architecture/grd-12-guardian-fight-engine).

## A 1000 px arena, 400 px tall, floor at y 400.
const ARENA := Rect2(0.0, 0.0, 1000.0, 400.0)
const MARGIN := 96.0


func test_a_step_backs_off_and_stops_at_the_margin() -> void:
	var step := StepMotion.new()
	step.distance = -200.0
	var path := step.plan(_ctx(Vector2(150.0, 400.0), 1, Vector2(300.0, 400.0)))
	assert_float(path.end_offset().x).is_equal(MARGIN - 150.0)
	assert_float(path.end_time()).is_less_equal(path.duration)

func test_a_step_from_inside_the_margin_never_runs_the_wrong_way() -> void:
	var step := StepMotion.new()
	step.distance = 32.0
	# Feet 50 px from the wall ahead, inside the 96 px margin: the step stops short, it does not turn back.
	var ahead := step.plan(_ctx(Vector2(950.0, 400.0), 1, Vector2(700.0, 400.0)))
	assert_float(ahead.end_offset().x).is_equal(0.0)
	var dash := DashMotion.new()
	dash.speed = 800.0
	dash.delay = 0.35
	dash.backstep = 48.0
	var ctx := _ctx(Vector2(30.0, 400.0), 1, Vector2(300.0, 400.0))
	ctx.duration = 0.9
	assert_float(dash.plan(ctx).at(0.35).x).override_failure_message("the backstep ran toward Ivo").is_less_equal(0.0)

func test_a_hop_rises_under_the_arena_top() -> void:
	var step := StepMotion.new()
	step.height = 900.0
	var ctx := _ctx(Vector2(500.0, 400.0), 1, Vector2(600.0, 400.0))
	ctx.body_height = 120.0
	var path := step.plan(ctx)
	var apex := 0.0
	for i: int in 61:
		apex = minf(apex, path.at(i / 60.0).y)
	assert_float(ctx.feet.y + apex - ctx.body_height).is_greater_equal(ARENA.position.y - 0.01)

func test_a_dash_stops_at_the_edge_and_speeds_up_to_finish_in_time() -> void:
	var dash := DashMotion.new()
	dash.speed = 100.0
	dash.margin = 48.0
	var path := dash.plan(_ctx(Vector2(200.0, 400.0), 1, Vector2(300.0, 400.0)))
	assert_float(200.0 + path.end_offset().x).is_equal(ARENA.end.x - 48.0)
	assert_float(path.end_time()).is_less_equal(path.duration + 0.0001)
	assert_bool(dash.aimed()).is_true()

## A negative `past` stops short of Ivo, and stays put when he is already closer (the Frost second swipe's step-in).
func test_a_dash_with_a_negative_past_stops_short_of_ivo() -> void:
	var dash := DashMotion.new()
	dash.speed = 400.0
	dash.past = -76.0
	assert_float(dash.plan(_ctx(Vector2(200.0, 400.0), 1, Vector2(350.0, 400.0))).end_offset().x).is_equal(74.0)
	assert_float(dash.plan(_ctx(Vector2(200.0, 400.0), 1, Vector2(250.0, 400.0))).end_offset().x).is_equal(0.0)
	assert_float(dash.plan(_ctx(Vector2(600.0, 400.0), -1, Vector2(450.0, 400.0))).end_offset().x).is_equal(-74.0)

func test_a_dash_with_a_backstep_steps_back_first_then_runs_to_the_far_edge() -> void:
	var dash := DashMotion.new()
	dash.speed = 800.0
	dash.delay = 0.35
	dash.backstep = 48.0
	dash.backstep_time = 0.2
	var ctx := _ctx(Vector2(500.0, 400.0), 1, Vector2(600.0, 400.0))
	ctx.duration = 1.2
	var path := dash.plan(ctx)
	assert_float(path.at(0.2).x).is_equal(-48.0)
	assert_float(path.at(0.35).x).override_failure_message("it held the backstep until the dash").is_equal(-48.0)
	assert_float(500.0 + path.end_offset().x).is_equal(ARENA.end.x - 48.0)
	assert_float(path.end_time()).is_less_equal(path.duration + 0.0001)
	# Against its back wall the step is cut to the margin.
	var cornered := dash.plan(_ctx(Vector2(110.0, 400.0), 1, Vector2(300.0, 400.0)))
	assert_float(110.0 + cornered.at(0.35).x).is_equal(MARGIN)

func test_a_leap_lands_on_its_target_inside_the_margins_under_the_top() -> void:
	var leap := LeapMotion.new()
	leap.height = 1000.0
	var ctx := _ctx(Vector2(500.0, 400.0), 1, Vector2(980.0, 400.0))
	ctx.body_height = 120.0
	for target: LeapMotion.Target in [LeapMotion.Target.IVO_SPOT, LeapMotion.Target.PAST_IVO, LeapMotion.Target.FAR_SIDE]:
		leap.target = target
		var path := leap.plan(ctx)
		var landing := ctx.feet.x + path.end_offset().x
		assert_float(landing).is_between(ARENA.position.x + MARGIN, ARENA.end.x - MARGIN)
		assert_float(path.end_time()).is_less_equal(path.duration)
		assert_float(path.at(path.end_time() * 0.5).y + ctx.feet.y - ctx.body_height).is_greater_equal(-0.01)
	leap.target = LeapMotion.Target.FAR_SIDE
	assert_float(ctx.feet.x + leap.plan(ctx).end_offset().x).override_failure_message("the far side from Ivo").is_equal(MARGIN)

func test_a_dive_rises_hangs_and_lands_on_ivos_spot_inside_the_strike() -> void:
	var dive := DiveMotion.new()
	dive.rise_time = 0.6
	dive.hang = 0.6
	dive.dive_time = 0.6
	var ctx := _ctx(Vector2(500.0, 400.0), 1, Vector2(700.0, 400.0))
	ctx.duration = 1.2
	var path := dive.plan(ctx)
	assert_float(path.end_time()).is_less_equal(1.2 + 0.0001)
	assert_vector(path.end_offset()).is_equal(Vector2(200.0, 0.0))
	assert_bool(path.holds_vertical(0.6)).is_true()
	assert_float(path.at(0.5).y).override_failure_message("the hang is not up").is_less(-100.0)
	assert_float(path.at(0.6).x).override_failure_message("rose straight up").is_equal(0.0)

## An approaching dive rises straight up, drifts part of the way across while it hangs, so it comes down steeper, and
## still lands on Ivo's spot: its body never sweeps low toward him on the way up.
func test_an_approaching_dive_hangs_part_of_the_way_to_ivo() -> void:
	var dive := DiveMotion.new()
	dive.rise_time = 0.4
	dive.hang = 0.4
	dive.dive_time = 0.4
	dive.approach = 0.5
	var ctx := _ctx(Vector2(500.0, 400.0), 1, Vector2(700.0, 400.0))
	ctx.duration = 1.2
	var path := dive.plan(ctx)
	assert_float(path.at(0.4).x).is_equal_approx(0.0, 0.01)
	assert_float(path.at(0.8).x).is_equal_approx(100.0, 0.01)
	assert_float(path.at(0.8).y).is_equal_approx(path.at(0.4).y, 0.01)
	assert_vector(path.end_offset()).is_equal(Vector2(200.0, 0.0))

## A dive lands on the floor it left even when Ivo is in the air as it starts, after a jump or a double jump.
func test_a_dive_at_an_airborne_ivo_lands_on_the_floor() -> void:
	var dive := DiveMotion.new()
	dive.approach = 0.8
	for up: float in [140.0, 260.0]:
		var ctx := _ctx(Vector2(500.0, 400.0), 1, Vector2(700.0, 400.0 - up))
		ctx.duration = 1.2
		var path := dive.plan(ctx)
		assert_vector(path.end_offset()).override_failure_message("Ivo %.0f px up" % up).is_equal(Vector2(200.0, 0.0))

func test_a_blink_takes_the_other_side_when_the_wall_is_close() -> void:
	var blink := BlinkMotion.new()
	blink.behind = 64.0
	blink.min_gap = 32.0
	var open := blink.plan(_ctx(Vector2(300.0, 400.0), 1, Vector2(500.0, 400.0)))
	assert_float(300.0 + open.blink_to.x).is_equal(564.0)
	var cornered := blink.plan(_ctx(Vector2(500.0, 400.0), 1, Vector2(890.0, 400.0)))
	assert_float(500.0 + cornered.blink_to.x).override_failure_message("reappeared against the wall").is_equal(826.0)

func _ctx(feet: Vector2, facing: int, target: Vector2) -> MotionContext:
	var ctx := MotionContext.new()
	ctx.feet = feet
	ctx.facing = facing
	ctx.target = target
	ctx.arena = ARENA
	ctx.margin = MARGIN
	ctx.duration = 0.6
	return ctx
