class_name BloomGuardianKitTest extends GdUnitTestSuite

## The Bloom Guardian's GRD-13 kit as data: its strings, what joins at stage 1, and the stage table
## (systems/guardians, "The Bloom Guardian's fight (GRD-13)").

const STATS := preload("res://resources/characters/guardians/bloom_guardian/bloom_guardian_stats.tres")
const LASH := preload("res://resources/characters/guardians/bloom_guardian/bloom_lash.tres")
const BACK_LASH := preload("res://resources/characters/guardians/bloom_guardian/bloom_back_lash.tres")
const THRUST := preload("res://resources/characters/guardians/bloom_guardian/bloom_antler_thrust.tres")
const POUNCE := preload("res://resources/characters/guardians/bloom_guardian/bloom_pounce.tres")
const POUNCE_AGAIN := preload("res://resources/characters/guardians/bloom_guardian/bloom_pounce_again.tres")
const BURST := preload("res://resources/characters/guardians/bloom_guardian/bloom_burst.tres")
const DASH := preload("res://resources/characters/guardians/bloom_guardian/bloom_antler_dash.tres")
## Px from Ivo to the view's edge: the camera centres him in a 640 px view.
const VIEW_HALF := 320.0
## Px of the stag's drawn half width (22 art px at scale 2).
const BODY_HALF := 22.0
## A 1200 px arena, floor at y 400.
const ARENA := Rect2(0.0, 0.0, 1200.0, 400.0)


func test_the_lash_strings_into_the_back_lash_and_the_antler_thrust() -> void:
	assert_object(_link(LASH, 0, 1)).is_same(BACK_LASH)
	assert_object(_link(BACK_LASH, 0, 2)).is_same(THRUST)
	assert_object(_link(THRUST, 0, 3)).override_failure_message("the thrust ends the string").is_null()
	# A player who backed off out of the next link's range breaks the string.
	assert_object(GuardianRepertoire.next_link(BACK_LASH, 0, 1.0, 2, 3, func(_a: GuardianAttack) -> bool: return false,
			false, false, func() -> float: return 0.0)).is_null()

func test_stage_one_makes_the_lash_string_certain() -> void:
	var tuning := STATS.stages[1]
	var never := func() -> float: return 0.99
	assert_object(GuardianRepertoire.next_link(LASH, 1, tuning.chain_scale, 1, tuning.max_links, _always, false, false,
			never)).is_same(BACK_LASH)

func test_it_pounces_twice_only_from_stage_one() -> void:
	assert_object(_link(POUNCE, 0, 1)).is_null()
	assert_object(_link(POUNCE, 1, 1)).is_same(POUNCE_AGAIN)
	assert_object(_link(POUNCE_AGAIN, 1, 2)).override_failure_message("a third pounce").is_null()

func test_the_new_moves_join_at_their_stage_and_the_burst_still_carries_the_recall() -> void:
	var at_start := GuardianRepertoire.available(STATS.attacks, 0)
	var later := GuardianRepertoire.available(STATS.attacks, 1)
	assert_int(at_start.size()).is_equal(4)
	assert_int(later.size()).is_equal(6)
	assert_bool(at_start.has(BURST)).is_true()
	assert_object(BURST.recall).is_not_null()
	assert_array(BURST.follow_ups).is_empty()

func test_stage_one_is_harder() -> void:
	assert_int(STATS.stages.size()).is_equal(STATS.cycles_to_restore)
	var first := STATS.stages[0]
	var second := STATS.stages[1]
	assert_float(second.cooldown_scale).is_less(first.cooldown_scale)
	assert_float(second.chain_scale).is_greater(first.chain_scale)

func test_every_move_has_a_wind_up_and_a_short_cooldown() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		var label := attack.resource_path.get_file()
		assert_int(attack.windup_index).override_failure_message("%s has no wind-up" % label).is_greater_equal(0)
		assert_float(attack.recovery).override_failure_message("%s has no recovery" % label).is_greater(0.0)
		assert_float(attack.cooldown).override_failure_message(label).is_between(0.3, 0.9)

## Every move is thrown from where its wind-up is on screen with Ivo centred
## (bugs/the-bloom-antler-dash-strands-it-beyond-every-other-move-and-it-dashes-back-from-off-screen).
func test_every_move_is_thrown_from_on_screen() -> void:
	for attack: GuardianAttack in GuardianMoveGraph.moves(STATS):
		assert_float(attack.attack_range + BODY_HALF).override_failure_message(attack.resource_path.get_file()).is_less_equal(VIEW_HALF)

## The dash stops its `past` beyond Ivo (short of him against a wall), at its own speed, and never follows itself.
func test_the_dash_ends_past_ivo_at_its_own_speed() -> void:
	var dash := DASH.motion as DashMotion
	assert_bool(DASH.repeats).is_false()
	var distance := 40.0
	while distance <= DASH.attack_range:
		var ctx := _ctx(Vector2(400.0, 400.0), Vector2(400.0 + distance, 400.0))
		var end := ctx.feet.x + dash.plan(ctx).end_offset().x
		assert_float(end).override_failure_message("from %.0f" % distance).is_equal_approx(ctx.target.x + dash.past, 0.01)
		assert_float(dash.planned_speed(ctx)).override_failure_message("sped up from %.0f" % distance).is_less_equal(dash.speed + 0.01)
		distance += 8.0
	# With no room past a cornered Ivo before the wall's margin it stops short of him, not on him.
	var cornered := _ctx(Vector2(900.0, 400.0), Vector2(1120.0, 400.0))
	assert_float(cornered.feet.x + dash.plan(cornered).end_offset().x).is_equal(1120.0 - dash.past)
	# It ends inside Ivo's longest swing on the stag (77.5 px; systems/guardians), so its recovery can be punished.
	assert_float(dash.past).is_less(77.5)

## Once the double jump is owned the burst is an ordinary move that hurts; before, the recall as it was.
func test_the_owned_burst_is_an_ordinary_move() -> void:
	assert_float(BURST.weight_for(false)).is_equal(0.0)
	assert_int(BURST.damage_for(false)).is_equal(0)
	assert_bool(BURST.leaves_cadence_when_owned()).is_true()
	assert_float(BURST.weight_for(true)).is_equal(0.5)
	assert_int(BURST.damage_for(true)).is_equal(1)

func _ctx(feet: Vector2, target: Vector2) -> MotionContext:
	var ctx := MotionContext.new()
	ctx.feet = feet
	ctx.facing = 1
	ctx.target = target
	ctx.arena = ARENA
	ctx.margin = 96.0
	ctx.duration = DASH.duration
	return ctx

func _link(move: GuardianAttack, stage: int, links_done: int) -> GuardianAttack:
	return GuardianRepertoire.next_link(move, stage, 1.0, links_done, GuardianStage.DEFAULT_MAX_LINKS, _always, false,
			false, func() -> float: return 0.0)

func _always(_attack: GuardianAttack) -> bool:
	return true
