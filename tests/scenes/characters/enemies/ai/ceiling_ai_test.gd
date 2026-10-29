class_name CeilingAITest extends GdUnitTestSuite

## The bat's style: it waits at its anchor until a target is under it, swoops through where the target was when the drop
## ended, and flies back to hang.

const STEP := 1.0 / 60.0

var _body: Node2D
var _target: Node2D
var _sight: EnemySight
var _ai: CeilingAI
var _move: EnemyMove


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	_sight = EnemySight.new()
	_sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	_sight.add_child(ray)
	_body.add_child(_sight)
	_ai = CeilingAI.new()
	_ai.stats = _stats()
	_body.add_child(_ai)
	add_child(_body)
	_target = auto_free(Node2D.new()) as Node2D
	_target.add_to_group(EnemySight.PRESENCE)
	add_child(_target)
	_sight._on_entered(_target)
	_ai.wake()

func _stats() -> EnemyStats:
	var stats := EnemyStats.new()
	stats.locomotion = LocomotionStats.new()
	stats.locomotion.move_speed = 120.0
	stats.stop_distance = 0.0
	_move = EnemyMove.new()
	_move.telegraph = 0.3
	_move.active = 2.5
	_move.recovery = 0.6
	_move.cooldown = 1.5
	_move.reach = Rect2(-24, 48, 152, 176)
	_move.lunge_speed = 240.0
	_move.hitbox = &"SwoopHitbox"
	stats.moves = [_move]
	return stats

func test_it_waits_at_the_anchor_until_the_target_is_under_it() -> void:
	_target.global_position = Vector2(300.0, 160.0)
	for i: int in 60:
		_ai.tick(STEP)
		assert_bool(_ai.is_telegraphing()).is_false()
		assert_vector(_ai.steer).is_equal(Vector2.ZERO)
	assert_bool(_ai.is_home()).is_true()
	_target.global_position = Vector2(60.0, 160.0)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_true()

func test_the_swoop_passes_the_point_locked_at_the_end_of_the_drop() -> void:
	_target.global_position = Vector2(60.0, 160.0)
	var locked := _target.global_position + EnemyAI.CHEST
	_ai.tick(STEP)
	while _ai.is_telegraphing():
		_ai.tick(STEP)
	_target.global_position = Vector2(-300.0, 0.0)
	var nearest := INF
	while _ai.is_active():
		_body.global_position += _ai.steer * STEP
		nearest = minf(nearest, _body.global_position.distance_to(locked))
		_ai.tick(STEP)
	assert_float(nearest).is_less(3.0)
	assert_vector(_body.global_position).is_equal_approx(Vector2(2.0 * locked.x, 0.0), Vector2.ONE * 6.0)

func test_after_the_swoop_it_flies_back_and_hangs() -> void:
	_target.global_position = Vector2(60.0, 160.0)
	_ai.tick(STEP)
	_target.remove_from_group(EnemySight.PRESENCE)
	var elapsed := 0.0
	while (_ai.is_busy() or not _ai.is_home()) and elapsed < 8.0:
		_body.global_position += _ai.steer * STEP
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_home()).is_true()
	for i: int in 60:
		_body.global_position += _ai.steer * STEP
		_ai.tick(STEP)
	assert_vector(_body.global_position).is_equal_approx(Vector2.ZERO, Vector2.ONE * 1.0)
	assert_vector(_ai.steer).is_equal(Vector2.ZERO)

## Home is back along the swoop it flew, never straight at the anchor through a wall (bugs/the-icicle-bat-never-flies-home-after-a-swoop).
func test_it_flies_home_back_along_its_swoop() -> void:
	_target.global_position = Vector2(60.0, 160.0)
	var locked := _target.global_position + EnemyAI.CHEST
	_ai.tick(STEP)
	while _ai.is_telegraphing():
		_ai.tick(STEP)
	while _ai.is_active():
		_body.global_position += _ai.steer * STEP
		_ai.tick(STEP)
	var nearest := INF
	var elapsed := 0.0
	while not _ai.is_home() and elapsed < 8.0:
		_body.global_position += _ai.steer * STEP
		nearest = minf(nearest, _body.global_position.distance_to(locked))
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_home()).is_true()
	assert_float(nearest).override_failure_message("the way home passes the swoop's low point").is_less(6.0)
