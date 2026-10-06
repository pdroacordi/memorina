class_name BruteShadowAITest extends GdUnitTestSuite

## The brute faces a target in reach although it stands still there
## (docs/knowledge/bugs/the-brute-swings-away-from-a-target-already-in-reach.md).

const STEP := 1.0 / 60.0
## Inside the 40 px default reach on either side.
const BEHIND := Vector2(-30, 0)
const IN_FRONT := Vector2(30, 0)
const FAR_BEHIND := Vector2(-300, 0)

var _body: Node2D
var _target: Node2D
var _ai: BruteShadowAI


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	var sight := EnemySight.new()
	sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	sight.add_child(ray)
	_body.add_child(sight)
	_ai = BruteShadowAI.new()
	_ai.stats = EnemyAIStats.new()
	_ai.attack_stats = BruteShadowAttackStats.new()
	_body.add_child(_ai)
	add_child(_body)
	_target = auto_free(Node2D.new()) as Node2D
	_target.add_to_group(EnemySight.PRESENCE)
	add_child(_target)
	sight._on_entered(_target)

## The Downtown case: the AI starts with the target already behind it and in reach.
func test_a_swing_at_a_target_already_in_reach_faces_it() -> void:
	_place_target(BEHIND)
	_ai.tick(STEP)
	assert_bool(_ai.is_attacking).is_true()
	assert_float(_ai.direction).is_equal(0.0)
	assert_float(_ai.facing_direction).is_equal(-1.0)

func test_a_swing_keeps_the_side_it_started_on() -> void:
	_place_target(BEHIND)
	_ai.tick(STEP)
	_place_target(IN_FRONT)
	_ai.tick(STEP)
	assert_bool(_ai.is_attacking).is_true()
	assert_float(_ai.facing_direction).is_equal(-1.0)

func test_waiting_out_the_cooldown_in_reach_turns_without_walking() -> void:
	_place_target(BEHIND)
	_swing_to_the_end()
	_place_target(IN_FRONT)
	_ai.tick(STEP)
	assert_bool(_ai.is_attacking).is_false()
	assert_float(_ai.direction).is_equal(0.0)
	assert_float(_ai.facing_direction).is_equal(1.0)

func test_out_of_reach_it_faces_where_it_walks() -> void:
	_place_target(FAR_BEHIND)
	_ai.tick(STEP)
	assert_bool(_ai.is_attacking).is_false()
	assert_float(_ai.direction).is_equal(-1.0)
	assert_float(_ai.facing_direction).is_equal(-1.0)

func _place_target(offset: Vector2) -> void:
	_target.global_position = _body.global_position + offset

func _swing_to_the_end() -> void:
	_ai.tick(STEP)
	var elapsed := 0.0
	while _ai.is_attacking and elapsed < 5.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_attacking).is_false()
