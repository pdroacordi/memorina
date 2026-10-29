class_name FlyerAITest extends GdUnitTestSuite

## The hornet's style: it holds a point beside its target at the target's chest, dashes along the aim it locked when the
## telegraph ended, and a current bends that dash.

const STEP := 1.0 / 60.0
const HORNET_LOCOMOTION := "res://resources/characters/creatures/hornet/hornet_locomotion.tres"

var _body: Node2D
var _target: Node2D
var _sight: EnemySight
var _ai: FlyerAI
var _move: EnemyMove


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	_sight = EnemySight.new()
	_sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	_sight.add_child(ray)
	_body.add_child(_sight)
	_ai = FlyerAI.new()
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
	stats.locomotion.move_speed = 90.0
	stats.stop_distance = 0.0
	_move = EnemyMove.new()
	_move.telegraph = 0.5
	_move.active = 0.5
	_move.recovery = 0.6
	_move.cooldown = 1.2
	_move.reach = Rect2(0, -8, 160, 56)
	_move.lunge_speed = 380.0
	_move.hitbox = &"DashHitbox"
	stats.moves = [_move]
	return stats

func test_out_of_reach_it_holds_a_point_beside_the_target_at_its_chest() -> void:
	_move.reach = Rect2(0, -8, 20, 16)
	_target.global_position = Vector2(400.0, 200.0)
	_fly(4.0)
	var point := _target.global_position + EnemyAI.CHEST - Vector2(_ai.hover_distance, 0.0)
	assert_vector(_body.global_position).is_equal_approx(point, Vector2.ONE * 2.0)
	assert_float(_ai.facing_direction).is_equal(1.0)

func test_the_dash_keeps_the_aim_it_locked_when_the_telegraph_ended() -> void:
	_target.global_position = Vector2(120.0, 20.0)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_true()
	while _ai.is_telegraphing():
		_ai.tick(STEP)
	assert_bool(_ai.is_active()).is_true()
	var aim := FlyerAI.aim_at(Vector2.ZERO, Vector2(120.0, 20.0))
	assert_vector(_ai.steer.normalized()).is_equal_approx(aim, Vector2.ONE * 0.001)
	_target.global_position = Vector2(-200.0, -300.0)
	_ai.tick(STEP)
	assert_vector(_ai.steer).is_equal_approx(aim * _move.lunge_speed, Vector2.ONE * 0.01)

## The hornet's own tuning: a current across the dash carries it sideways (wind is a velocity, systems/air).
func test_a_current_bends_the_dash() -> void:
	var tuning := load(HORNET_LOCOMOTION) as LocomotionStats
	var steer := Vector2(380.0, 0.0)
	var wind := Vector2(0.0, -200.0)
	var velocity := Vector2.ZERO
	for i: int in 30:
		velocity = FlightComponent.steered(velocity, steer, wind, tuning, STEP)
	assert_vector(velocity).is_equal_approx(steer + wind * tuning.air_wind, Vector2.ONE * 0.5)
	assert_float(velocity.y).is_less(0.0)

func test_with_no_target_it_hovers_home() -> void:
	_target.remove_from_group(EnemySight.PRESENCE)
	_body.global_position = Vector2(60.0, -40.0)
	_fly(3.0)
	assert_float(_body.global_position.distance_to(Vector2.ZERO)).is_less_equal(_ai.bob_height + 1.0)

## Each tick moves the body by its steer, as a flight with instant acceleration would.
func _fly(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		_ai.tick(STEP)
		_body.global_position += _ai.steer * STEP
		elapsed += STEP

## A target that crosses under it during the telegraph: the dash faces where it flies, never tail first.
func test_the_dash_faces_where_it_flies() -> void:
	_target.global_position = Vector2(120.0, 20.0)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_true()
	assert_float(_ai.facing_direction).is_equal(1.0)
	_target.global_position = Vector2(-120.0, 20.0)
	while _ai.is_telegraphing():
		_ai.tick(STEP)
	assert_bool(_ai.is_active()).is_true()
	assert_float(_ai.steer.x).is_less(0.0)
	assert_float(_ai.facing_direction).is_equal(-1.0)
