class_name PlayerRecallTest extends GdUnitTestSuite

## A recall press also acts: a jump pressed mid-swing cuts the swing and jumps, and a jump step short
## of the last counts only when the jump happens
## (docs/knowledge/bugs/a-recall-jump-pressed-during-a-swing-counts-a-step-without-jumping.md).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

## Top of the test floor.
const FLOOR_Y := 30.0

var _ivo: Player
var _stats: AbilityRecallStats
var _recalled: Array[Enums.PlayerSkill] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	_recalled.clear()
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	holder.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	holder.add_child(_ivo)
	_ivo.skill_recalled.connect(func(skill: Enums.PlayerSkill) -> void: _recalled.append(skill))
	# The Bloom burst's recall, without its trigger distance (no source here).
	_stats = AbilityRecallStats.new()
	_stats.skill = Enums.PlayerSkill.DOUBLE_JUMP
	_stats.action = &"jump"
	_stats.window = 1.6
	_stats.grounded_steps = 2
	_stats.airborne_finish = true
	_stats.step_window = 1.0

func after_test() -> void:
	SaveSystem.begin("", true)

func test_a_jump_pressed_mid_swing_jumps_and_counts_the_first_step() -> void:
	await _land()
	_player_input().attack_pressed.emit()
	await _frames(2)
	assert_bool(_ivo.is_attacking()).is_true()
	_ivo.begin_recall(_stats)
	assert_int(_recall().steps_left()).is_equal(2)
	_player_input().jump_pressed.emit()
	# The press alone is not the step: the jump is.
	assert_int(_recall().steps_left()).is_equal(2)
	await _frames(6)
	assert_bool(_ivo.is_attacking()).is_false()
	assert_bool(_ivo.is_on_floor()).is_false()
	assert_int(_recall().steps_left()).is_equal(1)
	_player_input().jump_pressed.emit()
	await _frames(1)
	assert_array(_recalled).contains_exactly([Enums.PlayerSkill.DOUBLE_JUMP])

func test_a_jump_that_does_not_happen_does_not_count() -> void:
	await _land()
	_ivo.begin_recall(_stats)
	# Nothing is buffered, so the press never becomes a jump.
	_jump().clear_buffer()
	_ivo.call(&"_notify_recall", &"jump")
	await _frames(4)
	assert_bool(_ivo.is_on_floor()).is_true()
	assert_int(_recall().steps_left()).is_equal(2)

## bugs/a-grounded-double-jump-recall-launched-before-the-first-press-cannot-count-it.
func test_a_press_after_a_launch_past_coyote_time_counts() -> void:
	await _land()
	_ivo.begin_recall(_stats)
	_ivo.velocity.y = -560.0
	await _frames(20)
	assert_bool(_jump().can_ground_jump(_ivo.is_on_floor())).is_false()
	_player_input().jump_pressed.emit()
	await _frames(1)
	assert_int(_recall().steps_left()).is_equal(1)
	_player_input().jump_pressed.emit()
	await _frames(1)
	assert_array(_recalled).contains_exactly([Enums.PlayerSkill.DOUBLE_JUMP])

## A wall-cued recall waits for Ivo to touch a wall; a press late in the window recalls WALL_CLIMB, jumps, and grips the
## wall with nothing held, pushed only as GuardianGust pushes (GRD-04, the autumn gust;
## bugs/the-gust-recall-grip-with-nothing-held-outlives-the-push-and-the-escape-time).
func test_a_wall_cued_recall_opens_at_the_wall_and_grips_it_with_nothing_held() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.position = Vector2(160, FLOOR_Y - 200.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 400)
	shape.shape = rect
	wall.add_child(shape)
	_ivo.get_parent().add_child(wall)
	await _land()
	var source := auto_free(Node2D.new()) as Node2D
	source.position = Vector2(-400, FLOOR_Y)
	var gust := load("res://resources/characters/guardians/autumn_guardian/autumn_gust.tres") as GuardianAttack
	_ivo.begin_recall(gust.recall, 2.4, source)
	await _frames(2)
	assert_bool(_recall().is_armed()).override_failure_message("opened away from the wall").is_false()
	for i: int in 90:
		_ivo.push(GuardianGust.push_for(gust, true, 1, source.position, _ivo.global_position))
		await get_tree().physics_frame
		if _recall().is_armed():
			break
	assert_bool(_recall().is_armed()).override_failure_message("never opened at the wall").is_true()
	# Late in the window: the world is slowed, so most of a real second.
	for i: int in 50:
		_ivo.push(GuardianGust.push_for(gust, true, 1, source.position, _ivo.global_position))
		await get_tree().physics_frame
	_player_input().jump_pressed.emit()
	var gripped := false
	for i: int in 400:
		_ivo.push(GuardianGust.push_for(gust, true, 1, source.position, _ivo.global_position))
		await get_tree().physics_frame
		if _ivo.is_wall_sliding():
			gripped = true
			break
	assert_bool(SaveSystem.has_skill(Enums.PlayerSkill.WALL_CLIMB)).is_true()
	assert_bool(gripped).override_failure_message("never gripped the wall with nothing held").is_true()

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _recall() -> AbilityRecallComponent:
	return _ivo.get_node("AbilityRecall") as AbilityRecallComponent

func _jump() -> JumpComponent:
	return _ivo.get_node("Jump") as JumpComponent

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")
