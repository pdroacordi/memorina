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

func _place_player(dx: float) -> void:
	_player.global_position = _body.global_position + Vector2(dx, 0.0)

func _tick_until_swinging() -> void:
	var elapsed := 0.0
	while not _ai.is_swinging() and elapsed < 2.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_swinging()).is_true()
