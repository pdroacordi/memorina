class_name PlayerSceneTest extends GdUnitTestSuite

## In a cutscene Ivo hears no input, refuses doors, talks, benches, the Memorina and the map, walks by the scene's
## controller onto its mark, and a talk inside the scene owns the block so a NOTES beat still gets its notes.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
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
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func after_test() -> void:
	SaveSystem.begin("", true)

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return

func test_a_scene_blocks_him_and_refuses_the_map() -> void:
	await _land()
	assert_bool(_ivo.can_begin_scene()).is_true()
	_ivo.begin_scene()
	assert_bool(_player_input().blocked).is_true()
	assert_bool(_ivo.is_in_story()).is_true()
	assert_bool(_ivo.can_open_map()).is_false()
	assert_bool(_ivo.can_begin_scene()).is_false()
	_ivo.end_scene()
	assert_bool(_player_input().blocked).is_false()
	assert_bool(_ivo.can_open_map()).is_true()

## The talk owns the block while it runs; when it ends the scene takes it back.
func test_a_talk_inside_a_scene_owns_the_block() -> void:
	await _land()
	_ivo.begin_scene()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	assert_bool(_player_input().blocked).is_true()
	_ivo.pause_talk(DialogueBeat.Hold.NOTES)
	assert_bool(_player_input().blocked).is_false()
	assert_bool(_player_input().notes_only).is_true()
	_ivo.end_talk()
	assert_bool(_player_input().blocked).is_true()
	_ivo.end_scene()
	assert_bool(_player_input().blocked).is_false()

## The map's block is the map's: a scene ending under it leaves him blocked.
func test_the_map_block_outlives_a_scene() -> void:
	await _land()
	_ivo.block_input()
	assert_bool(_ivo.can_begin_scene()).is_false()
	_ivo.begin_scene()
	_ivo.end_scene()
	assert_bool(_player_input().blocked).is_true()
	_ivo.unblock_input()
	assert_bool(_player_input().blocked).is_false()

func test_a_driven_walk_ends_exactly_on_its_mark() -> void:
	await _land()
	var controller := auto_free(ScriptedController.new()) as ScriptedController
	add_child(controller)
	_ivo.begin_scene()
	_ivo.drive(controller)
	controller.walk_to(-90.0, 1.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_float(_ivo.move_axis()).is_less(0.0)
	for i: int in 240:
		await get_tree().physics_frame
		if not controller.is_walking():
			break
	await get_tree().physics_frame
	assert_float(_ivo.global_position.x).is_equal(-90.0)
	assert_int(_ivo.facing).is_equal(-1)
	_ivo.end_scene()
	assert_float(_ivo.move_axis()).is_equal(0.0)

func test_a_scene_pose_holds_until_the_scene_ends() -> void:
	await _land()
	_ivo.begin_scene()
	_ivo.stage_pose(DialogueBeat.Pose.GUITAR)
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.GUITAR)
	_ivo.end_scene()
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.NONE)

func test_the_memorina_is_refused_in_a_scene() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	await _land()
	_ivo.begin_scene()
	(_ivo.get_node("Memorina") as MemorinaComponent).buffer_toggle()
	for i: int in 5:
		await get_tree().physics_frame
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	_ivo.end_scene()

## STORY-16: a scene seats him (the bench's clip) and walks him slower than his run with the walk clip.
func test_a_scene_seats_him_and_strolls_him() -> void:
	await _land()
	var driver := _ivo.get_node("AnimationDriver") as AnimationDriver
	_ivo.begin_scene()
	_ivo.stage_pose(DialogueBeat.Pose.SEATED)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_str(String(driver.current)).is_equal(String(PlayerAnimationResolver.SIT))
	_ivo.stage_pose(DialogueBeat.Pose.NONE)
	var controller := auto_free(ScriptedController.new()) as ScriptedController
	add_child(controller)
	_ivo.drive(controller)
	controller.walk_to(200.0, 0.4)
	for i: int in 4:
		await get_tree().physics_frame
	assert_bool(_ivo.is_strolling()).is_true()
	assert_str(String(driver.current)).is_equal(String(PlayerAnimationResolver.WALK))
	controller.walk_to(-200.0, 1.0)
	for i: int in 4:
		await get_tree().physics_frame
	assert_str(String(driver.current)).is_equal(String(PlayerAnimationResolver.RUN))
	_ivo.end_scene()
