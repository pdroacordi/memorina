class_name GuardianAITest extends GdUnitTestSuite

## A swing keeps the side it started on, so a pounce or a charge carries past a player who
## rolls under it (docs/knowledge/systems/guardians.md, "Three moves each").

const STEP := 1.0 / 60.0
## Walk speed of the simulated body, in px/s.
const WALK_SPEED := 70.0

var _body: Node2D
var _player: Node2D
var _ai: GuardianAI
var _attack: GuardianAttack


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	var sight := EnemySight.new()
	sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	sight.add_child(ray)
	_body.add_child(sight)
	_ai = GuardianAI.new()
	_body.add_child(_ai)
	add_child(_body)
	_player = auto_free(Node2D.new()) as Node2D
	add_child(_player)
	sight.player = _player
	_attack = GuardianAttack.new()
	_attack.telegraph = 0.2
	_attack.duration = 0.6
	_attack.attack_range = 120.0
	_attack.lunge_speed = 320.0
	_ai.attacks = [_attack]
	_ai.comfort_distance = 0.0
	_ai.active = true

func test_a_telegraph_follows_the_player() -> void:
	_place_player(60.0)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_true()
	_place_player(-60.0)
	_ai.tick(STEP)
	assert_float(_ai.facing_intent()).is_equal(-1.0)

func test_a_swing_does_not_turn_when_the_player_crosses_under_it() -> void:
	_place_player(60.0)
	_ai.tick(STEP)
	_tick_until_swinging()
	_place_player(-60.0)
	_ai.tick(STEP)
	assert_bool(_ai.is_swinging()).is_true()
	assert_float(_ai.facing_intent()).is_equal(0.0)

func test_after_the_swing_it_faces_the_player_again() -> void:
	_place_player(60.0)
	_ai.tick(STEP)
	_tick_until_swinging()
	_place_player(-60.0)
	var elapsed := 0.0
	while _ai.is_swinging() and elapsed < 2.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_swinging()).is_false()
	assert_float(_ai.facing_intent()).is_equal(-1.0)

## Spacing gives ground only under give_ground_distance, not at the comfort distance's fraction
## (systems/guardians, "Comfort distances follow Ivo's reach").
func test_it_gives_ground_only_under_its_give_ground_distance() -> void:
	_attack.lunge_speed = 0.0
	_attack.attack_range = 72.0
	_attack.cooldown = 1.4
	_ai.comfort_distance = 114.0
	_ai.give_ground_distance = 70.0
	_place_player(71.0)
	_ai.tick(STEP)
	_tick_until_swinging()
	var elapsed := 0.0
	while _ai.is_attacking() and elapsed < 2.0:
		_ai.tick(STEP)
		elapsed += STEP
	_ai.tick(STEP)
	assert_int(_ai._spacing).override_failure_message("backed off at 71 px after its own swing").is_not_equal(GuardianAI.GIVE_GROUND)
	_place_player(65.0)
	_ai.tick(STEP)
	assert_int(_ai._spacing).is_equal(GuardianAI.GIVE_GROUND)
	assert_float(_ai.direction).is_less(0.0)

## "O pogo é a brecha" (user, 2026-10-29): a pogo on the golem's head is a way out of its moves, but it steps out
## from under him and goes back to them (bugs/a-pogo-on-the-frost-golems-head-stops-it-attacking).
func test_a_pogo_on_its_head_does_not_stop_its_moves() -> void:
	var stats := load("res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres") as GuardianStats
	_ai.attacks = stats.attacks
	_ai.comfort_distance = stats.comfort_distance
	_ai.give_ground_distance = stats.give_ground_distance
	_ai.pace_speed = stats.pace_speed
	_ai.step_out_speed = stats.step_out_speed
	# Golem capsule r34 beside Ivo's r11.
	_ai.overhead_band = GuardianAI.overhead_band_for(68.0, 22.0)
	var telegraphed: Array[float] = []
	_ai.attack_telegraphed.connect(func(_attack: GuardianAttack) -> void:
		telegraphed.append(_player.global_position.x - _body.global_position.x))
	var player_x := _body.global_position.x + 2.0
	var elapsed := 0.0
	while elapsed < 4.0 and telegraphed.is_empty():
		# Feet 180..260 px above the golem's, bouncing on a 0.5 s period.
		var above := 180.0 + 80.0 * absf(sin(elapsed * PI / 0.5))
		_player.global_position = Vector2(player_x, _body.global_position.y - above)
		_ai.tick(STEP)
		_body.position.x += _ai.direction * WALK_SPEED * STEP
		elapsed += STEP
	assert_array(telegraphed).override_failure_message("no move in 4 s under a pogo").is_not_empty()
	assert_float(absf(telegraphed[0])).override_failure_message("thrown from under him").is_greater(_ai.overhead_band)

## The band is the guardian's body and Ivo's side by side, so a jump attack from beside a slim guardian is not an
## escape (GRD-07 review: the old 64 px band was sized for the wide Bloom).
func test_only_a_player_over_its_body_is_on_top_of_it() -> void:
	_attack.attack_height = 60.0
	_attack.attack_range = 20.0
	_attack.lunge_speed = 0.0
	_ai.overhead_band = GuardianAI.overhead_band_for(32.0, 22.0)
	assert_float(_ai.overhead_band).is_equal(27.0)
	_player.global_position = _body.global_position + Vector2(40.0, -80.0)
	_ai.tick(STEP)
	_ai.tick(STEP)
	assert_bool(_ai.is_escaping()).override_failure_message("escaped a jump attack 40 px beside it").is_false()
	_player.global_position = _body.global_position + Vector2(10.0, -80.0)
	_ai.tick(STEP)
	assert_bool(_ai.is_escaping()).is_true()

## A far player draws any move that reaches him, by weight, not always the longest; one that does not reach is never
## picked, and the choice is kept until thrown (systems/guardians, "The Bloom Guardian's fight").
func test_a_far_player_draws_every_reaching_move_by_weight() -> void:
	var long := _far_move(300.0, 1.0)
	var longer := _far_move(320.0, 1.0)
	var short := _far_move(150.0, 5.0)
	_ai.attacks = [short, long, longer]
	_ai.comfort_distance = 82.0
	# Level, a hair above as move_and_slide leaves feet, and a jump's height under every move's reach up.
	for above: float in [0.0, 0.1, 40.0]:
		_player.global_position = _body.global_position + Vector2(250.0, -above)
		var thrown: Dictionary[GuardianAttack, bool] = {}
		for i: int in 40:
			seed(i)
			_ai.cancel_attack()
			_ai.set(&"_next", null)
			_ai.set(&"_far_pick", null)
			_ai.tick(STEP)
			assert_bool(_ai.is_telegraphing()).is_true()
			thrown[_ai.current_attack] = true
		assert_bool(thrown.has(long)).override_failure_message("%.1f px up: the shorter reaching move was never thrown" % above).is_true()
		assert_bool(thrown.has(longer)).override_failure_message("%.1f px up" % above).is_true()
		assert_bool(thrown.has(short)).override_failure_message("%.1f px up: threw a move that does not reach" % above).is_false()

func test_a_far_choice_is_kept_until_it_is_thrown() -> void:
	_ai.attacks = [_far_move(300.0, 1.0), _far_move(320.0, 1.0)]
	_ai.comfort_distance = 82.0
	(_ai.get(&"_clock") as GuardianMoveClock).call(&"_cool", 5.0)
	_place_player(250.0)
	seed(7)
	_ai.tick(STEP)
	var first: GuardianAttack = _ai.get(&"_next")
	for i: int in 60:
		_ai.tick(STEP)
		assert_object(_ai.get(&"_next")).override_failure_message("re-rolled at frame %d" % i).is_same(first)

## A player a hair above the lion's feet no longer hands the pick to the taller claw: the roar it chose is kept while it
## closes in and thrown in its range (bugs/the-sun-guardians-roar-never-fires).
func test_the_sun_roar_is_kept_for_a_player_a_hair_above() -> void:
	var stats := load("res://resources/characters/guardians/summer_guardian/summer_guardian_stats.tres") as GuardianStats
	var roar := load("res://resources/characters/guardians/summer_guardian/summer_roar.tres") as GuardianAttack
	_ai.attacks = stats.attacks
	_ai.comfort_distance = stats.comfort_distance
	_ai.set(&"_next", roar)
	_player.global_position = _body.global_position + Vector2(100.0, -0.1)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).override_failure_message("threw the claw over the roar").is_false()
	assert_object(_ai.get(&"_next")).is_same(roar)
	_player.global_position = _body.global_position + Vector2(80.0, -0.1)
	_ai.tick(STEP)
	assert_object(_ai.current_attack).is_same(roar)

## A player above every move's reach but the tallest's still draws the move that reaches him there.
func test_a_player_above_the_lower_moves_draws_the_tall_one() -> void:
	var low := _far_move(120.0, 5.0)
	var tall := _far_move(120.0, 0.1)
	tall.attack_height = 150.0
	_ai.attacks = [low, tall]
	_player.global_position = _body.global_position + Vector2(60.0, -120.0)
	_ai.tick(STEP)
	assert_object(_ai.current_attack).is_same(tall)

## Equally tall moves over a jumping player are drawn by weight, not taken in array order: in order, with
## `recent_strings` 2, the mentor cycled three of them three times running (the GRD-17 fix round).
func test_equally_tall_overhead_moves_are_drawn_by_weight() -> void:
	var low := _far_move(120.0, 5.0)
	var first := _far_move(120.0, 1.0)
	var second := _far_move(120.0, 1.0)
	first.attack_height = 150.0
	second.attack_height = 150.0
	_ai.attacks = [low, first, second]
	_player.global_position = _body.global_position + Vector2(60.0, -120.0)
	var picked := {}
	for i: int in 40:
		_ai.set(&"_next", null)
		_ai.call(&"_pick_next")
		picked[_ai.get(&"_next")] = true
	assert_bool(picked.has(first) and picked.has(second)).is_true()
	assert_bool(picked.has(low)).is_false()

## Until its skill is owned the recall move keeps its cadence and its call; once owned, a move with owned numbers is
## an ordinary move by its owned weight, and one without keeps today's cadence.
func test_an_owned_recall_move_leaves_the_cadence_only_with_owned_numbers() -> void:
	var hit := _far_move(120.0, 1.0)
	var recall := _far_move(120.0, 0.0)
	recall.recall = AbilityRecallStats.new()
	recall.owned_weight = 1.0
	_ai.attacks = [hit, recall]
	_ai.recall_after_attacks = 1
	_ai.set(&"_since_recall", 3)
	_ai.call(&"_pick_next")
	assert_object(_ai.get(&"_next")).override_failure_message("the cadence broke while the skill is missing").is_same(recall)
	_ai.recall_owned = true
	var picked := {}
	for i: int in 30:
		seed(i)
		_ai.set(&"_since_recall", 3)
		_ai.call(&"_pick_next")
		picked[_ai.get(&"_next")] = true
	assert_bool(picked.has(hit)).override_failure_message("the owned burst still forced its slot").is_true()
	assert_bool(picked.has(recall)).override_failure_message("the owned burst never came by weight").is_true()
	_ai.request_recall()
	assert_bool(_ai.get(&"_recall_requested")).is_false()
	recall.owned_weight = -1.0
	_ai.call(&"_pick_next")
	assert_object(_ai.get(&"_next")).override_failure_message("a recall move without owned numbers left the cadence").is_same(recall)

## The Frost charge turns after passing Ivo and charges back, wall or not, only once the roll is owned, from stage 1
## ("Turn after passing Ivo (Recommended)", user, 2026-11-18; GRD-14).
func test_the_owned_frost_charge_charges_back_wall_or_not() -> void:
	for owned: bool in [false, true]:
		assert_bool(_charge_backs(owned, false)).override_failure_message("owned %s" % owned).is_equal(owned)

## Ownership is read as the strike begins: the press that teaches the roll mid-strike does not let that strike chain
## (bugs/a-recall-move-with-follow-ups-never-resets-the-recall-cadence, Revision).
func test_a_teaching_charge_never_chains_off_the_press_that_taught_it() -> void:
	assert_bool(_charge_backs(false, true)).override_failure_message("chained off its own press").is_false()

## Frost's moves reach 96 px up but the body drop (200): an Ivo jumping 130 px up beside the golem draws it from
## stage 2; at stage 1 nothing reaches him there ("Jump clears the raised fists (Recommended)", user, 2026-11-18).
func test_a_frost_golem_answers_a_player_above_with_the_body_drop() -> void:
	var stats := load("res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres") as GuardianStats
	_ai.attacks = stats.attacks
	_ai.comfort_distance = stats.comfort_distance
	_place_player(150.0)
	_player.global_position.y -= 130.0
	_ai.stage = 2
	_ai.call(&"_pick_next")
	assert_object(_ai.get(&"_next")).is_same(stats.attacks[4])
	_ai.stage = 1
	assert_object(_ai.call(&"_situational_pick")).override_failure_message("a stage-1 move reaches 130 px up").is_null()

## At stage 0 nothing reaches above 96 px, so an Ivo who keeps jumping beside the golem is answered once the
## patience runs out, where he comes down.
func test_a_jumping_player_beside_a_stage_zero_frost_still_draws_a_move() -> void:
	var stats := load("res://resources/characters/guardians/frost_guardian/frost_guardian_stats.tres") as GuardianStats
	_ai.attacks = stats.attacks
	_ai.comfort_distance = stats.comfort_distance
	_ai.give_ground_distance = stats.give_ground_distance
	_ai.pace_speed = stats.pace_speed
	_ai.overhead_band = GuardianAI.overhead_band_for(68.0, 22.0)
	var telegraphed: Array[float] = []
	_ai.attack_telegraphed.connect(func(_attack: GuardianAttack) -> void: telegraphed.append(_ai.swing_elapsed()))
	var elapsed := 0.0
	while elapsed < 6.0 and telegraphed.is_empty():
		# A single jump every 0.9 s, 80 px beside the golem, peaking at 144 px.
		var hop := fmod(elapsed, 0.9)
		_player.global_position = _body.global_position + Vector2(80.0, -144.0 * sin(PI * minf(hop / 0.8, 1.0)))
		_ai.tick(STEP)
		_body.position.x += _ai.direction * WALK_SPEED * STEP
		elapsed += STEP
	assert_array(telegraphed).override_failure_message("no move in 6 s against a jumping Ivo").is_not_empty()

## A move that does not repeat is never the pick right after a string it ended, near or far.
func test_a_move_that_does_not_repeat_never_follows_itself() -> void:
	var dash := _far_move(260.0, 1.0)
	dash.repeats = false
	var lash := _far_move(100.0, 1.0)
	_ai.attacks = [dash, lash]
	_ai.comfort_distance = 82.0
	_ai.set(&"_last_end", dash)
	for i: int in 30:
		seed(i)
		assert_object(_ai.call(&"_weighted_pick")).is_same(lash)
	_player.global_position = _body.global_position + Vector2(200.0, 0.0)
	assert_object(_ai.call(&"_far_opinion", 200.0)).override_failure_message("dashed after a dash").is_null()
	_ai.set(&"_last_end", lash)
	assert_object(_ai.call(&"_far_opinion", 200.0)).is_same(dash)

## With `recent_strings`, the first moves of the last strings are skipped by every pick while another pickable move is
## left; with 0 nothing changes (playtests/2026-11-18-grd15-leaf-feel: a blades, hop loop for all of stage 0).
func test_a_pick_avoids_the_recent_strings_first_moves() -> void:
	var blades := _far_move(240.0, 1.0)
	var hop := _far_move(250.0, 1.0)
	var sweep := _far_move(100.0, 1.0)
	_ai.attacks = [blades, hop, sweep]
	_ai.comfort_distance = 82.0
	_ai.recent_strings = 2
	_ai.set(&"_recent_roots", [blades, hop] as Array[GuardianAttack])
	for i: int in 20:
		seed(i)
		assert_object(_ai.call(&"_weighted_pick")).is_same(sweep)
	# Far away only the recent moves reach: the far pick has nothing, and the guardian walks in for the sweep.
	_place_player(200.0)
	assert_object(_ai.call(&"_far_opinion", 200.0)).is_null()
	# Nothing pickable left: every move is back in the pool.
	_ai.set(&"_recent_roots", [blades, hop, sweep] as Array[GuardianAttack])
	assert_int((_ai.call(&"_choosable") as Array).size()).is_equal(3)
	_ai.recent_strings = 0
	_ai.set(&"_recent_roots", [] as Array[GuardianAttack])
	assert_int((_ai.call(&"_choosable") as Array).size()).is_equal(3)

## With `far_walks_in` a far Ivo can draw a close move by weight, kept while he stays far; without it only a reaching
## move is drawn (playtests/2026-11-18-grd15-leaf-feel: 0 sweeps in 64 stage-0 strings against a dodger).
func test_a_far_pick_may_walk_in_for_a_close_move() -> void:
	var far := _far_move(240.0, 1.0)
	var sweep := _far_move(100.0, 3.0)
	_ai.attacks = [far, sweep]
	_ai.comfort_distance = 82.0
	_place_player(200.0)
	assert_object(_ai.call(&"_far_opinion", 200.0)).is_same(far)
	_ai.far_walks_in = true
	var drawn := {}
	for i: int in 40:
		seed(i)
		_ai.set(&"_far_pick", null)
		drawn[_ai.call(&"_far_opinion", 200.0)] = true
	assert_bool(drawn.has(sweep)).is_true()
	assert_bool(drawn.has(far)).is_true()
	_ai.set(&"_far_pick", sweep)
	for i: int in 10:
		assert_object(_ai.call(&"_far_opinion", 200.0)).override_failure_message("re-rolled a kept choice").is_same(sweep)

## A finished string's first move is remembered, the oldest dropped past `recent_strings`; with 0 none is.
func test_finished_strings_feed_the_recent_moves() -> void:
	var a := _far_move(120.0, 1.0)
	var b := _far_move(120.0, 1.0)
	var c := _far_move(120.0, 1.0)
	_ai.recent_strings = 2
	for move: GuardianAttack in [a, b, c]:
		_ai.set(&"_root", move)
		_ai.call(&"_remember_root")
	assert_array(_ai.get(&"_recent_roots") as Array).is_equal([b, c])
	_ai.recent_strings = 0
	_ai.set(&"_recent_roots", [] as Array[GuardianAttack])
	_ai.call(&"_remember_root")
	assert_array(_ai.get(&"_recent_roots") as Array).is_empty()

## A link that turns from a wall, taken against one, winds up facing away from it even with Ivo on the wall's side; a
## link that does not turn faces Ivo there (the Sun charge's bounce, GRD-16).
func test_a_bounce_taken_against_a_wall_winds_up_facing_away_from_it() -> void:
	for turns: bool in [true, false]:
		var bounce := _far_move(300.0, 0.0)
		bounce.turns_from_wall = turns
		var link := GuardianFollowUp.new()
		link.attack = bounce
		link.needs_wall = true
		_attack.follow_ups = [link]
		_ai.cancel_attack()
		_ai.provoke()
		_place_player(60.0)
		_ai.tick(STEP)
		_tick_until_swinging()
		_ai.blocked_ahead = true
		var elapsed := 0.0
		while _ai.current_attack != bounce and elapsed < 2.0:
			_ai.tick(STEP)
			elapsed += STEP
		assert_bool(_ai.is_telegraphing()).is_true()
		assert_bool(_ai.turns_from_wall()).is_equal(turns)
		_ai.tick(STEP)
		assert_float(_ai.facing_intent()).override_failure_message("turns %s" % turns).is_equal(0.0 if turns else 1.0)
		_ai.blocked_ahead = false

## While the guardian's own floor patches burn, a move that waits for the floor is not chosen, nor thrown if it was
## chosen before they lit; once they are out it is (bugs/a-pounce-slam-thrown-after-an-ember-spit-cannot-be-walked-out-of).
func test_a_move_that_waits_for_the_floor_is_held_while_it_burns() -> void:
	var waits := _far_move(120.0, 5.0)
	waits.waits_for_floor = true
	var other := _far_move(120.0, 0.5)
	_ai.attacks = [waits, other]
	_place_player(60.0)
	_ai.floor_burning = true
	for i: int in 30:
		seed(i)
		_ai.cancel_attack()
		_ai.set(&"_next", waits)
		_ai.tick(STEP)
		assert_object(_ai.current_attack).override_failure_message("thrown into a burning floor").is_same(other)
	_ai.floor_burning = false
	var thrown := {}
	for i: int in 30:
		seed(i)
		_ai.cancel_attack()
		_ai.set(&"_next", null)
		_ai.tick(STEP)
		thrown[_ai.current_attack] = true
	assert_bool(thrown.has(waits)).override_failure_message("never thrown once the floor is out").is_true()

func test_with_only_floor_moves_it_keeps_its_choice_and_waits_for_the_floor() -> void:
	var first := _far_move(120.0, 1.0)
	first.waits_for_floor = true
	var second := _far_move(120.0, 1.0)
	second.waits_for_floor = true
	_ai.attacks = [first, second]
	_place_player(60.0)
	_ai.floor_burning = true
	_ai.cancel_attack()
	_ai.set(&"_next", first)
	for i: int in 30:
		seed(i)
		_ai.tick(STEP)
		assert_object(_ai.current_attack).override_failure_message("thrown into a burning floor").is_null()
		assert_object(_ai.get(&"_next")).override_failure_message("re-rolled while it waits").is_same(first)
	_ai.floor_burning = false
	_ai.tick(STEP)
	assert_object(_ai.current_attack).override_failure_message("not thrown once the floor is out").is_same(first)

func _far_move(reach: float, weight: float) -> GuardianAttack:
	var move := GuardianAttack.new()
	move.telegraph = 0.2
	move.duration = 0.6
	move.attack_range = reach
	move.weight = weight
	return move

func _place_player(dx: float) -> void:
	_player.global_position = _body.global_position + Vector2(dx, 0.0)

func _tick_until_swinging() -> void:
	var elapsed := 0.0
	while not _ai.is_swinging() and elapsed < 2.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_swinging()).is_true()

## Throws the Frost charge at an Ivo 150 px away at stage 1, away from any wall, and says whether its charge-back
## followed; `owned_mid_strike` hands the roll over halfway through the strike.
func _charge_backs(owned: bool, owned_mid_strike: bool) -> bool:
	var charge := load("res://resources/characters/guardians/frost_guardian/frost_charge.tres") as GuardianAttack
	var back := load("res://resources/characters/guardians/frost_guardian/frost_charge_back.tres") as GuardianAttack
	_ai.cancel_attack()
	_ai.provoke()
	_ai.attacks = [charge]
	_ai.stage = 1
	_ai.blocked_ahead = false
	_ai.recall_owned = owned
	var next := {}
	_ai.attack_telegraphed.connect(func(attack: GuardianAttack) -> void: next[attack] = true)
	_place_player(-150.0)
	_ai.call(&"_start_telegraph", charge)
	var elapsed := 0.0
	while _ai.is_attacking() and not next.has(back) and elapsed < 3.0:
		if owned_mid_strike and _ai.is_swinging() and _ai.swing_elapsed() > charge.duration * 0.5:
			_ai.recall_owned = true
		_ai.tick(STEP)
		elapsed += STEP
	return next.has(back)
