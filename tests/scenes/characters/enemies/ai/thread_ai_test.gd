class_name ThreadAITest extends GdUnitTestSuite

## The spider's style: it lets itself down to a target's chest while the target is in its column, no farther than
## max_drop, and climbs back after `linger` without one.

const STEP := 1.0 / 60.0
## In the column, out of the bite's reach.
const BESIDE := 50.0

var _body: Node2D
var _target: Node2D
var _sight: EnemySight
var _ai: ThreadAI


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	_sight = EnemySight.new()
	_sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	_sight.add_child(ray)
	_body.add_child(_sight)
	_ai = ThreadAI.new()
	_ai.stats = _stats()
	_body.add_child(_ai)
	add_child(_body)
	_target = auto_free(Node2D.new()) as Node2D
	_target.add_to_group(EnemySight.PRESENCE)
	add_child(_target)
	_sight._on_entered(_target)

func _stats() -> EnemyStats:
	var stats := EnemyStats.new()
	stats.locomotion = LocomotionStats.new()
	stats.stop_distance = 0.0
	var move := EnemyMove.new()
	move.telegraph = 0.35
	move.active = 0.2
	move.recovery = 0.5
	move.cooldown = 0.9
	move.reach = Rect2(0, -8, 30, 32)
	move.hitbox = &"BiteHitbox"
	stats.moves = [move]
	return stats

func test_its_thread_is_tied_above_where_it_rests() -> void:
	assert_vector(_ai.anchor()).is_equal(Vector2(0.0, -_ai.anchor_height))
	_ai.wake()
	_body.global_position = Vector2(0.0, 90.0)
	assert_vector(_ai.anchor()).is_equal(Vector2(0.0, -_ai.anchor_height))

func test_asleep_it_ignores_a_target_under_it() -> void:
	_target.global_position = Vector2(BESIDE, 200.0)
	_drop(2.0)
	assert_vector(_body.global_position).is_equal(Vector2.ZERO)

func test_it_descends_to_the_chest_of_a_target_in_its_column() -> void:
	_ai.wake()
	_target.global_position = Vector2(BESIDE, 200.0)
	_drop(4.0)
	var chest := 200.0 + EnemyAI.CHEST.y + _ai.chest_height
	assert_float(_body.global_position.y).is_equal_approx(chest, 1.0)
	assert_float(_body.global_position.x).is_equal_approx(0.0, 0.01)

func test_it_lets_itself_down_no_farther_than_max_drop() -> void:
	_ai.wake()
	_target.global_position = Vector2(BESIDE, 2000.0)
	_drop(6.0)
	assert_float(_body.global_position.y).is_equal_approx(_ai.max_drop, 1.0)

func test_it_waits_out_linger_then_climbs_back() -> void:
	_ai.wake()
	_target.global_position = Vector2(BESIDE, 200.0)
	_drop(4.0)
	var low := _body.global_position.y
	_target.global_position = Vector2(_ai.column_half_width + 100.0, 200.0)
	_drop(_ai.linger - 0.2)
	assert_float(_body.global_position.y).is_equal_approx(low, 1.0)
	_drop(5.0)
	assert_float(_body.global_position.y).is_equal_approx(0.0, 1.0)
	assert_bool(_ai.is_home()).is_true()

## Each tick moves the body by its steer.
func _drop(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		_ai.tick(STEP)
		_body.global_position += _ai.steer * STEP
		elapsed += STEP
