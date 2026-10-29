class_name GuardianFacingTest extends GdUnitTestSuite

## A guardian flinches facing what hit it and keeps that side through the hurt clip; a restored guardian watches
## Ivo (docs/knowledge/systems/guardians.md, "Fixes after the GRD-07 playtest").

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const BLOOM := preload("res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn")
const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
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

func after_test() -> void:
	SaveSystem.begin("", true)

func test_a_flinch_faces_what_hit_it_and_keeps_that_side() -> void:
	var guardian := _guardian(BLOOM)
	_place_ivo(35.0)
	await _frames(10)
	guardian.call(&"_on_player_entered")
	assert_int(guardian.phase()).is_equal(GuardianFight.Phase.PRESSURE)
	var ai := guardian.get_node("AI") as GuardianAI
	# A cooldown: it gives ground from Ivo, walking away and so facing away.
	ai.set(&"_cooldown", 5.0)
	for i: int in 60:
		await get_tree().physics_frame
		if guardian.facing < 0:
			break
	assert_int(guardian.facing).override_failure_message("never turned away to give ground").is_equal(-1)
	guardian.call(&"_on_hit_received", 1, Vector2.ZERO, _ivo)
	assert_int(guardian.facing).is_equal(1)
	var flinch := (guardian.get_node("AnimationDriver") as AnimationDriver).clip_length(GuardianAnimationResolver.HURT)
	var elapsed := 0.0
	while elapsed < flinch - 0.05:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
		assert_int(guardian.facing).override_failure_message("turned mid-flinch at %.2f s" % elapsed).is_equal(1)

func test_a_restored_guardian_turns_to_ivo() -> void:
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	var guardian := _guardian(FROST)
	assert_int(guardian.phase()).is_equal(GuardianFight.Phase.RESTORED)
	_place_ivo(-200.0)
	await _frames(10)
	assert_int(guardian.facing).override_failure_message("its back to Ivo entering from the west").is_equal(-1)
	_ivo.teleport(Vector2(200.0, FLOOR_Y - 30.0))
	await _frames(10)
	assert_int(guardian.facing).is_equal(1)

func _guardian(scene: PackedScene) -> Guardian:
	var guardian := scene.instantiate() as Guardian
	guardian.position = Vector2(0, FLOOR_Y)
	_holder.add_child(guardian)
	return guardian

func _place_ivo(dx: float) -> void:
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(dx, FLOOR_Y - 30.0)
	_holder.add_child(_ivo)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
