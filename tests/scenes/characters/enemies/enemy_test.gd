class_name EnemyTest extends GdUnitTestSuite

## The body owns its areas every physics frame: off while hidden and dead, on once gathered; a defeated
## save_id never comes back before a rest; death frees the body only after the dissolve.

const SCORPION := "res://scenes/characters/creatures/scorpion/scorpion.tscn"
const BOAR := "res://scenes/characters/creatures/boar/boar.tscn"
const CRAB := "res://scenes/characters/creatures/crab/crab.tscn"
const BAT := "res://scenes/characters/creatures/bat/bat.tscn"
const SPIDER := "res://scenes/characters/creatures/spider/spider.tscn"
const DEFEATED_ID := "enemy_test_defeated"
const HURTBOX := "res://scenes/combat/hurtbox/hurtbox.tscn"
## Ivo's hurtbox invulnerability, s (ivo.tscn).
const IVO_INVULNERABILITY := 0.85


func after_test() -> void:
	SaveSystem._ledger.defeated.erase(DEFEATED_ID)

func _spawn(path: String, save_id: String = "") -> Enemy:
	var enemy := (load(path) as PackedScene).instantiate() as Enemy
	enemy.save_id = save_id
	add_child(enemy)
	return auto_free(enemy)

func test_a_hidden_creature_has_every_area_off_until_it_gathers() -> void:
	var enemy := _spawn(SCORPION)
	await await_idle_frame()
	assert_bool(enemy.is_dormant()).is_true()
	assert_bool(enemy.is_present()).is_false()
	assert_bool(enemy.hurtbox.monitorable).is_false()
	assert_bool((enemy.get_node(^"ContactHitbox") as Hitbox).monitoring).is_false()
	assert_bool((enemy.get_node(^"Guard") as Hitbox).monitoring).is_false()
	assert_bool((enemy.get_node(^"StrikeHitbox") as Hitbox).monitoring).is_false()

func test_once_woken_and_gathered_its_body_hurts_and_can_be_hurt() -> void:
	var enemy := _spawn(SCORPION)
	enemy.wake()
	assert_bool(enemy.is_present()).is_false()
	await await_millis(800)
	assert_bool(enemy.is_present()).is_true()
	assert_bool(enemy.hurtbox.monitorable).is_true()
	assert_bool((enemy.get_node(^"ContactHitbox") as Hitbox).monitoring).is_true()
	assert_bool((enemy.get_node(^"Guard") as Hitbox).monitoring).is_true()
	assert_bool((enemy.get_node(^"StrikeHitbox") as Hitbox).monitoring).is_false()

func test_stats_reach_the_children() -> void:
	var bait := (load(SCORPION) as PackedScene).instantiate() as Enemy
	bait.stats = load("res://resources/characters/creatures/scorpion/scorpion_bait_stats.tres")
	add_child(bait)
	auto_free(bait)
	var plain_sight := _spawn(SCORPION).get_node(^"EnemySight/CollisionShape2D") as CollisionShape2D
	assert_bool((bait.get_node(^"EnemySight/CollisionShape2D") as CollisionShape2D).shape == plain_sight.shape).is_false()
	assert_int(bait.health.max_hp).is_equal(8)
	assert_int(bait.health.current_hp).is_equal(8)
	assert_float(_radius(bait, ^"EnemySight/CollisionShape2D")).is_equal(366.0)
	assert_float(_radius(bait, ^"WakeTrigger/CollisionShape2D")).is_equal(200.0)
	var plain := _spawn(SCORPION)
	assert_float(_radius(plain, ^"EnemySight/CollisionShape2D")).is_equal(plain.stats.sight_radius)

func test_a_defeated_save_id_frees_on_ready() -> void:
	SaveSystem.mark_enemy_defeated(DEFEATED_ID)
	var enemy := (load(BOAR) as PackedScene).instantiate() as Enemy
	enemy.save_id = DEFEATED_ID
	add_child(enemy)
	assert_bool(enemy.is_queued_for_deletion()).is_true()

func test_death_marks_the_save_and_frees_only_after_the_dissolve() -> void:
	var enemy := _spawn(BOAR, DEFEATED_ID)
	enemy.wake()
	await await_millis(700)
	enemy.health.take_damage(99)
	assert_bool(SaveSystem.is_enemy_defeated(DEFEATED_ID)).is_true()
	await await_millis(100)
	assert_bool(is_instance_valid(enemy) and not enemy.is_queued_for_deletion()).is_true()
	assert_bool(enemy.hurtbox.monitorable).is_false()
	assert_bool((enemy.get_node(^"ContactHitbox") as Hitbox).monitoring).is_false()
	await await_millis(900)
	assert_bool(is_instance_valid(enemy) and not enemy.is_queued_for_deletion()).is_false()

## After its move hits, the body stops hurting until the move ends (recovery included), then hurts again.
func test_after_its_move_lands_the_body_stops_hurting_until_the_move_ends() -> void:
	var boar := await _gathered(BOAR)
	var contact := boar.get_node(^"ContactHitbox") as Hitbox
	boar._ai._clock.start(boar.stats.moves[0])
	await _until(func() -> bool: return boar.is_attacking(), 2.0)
	assert_bool(contact.monitoring).is_true()
	(boar.get_node(^"ChargeHitbox") as Hitbox).hit_landed.emit(boar.hurtbox)
	await await_idle_frame()
	await get_tree().physics_frame
	assert_bool(contact.monitoring).is_false()
	await _until(func() -> bool: return boar.is_recovering(), 3.0)
	assert_bool(contact.monitoring).is_false()
	await _until(func() -> bool: return not boar._ai.is_busy(), 3.0)
	await get_tree().physics_frame
	assert_bool(contact.monitoring).is_true()

## The scorpion's tail guard counts as its body.
func test_a_landed_strike_also_quiets_the_tail_guard() -> void:
	var scorpion := await _gathered(SCORPION)
	scorpion._ai._clock.start(scorpion.stats.moves[0])
	await _until(func() -> bool: return scorpion.is_attacking(), 2.0)
	(scorpion.get_node(^"StrikeHitbox") as Hitbox).hit_landed.emit(scorpion.hurtbox)
	await get_tree().physics_frame
	assert_bool((scorpion.get_node(^"Guard") as Hitbox).monitoring).is_false()
	assert_bool((scorpion.get_node(^"ContactHitbox") as Hitbox).monitoring).is_false()

## A target riding inside the boar, with Ivo's 0.85 s invulnerability, takes exactly one hit from charge to end of daze.
func test_one_charge_costs_exactly_one_life() -> void:
	var boar := await _gathered(BOAR)
	var target := (load(HURTBOX) as PackedScene).instantiate() as Hurtbox
	target.collision_layer = 512
	target.invulnerability_time = IVO_INVULNERABILITY
	target.position = Vector2(20, 0)
	var hits: Array[int] = [0]
	target.hit_received.connect(func(_damage: int, _knockback: Vector2, _source: Node2D) -> void:
		if boar._ai.is_active() or boar._ai.is_recovering():
			hits[0] += 1)
	boar.add_child(target)
	boar._ai._clock.start(boar.stats.moves[0])
	await _until(func() -> bool: return boar.is_attacking(), 2.0)
	await _until(func() -> bool: return not boar._ai.is_busy(), 4.0)
	assert_int(hits[0]).is_equal(1)

## User, 2026-10-29: "1 damage; shell blocks (Recommended)": a hit on the shell does no damage and flashes it white.
func test_the_crabs_shell_blocks_a_hit_from_in_front() -> void:
	var crab := await _gathered(CRAB)
	var blocks: Array[int] = [0]
	crab.blocked.connect(func() -> void: blocks[0] += 1)
	crab.hurtbox.receive_hit(1, Vector2(300, -100), _source(crab, Vector2(40, 0)))
	assert_int(crab.health.current_hp).is_equal(crab.stats.health)
	assert_int(blocks[0]).is_equal(1)
	assert_bool(crab.just_hit()).is_false()
	assert_bool(crab.is_in_knockback()).is_false()
	assert_float((crab.get_node(^"Sprite2D") as Sprite2D).modulate.r).is_greater(1.0)

func test_the_crab_is_hurt_from_behind_and_from_above() -> void:
	var crab := await _gathered(CRAB)
	crab.hurtbox.receive_hit(1, Vector2.ZERO, _source(crab, Vector2(-40, 0)))
	assert_int(crab.health.current_hp).is_equal(crab.stats.health - 1)
	crab.hurtbox.receive_hit(1, Vector2.ZERO, _source(crab, Vector2(10, -40)))
	assert_int(crab.health.current_hp).is_equal(crab.stats.health - 2)

## User, 2026-10-29: the bat and the spider are drawn asleep, so they can be struck asleep, and a hit wakes them.
func test_a_creature_drawn_asleep_is_present_and_a_hit_wakes_it() -> void:
	var bat := _spawn(BAT)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(bat.is_dormant()).is_true()
	assert_bool(bat.is_present()).is_true()
	assert_bool(bat.hurtbox.monitorable).is_true()
	assert_bool((bat.get_node(^"ContactHitbox") as Hitbox).monitoring).is_true()
	bat.hurtbox.receive_hit(1, Vector2.ZERO, _source(bat, Vector2(30, 0)))
	assert_bool(bat.is_dormant()).is_false()

func test_the_spiders_thread_hangs_from_its_anchor() -> void:
	var spider := _spawn(SPIDER)
	spider.global_position = Vector2(100, 200)
	await await_idle_frame()
	await await_idle_frame()
	var thread := spider.get_node(^"SilkThread") as Node2D
	assert_vector(thread.global_position).is_equal(Vector2(100, 200 - 16))
	assert_bool(thread.visible).is_true()

func _source(enemy: Enemy, offset: Vector2) -> Node2D:
	var source := auto_free(Node2D.new()) as Node2D
	add_child(source)
	source.global_position = enemy.global_position + offset
	return source

func _gathered(path: String) -> Enemy:
	var enemy := _spawn(path)
	enemy.wake()
	await _until(func() -> bool: return enemy.is_present(), 2.0)
	return enemy

func _until(condition: Callable, seconds: float) -> void:
	var waited := 0
	while not condition.call() and waited < int(seconds * 60.0):
		await get_tree().physics_frame
		waited += 1
	assert_bool(condition.call()).is_true()

func _radius(enemy: Enemy, path: NodePath) -> float:
	return ((enemy.get_node(path) as CollisionShape2D).shape as CircleShape2D).radius
