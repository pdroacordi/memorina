class_name GuardianAITest extends GdUnitTestSuite

## A swing keeps the side it started on, so a pounce or a charge carries past a player who
## rolls under it (docs/knowledge/systems/guardians.md, "Three moves each").

const STEP := 1.0 / 60.0

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

func _place_player(dx: float) -> void:
	_player.global_position = _body.global_position + Vector2(dx, 0.0)

func _tick_until_swinging() -> void:
	var elapsed := 0.0
	while not _ai.is_swinging() and elapsed < 2.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_swinging()).is_true()
