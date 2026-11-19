class_name GuardianEngineTest extends GdUnitTestSuite

## The shared fight engine on the fixture guardian: spawns fired per strike and cleared out of the pressure, motions
## moved by GuardianMover, and the wind-up, recovery and replayed strike clips (architecture/grd-12-guardian-fight-engine).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const ENGINE := preload("res://tests/fixtures/guardians/engine_guardian.tscn")
const PATCH := preload("res://scenes/characters/guardians/spawns/floor_patch/floor_patch.tscn")
const SHARD := preload("res://scenes/characters/guardians/spawns/falling_shard/falling_shard.tscn")
const BURST := preload("res://tests/fixtures/guardians/engine_burst.tres")

const FLOOR_Y := 30.0
const STEP := 1.0 / 60.0

var _holder: Node2D
var _guardian: Guardian
var _ai: GuardianAI
var _spawner: GuardianSpawner
var _driver: AnimationDriver
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_guardian = ENGINE.instantiate() as Guardian
	_guardian.position = Vector2(0, FLOOR_Y)
	_holder.add_child(_guardian)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(600, FLOOR_Y)
	_holder.add_child(_ivo)
	_ai = _guardian.get_node(^"AI") as GuardianAI
	_spawner = _guardian.get_node(^"Spawner") as GuardianSpawner
	_driver = _guardian.get_node(^"AnimationDriver") as AnimationDriver
	_guardian.call(&"_on_player_entered")
	await _frames(2)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_a_spawn_fires_once_per_strike() -> void:
	var move := _move([_patch_spawn(0.1)])
	_throw(move)
	await _seconds(1.2)
	assert_int(_spawns()).is_equal(1)

func test_a_repeated_link_fires_its_spawn_again() -> void:
	var move := _move([_patch_spawn(0.1)])
	move.follow_ups = [GuardianFollowUp.new()]
	_ai.max_links = 2
	_throw(move)
	await _seconds(1.5)
	assert_int(_spawns()).is_equal(2)

func test_spawns_are_cleared_when_the_pressure_ends() -> void:
	for to: GuardianFight.Phase in [GuardianFight.Phase.LUCIDITY, GuardianFight.Phase.RESTORED]:
		await before_test()
		var spawn := _patch_spawn(0.0)
		_throw(_move([spawn]))
		await _seconds(0.2)
		assert_int(_spawns()).is_equal(1)
		_guardian.fight().call(&"_transition", to)
		await _frames(2)
		assert_int(_spawns()).override_failure_message("a spawn outlived the pressure into %d" % to).is_equal(0)

func test_spawns_are_cleared_when_a_recall_move_starts() -> void:
	_throw(_move([_patch_spawn(0.0)]))
	await _seconds(0.2)
	assert_int(_spawns()).is_equal(1)
	_ai.cancel_attack()
	_throw(BURST)
	await _seconds(BURST.telegraph + 0.1)
	assert_int(_spawns()).is_equal(0)

func test_a_spawn_stops_with_its_guardians_room() -> void:
	_throw(_move([_patch_spawn(0.0)]))
	await _seconds(0.1)
	var patch := _spawner.get_child(0) as SpawnedAttack
	_holder.process_mode = Node.PROCESS_MODE_DISABLED
	var before: float = patch.get(&"_t")
	await _frames(10)
	assert_float(patch.get(&"_t")).is_equal(before)
	_holder.process_mode = Node.PROCESS_MODE_INHERIT

func test_a_blink_teleports_with_no_stale_physics_position() -> void:
	var blink := BlinkMotion.new()
	blink.at = 0.1
	var move := _move([])
	move.motion = blink
	_throw(move)
	await _seconds(0.25)
	var state := PhysicsServer2D.body_get_state(_guardian.get_rid(), PhysicsServer2D.BODY_STATE_TRANSFORM) as Transform2D
	assert_float(state.origin.x).is_equal_approx(_guardian.global_position.x, 1.0)
	assert_float(_guardian.global_position.x).override_failure_message("did not reappear by Ivo").is_greater(400.0)

func test_a_hang_holds_the_body_up_with_gravity_off() -> void:
	var dive := DiveMotion.new()
	dive.height = 80.0
	dive.rise_time = 0.15
	dive.hang = 0.3
	dive.dive_time = 0.15
	var move := _move([])
	move.motion = dive
	_throw(move)
	await _seconds(0.25)
	var held := _guardian.global_position.y
	await _seconds(0.15)
	assert_float(_guardian.global_position.y).is_equal_approx(held, 1.0)
	assert_float(FLOOR_Y - held).is_greater(60.0)

func test_a_wind_up_plays_through_the_telegraph() -> void:
	var move := _move([])
	move.telegraph = 0.35
	move.windup_index = 0
	_throw(move)
	await _frames(3)
	assert_str(String(_driver.current)).is_equal(String(GuardianAnimationResolver.WINDUP_1))

func test_a_recovery_plays_after_the_strings_last_strike() -> void:
	var move := _move([])
	move.recovery = 0.4
	move.recovery_index = 0
	_throw(move)
	await _seconds(0.6 + 0.15)
	assert_bool(_ai.is_recovering()).is_true()
	assert_float(_ai.facing_intent()).is_equal(0.0)
	assert_str(String(_driver.current)).is_equal(String(GuardianAnimationResolver.RECOVER_1))

func test_a_repeated_link_replays_its_strike_clip() -> void:
	var move := _move([])
	move.telegraph = 0.0
	move.follow_ups = [GuardianFollowUp.new()]
	_ai.max_links = 2
	var started: Array[float] = []
	_ai.attack_started.connect(func(_attack: GuardianAttack) -> void: started.append(0.0))
	_throw(move)
	await _seconds(0.7)
	assert_int(started.size()).is_equal(2)
	assert_str(String(_driver.current)).is_equal(String(GuardianAnimationResolver.ATTACK_1))
	assert_float(_driver.position()).override_failure_message("the second strike did not restart its clip").is_less(0.2)

## bugs/a-guardian-motion-left-undriven-mid-strike-keeps-gravity-off-and-the-world-passed-through
func test_a_hang_left_undriven_falls() -> void:
	var dive := DiveMotion.new()
	dive.height = 80.0
	dive.rise_time = 0.15
	dive.hang = 0.3
	dive.dive_time = 0.15
	var move := _move([])
	move.motion = dive
	_throw(move)
	await _seconds(0.25)
	var held := _guardian.global_position.y
	_guardian.fight().call(&"_transition", GuardianFight.Phase.LUCIDITY)
	await _seconds(0.2)
	assert_float(_guardian.global_position.y).override_failure_message("an undriven hang floats").is_greater(held + 4.0)

func test_a_leap_through_the_ceiling_left_undriven_takes_the_world_back() -> void:
	var leap := LeapMotion.new()
	leap.height = 120.0
	leap.air_time = 0.5
	leap.through_ceiling = true
	var move := _move([])
	move.motion = leap
	var solid := _guardian.collision_mask
	_throw(move)
	await _seconds(0.2)
	assert_int(_guardian.collision_mask).override_failure_message("the leap did not pass through").is_equal(0)
	_guardian.fight().call(&"_transition", GuardianFight.Phase.LUCIDITY)
	await _frames(3)
	assert_int(_guardian.collision_mask).is_equal(solid)

## bugs/one-note-per-string-is-not-held-by-the-contact-box-or-a-links-spawns
func test_every_hitbox_of_a_string_shares_its_gate_and_the_gate_ends_with_it() -> void:
	var gate := (_guardian.get_node(^"Hitbox") as Hitbox).gate
	assert_object(gate).is_not_null()
	assert_object((_guardian.get_node(^"ContactHitbox") as Hitbox).gate).is_same(gate)
	var move := _move([_patch_spawn(0.0)])
	move.follow_ups = [GuardianFollowUp.new()]
	_ai.max_links = 2
	_throw(move)
	await _seconds(0.2)
	var patch := _spawner.get_child(0) as SpawnedAttack
	assert_object(patch.hitbox().gate).is_same(gate)
	var target: Node = auto_free(Node.new())
	gate.record(target)
	await _seconds(0.55)
	assert_int(_ai.link_index()).is_equal(1)
	assert_bool(gate.allows(target)).override_failure_message("a link hurt again").is_false()
	await _seconds(0.65)
	assert_bool(_ai.is_attacking()).is_false()
	assert_bool(gate.allows(target)).override_failure_message("the gate outlived its string").is_true()

func test_icicles_aimed_at_ivo_fall_where_he_stands_as_each_one_fires() -> void:
	var spawn := GuardianSpawn.new()
	spawn.scene = SHARD
	spawn.placement = GuardianSpawn.Placement.AT_IVO
	spawn.count = 2
	spawn.interval = 0.3
	_throw(_move([spawn]))
	await _seconds(0.1)
	_ivo.teleport(Vector2(450.0, FLOOR_Y))
	await _seconds(0.35)
	var xs: Array[float] = []
	for child: Node in _spawner.get_children():
		xs.append((child as Node2D).position.x)
	assert_array(xs).has_size(2)
	assert_float(absf(xs[0] - xs[1])).override_failure_message("the second shard fell on the old spot").is_greater(100.0)

func _throw(move: GuardianAttack) -> void:
	_guardian.set_attacks([move])
	_ai.call(&"_start_telegraph", move)

## A lash-length move on `attack_1` that reaches Ivo anywhere and never comes back on its own.
func _move(spawns: Array[GuardianSpawn]) -> GuardianAttack:
	var move := GuardianAttack.new()
	move.duration = 0.6
	move.telegraph = 0.05
	move.attack_range = 2000.0
	move.attack_height = 1000.0
	move.cooldown = 100.0
	move.spawns = spawns
	return move

func _patch_spawn(at: float) -> GuardianSpawn:
	var spawn := GuardianSpawn.new()
	spawn.scene = PATCH
	spawn.at = at
	return spawn

func _spawns() -> int:
	var count := 0
	for child: Node in _spawner.get_children():
		if child is SpawnedAttack and not child.is_queued_for_deletion():
			count += 1
	return count

func _seconds(seconds: float) -> void:
	await _frames(ceili(seconds / STEP))

## physics_frame is emitted before the nodes' own physics step, so one frame is not enough to see its write.
func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
