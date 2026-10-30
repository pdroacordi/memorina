class_name GuardianLeapFramingTest extends GdUnitTestSuite

## The camera pairs Ivo and a leaping guardian at take-off, so the landing is in frame; only the landing stages the call
## (docs/knowledge/systems/guardians.md, "The leap is framed from take-off (GRD-09)").

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
	# Ground (GroundCollision.COLLISION_LAYER) for the guardian, layer 2 for Ivo.
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER | 2
	# Thick, like a room's ground: the leap takes its collision back near the floor at full fall speed.
	floor_body.position = Vector2(0, FLOOR_Y + 160.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 320)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_the_bloom_leap_is_framed_from_take_off_and_lands_in_view() -> void:
	await _assert_framed_leap(BLOOM)

func test_the_frost_leap_is_framed_from_take_off_and_lands_in_view() -> void:
	await _assert_framed_leap(FROST)

func test_a_call_abandoned_mid_leap_releases_the_frame() -> void:
	var setup := await _set_up(FROST)
	var guardian := setup[0] as Guardian
	var ivo := setup[1] as Player
	var released: Array[bool] = []
	ivo.call_unstaged.connect(func() -> void: released.append(true))
	_open_lucidity(guardian, ivo)
	for i: int in LEAP_FRAMES:
		await get_tree().physics_frame
		if guardian.is_leaping():
			break
	assert_bool(guardian.is_leaping()).override_failure_message("the golem never leapt").is_true()
	guardian.call(&"_abandon_call")
	assert_array(released).is_equal([true])
	await get_tree().physics_frame

func _assert_framed_leap(scene: PackedScene) -> void:
	var setup := await _set_up(scene)
	var guardian := setup[0] as Guardian
	var ivo := setup[1] as Player
	var camera := setup[2] as GameCamera
	var events: Array[String] = []
	ivo.call_framed.connect(func(caller: Node2D) -> void:
		assert_object(caller).is_same(guardian)
		events.append("framed:%s" % ("leaping" if guardian.is_leaping() else "grounded")))
	ivo.call_staged.connect(func(_caller: Node2D) -> void:
		events.append("staged:%s" % ("leaping" if guardian.is_leaping() else "grounded")))
	var outside_at_touchdown: Array[float] = []
	guardian.landed.connect(func(_p: Vector2, _s: float) -> void:
		var view := camera.view_rect()
		var body := guardian.body_rect()
		outside_at_touchdown.append(maxf(view.position.x - body.position.x, body.end.x - view.end.x)))
	_open_lucidity(guardian, ivo)
	for i: int in LEAP_FRAMES:
		await get_tree().physics_frame
		if events.size() >= 2:
			break
	assert_array(events).override_failure_message("%s framed and staged as %s" % [guardian.name, events]) \
		.is_equal(["framed:leaping", "staged:grounded"])
	assert_int(outside_at_touchdown.size()).is_equal(1)
	assert_float(outside_at_touchdown[0]).override_failure_message(
		"%s lands %.0f px outside the frame" % [guardian.name, outside_at_touchdown[0]]).is_less_equal(0.0)
	# Closed while Ivo is still in the tree: freed mid-call, his failure sound would play outside it.
	guardian.call(&"_abandon_call")
	await get_tree().physics_frame

## [guardian, ivo, camera]: the camera follows Ivo and answers his `call_framed` as game.tscn wires it.
func _set_up(scene: PackedScene) -> Array:
	var guardian := scene.instantiate() as Guardian
	guardian.position = Vector2(0, FLOOR_Y)
	_holder.add_child(guardian)
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(60.0, FLOOR_Y - 30.0)
	_holder.add_child(ivo)
	var camera := GameCamera.new()
	_holder.add_child(camera)
	camera.make_current()
	camera.follow(ivo)
	ivo.call_framed.connect(camera.frame_pair)
	ivo.call_unstaged.connect(camera.release_pair)
	for i: int in 10:
		await get_tree().physics_frame
	return [guardian, ivo, camera]

func _open_lucidity(guardian: Guardian, ivo: Player) -> void:
	guardian.call(&"_on_player_entered")
	(guardian.get(&"_fight") as GuardianFight).set_recall_pending(false)
	for i: int in guardian.stats.hits_to_open:
		guardian.call(&"_on_hit_received", 1, Vector2.ZERO, ivo)
