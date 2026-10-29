class_name WalkerAITest extends GdUnitTestSuite

## The walker's combat rules, the brute's three bugs among them
## (docs/knowledge/bugs/the-brute-swings-away-from-a-target-already-in-reach.md,
## docs/knowledge/bugs/the-brute-walks-under-ivo-when-he-jumps-from-where-it-parks.md).

const STEP := 1.0 / 60.0
const SPEED := 60.0
## Inside the 90 px reach on either side, and inside the 48 px stop distance.
const BEHIND := Vector2(-30, 0)
const IN_FRONT := Vector2(30, 0)
const FAR_BEHIND := Vector2(-300, 0)

var _body: Node2D
var _target: Node2D
var _sight: EnemySight
var _ai: WalkerAI
var _move: EnemyMove


func before_test() -> void:
	_body = auto_free(Node2D.new()) as Node2D
	_sight = EnemySight.new()
	_sight.name = "EnemySight"
	var ray := RayCast2D.new()
	ray.name = "RayCast2D"
	_sight.add_child(ray)
	_body.add_child(_sight)
	_ai = WalkerAI.new()
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
	stats.locomotion.move_speed = SPEED
	stats.stop_distance = 48.0
	_move = EnemyMove.new()
	_move.telegraph = 0.3
	_move.active = 0.2
	_move.recovery = 0.3
	_move.cooldown = 1.0
	_move.reach = Rect2(0, -40, 90, 48)
	_move.hitbox = &"StrikeHitbox"
	stats.moves = [_move]
	return stats

## The Downtown case: the AI starts with the target already behind it and in reach.
func test_a_move_at_a_target_already_in_reach_faces_it() -> void:
	_place_target(BEHIND)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_true()
	assert_float(_ai.direction).is_equal(0.0)
	assert_float(_ai.facing_direction).is_equal(-1.0)

func test_a_move_keeps_the_side_it_started_on() -> void:
	_place_target(BEHIND)
	_ai.tick(STEP)
	_place_target(IN_FRONT)
	for i: int in 30:
		_ai.tick(STEP)
		assert_float(_ai.facing_direction).is_equal(-1.0)

func test_waiting_out_the_cooldown_in_reach_turns_without_walking() -> void:
	_place_target(BEHIND)
	_move_to_the_end()
	_place_target(IN_FRONT)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_false()
	assert_float(_ai.direction).is_equal(0.0)
	assert_float(_ai.facing_direction).is_equal(1.0)

## A move thrown from afar is followed by closing to the stop distance, inside Ivo's reach.
func test_after_a_long_move_it_closes_to_the_stop_distance_on_x_only() -> void:
	_place_target(Vector2(70, 0))
	_move_to_the_end()
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(1.0)
	assert_float(_ai.steer.x).is_equal(SPEED)
	_place_target(Vector2(40, 0))
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(0.0)
	assert_float(_ai.facing_direction).is_equal(1.0)

## Ivo jumping in place from where it parks is not moving away: it must not walk under his landing.
func test_a_jump_from_the_parking_spot_does_not_draw_it_under_ivo() -> void:
	_place_target(Vector2(70, 0))
	_move_to_the_end()
	for height: float in [-60.0, -144.0]:
		_place_target(Vector2(48, height))
		_ai.tick(STEP)
		assert_float(_ai.direction).is_equal(0.0)

## A target on a ledge nearly overhead neither draws it back and forth nor flips it.
func test_a_target_nearly_overhead_on_a_ledge_does_not_flip_it() -> void:
	_place_target(Vector2(70, 0))
	_move_to_the_end()
	for dx: float in [2.0, -2.0, 6.0, -6.0]:
		_place_target(Vector2(dx, -60))
		_ai.tick(STEP)
		assert_float(_ai.direction).is_equal(0.0)
		assert_float(_ai.facing_direction).is_equal(1.0)
	_place_target(Vector2(-30, -60))
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(0.0)
	assert_float(_ai.facing_direction).is_equal(-1.0)

func test_out_of_reach_it_faces_where_it_walks() -> void:
	_place_target(FAR_BEHIND)
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_false()
	assert_float(_ai.direction).is_equal(-1.0)
	assert_float(_ai.facing_direction).is_equal(-1.0)

func test_a_ledge_ahead_stops_the_chase() -> void:
	_place_target(Vector2(300, 0))
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(1.0)
	_ai.ledge_ahead = true
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(0.0)

func test_a_wall_ends_a_lunge_into_recovery() -> void:
	_move.lunge_speed = 300.0
	_move.ends_on_wall = true
	_move.active = 1.2
	_place_target(Vector2(60, 0))
	_tick_until(func() -> bool: return _ai.is_active())
	assert_float(_ai.steer.x).is_equal(300.0)
	_ai.handle_wall_contact()
	assert_bool(_ai.is_recovering()).is_true()
	_ai.tick(STEP)
	assert_float(_ai.steer.x).is_equal(0.0)

func test_a_ledge_ends_a_lunge_that_ends_on_walls() -> void:
	_move.lunge_speed = 300.0
	_move.ends_on_wall = true
	_move.active = 1.2
	_place_target(Vector2(60, 0))
	_tick_until(func() -> bool: return _ai.is_active())
	_ai.ledge_ahead = true
	_ai.tick(STEP)
	assert_bool(_ai.is_recovering()).is_true()
	assert_float(_ai.steer.x).is_equal(0.0)

func test_the_leash_holds_it_and_walks_it_home() -> void:
	_ai.stats.leash = 100.0
	_place_target(Vector2(400, 0))
	_body.global_position.x += 100.0
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(0.0)
	_sight._on_exited(_target)
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(-1.0)
	_body.global_position.x -= 98.0
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(0.0)

func test_a_dormant_walker_ignores_a_presence() -> void:
	var sleeper := WalkerAI.new()
	sleeper.stats = _stats()
	_body.add_child(sleeper)
	_place_target(IN_FRONT)
	sleeper.tick(STEP)
	assert_bool(sleeper.is_awake()).is_false()
	assert_bool(sleeper.is_telegraphing()).is_false()
	assert_vector(sleeper.steer).is_equal(Vector2.ZERO)

## Sombra's shadow is a presence: the walker goes for it with Ivo nowhere near (design 02 section 7.1).
func test_a_shadow_presence_is_targeted() -> void:
	_target.remove_from_group(EnemySight.PRESENCE)
	var shadow := auto_free(Node2D.new()) as Node2D
	shadow.add_to_group(EnemySight.PRESENCE)
	add_child(shadow)
	_sight._on_entered(shadow)
	shadow.global_position = _body.global_position + Vector2(-250, 0)
	_ai.tick(STEP)
	assert_float(_ai.direction).is_equal(-1.0)

func test_a_hit_cancels_a_telegraph_but_not_an_armoured_lunge() -> void:
	_place_target(IN_FRONT)
	_ai.tick(STEP)
	_ai.on_hurt()
	assert_bool(_ai.is_telegraphing()).is_false()
	assert_bool(_ai.is_active()).is_false()
	_move.armoured = true
	_move.cooldown = 0.0
	_ai.tick(STEP)
	_ai.tick(STEP)
	_tick_until(func() -> bool: return _ai.is_active())
	_ai.on_hurt()
	assert_bool(_ai.is_active()).is_true()

func test_the_move_signals_follow_its_phases() -> void:
	var heard: Array[String] = []
	_ai.move_telegraphed.connect(func(_move_: EnemyMove) -> void: heard.append("telegraphed"))
	_ai.move_started.connect(func(_move_: EnemyMove) -> void: heard.append("started"))
	_ai.move_finished.connect(func(_move_: EnemyMove) -> void: heard.append("finished"))
	_place_target(IN_FRONT)
	_move_to_the_end()
	assert_array(heard).contains_exactly(["telegraphed", "started", "finished"])

func _place_target(offset: Vector2) -> void:
	_target.global_position = _body.global_position + offset

func _tick_until(condition: Callable) -> void:
	var elapsed := 0.0
	while not condition.call() and elapsed < 5.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(condition.call()).is_true()

func _move_to_the_end() -> void:
	_ai.tick(STEP)
	assert_bool(_ai.is_telegraphing()).is_true()
	var elapsed := 0.0
	while (_ai.is_telegraphing() or _ai.is_active() or _ai.is_recovering()) and elapsed < 5.0:
		_ai.tick(STEP)
		elapsed += STEP
	assert_bool(_ai.is_recovering()).is_false()
