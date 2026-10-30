class_name GuardianLeapAnimationTest extends GdUnitTestSuite

## The lucidity leap plays its own clips: the crouch ends on take-off, rise and fall follow the arc, land plays on
## touchdown, then lucid (docs/knowledge/systems/guardians.md, "Our own art (GRD-07)").

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const BLOOM := preload("res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn")
const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")

## Top of the test floor.
const FLOOR_Y := 30.0
## Physics frames to wait for the whole leap: delay, flight and landing.
const LEAP_FRAMES := 300

var _holder: Node2D


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER | 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_the_bloom_leap_plays_crouch_rise_fall_and_land() -> void:
	await _assert_leap(BLOOM)

func test_the_frost_leap_plays_crouch_rise_fall_and_land() -> void:
	await _assert_leap(FROST)

func _assert_leap(scene: PackedScene) -> void:
	var guardian := scene.instantiate() as Guardian
	guardian.position = Vector2(0, FLOOR_Y)
	_holder.add_child(guardian)
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(60.0, FLOOR_Y - 30.0)
	_holder.add_child(ivo)
	for i: int in 10:
		await get_tree().physics_frame
	guardian.call(&"_on_player_entered")
	# The recall gate lifted, so the hits open lucidity.
	(guardian.get(&"_fight") as GuardianFight).set_recall_pending(false)
	var driver := guardian.get_node(^"AnimationDriver") as AnimationDriver
	var at_take_off: Array[StringName] = []
	var at_touchdown: Array[StringName] = []
	guardian.leapt.connect(func(_p: Vector2) -> void: at_take_off.append(driver.current))
	guardian.landed.connect(func(_p: Vector2, _s: float) -> void: at_touchdown.append(driver.current))
	for i: int in guardian.stats.hits_to_open:
		guardian.call(&"_on_hit_received", 1, Vector2.ZERO, ivo)
	var seen: Array[StringName] = []
	for i: int in LEAP_FRAMES:
		await get_tree().physics_frame
		if seen.is_empty() or seen.back() != driver.current:
			seen.append(driver.current)
		if guardian.is_leaping():
			var arc := GuardianAnimationResolver.LEAP_RISE if guardian.velocity.y < 0.0 else GuardianAnimationResolver.LEAP_FALL
			if driver.current != GuardianAnimationResolver.LEAP_CROUCH:
				assert_str(driver.current).override_failure_message("%s plays %s in its arc at vy %.0f" % [
					guardian.name, driver.current, guardian.velocity.y]).is_equal(arc)
	assert_array(at_take_off).override_failure_message("%s never leapt" % guardian.name).is_equal([GuardianAnimationResolver.LEAP_CROUCH])
	assert_array(at_touchdown).override_failure_message("%s never landed from its fall" % guardian.name).is_equal([GuardianAnimationResolver.LEAP_FALL])
	# The landing settles on lucid; play_song follows once the call's lead-in is over.
	var tail := seen.slice(seen.find(GuardianAnimationResolver.LEAP_CROUCH)).slice(0, 5)
	assert_array(tail).is_equal([GuardianAnimationResolver.LEAP_CROUCH, GuardianAnimationResolver.LEAP_RISE,
			GuardianAnimationResolver.LEAP_FALL, GuardianAnimationResolver.LEAP_LAND, GuardianAnimationResolver.LUCID])
	# Closed while Ivo is still in the tree: freed mid-call, his failure sound would play outside it.
	guardian.call(&"_abandon_call")
	await get_tree().physics_frame
