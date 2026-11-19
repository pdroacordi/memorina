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

## The blow the recall teaches to escape landed before the press: a miss, not a lesson; a 0-damage launcher (the Bloom
## burst), its body's contact and another body's hit leave it open (playtests/2026-11-18-grd14-frost-feel, (5);
## bugs/a-guardians-contact-touch-during-its-recall-window-costs-the-hit-and-the-miss-damage).
func test_only_a_damaging_hit_from_the_move_box_closes_it_as_a_miss() -> void:
	var recall := _ivo.get_node(^"AbilityRecall") as AbilityRecallComponent
	var guardian := auto_free(Node2D.new()) as Node2D
	var fist := Node2D.new()
	var body := Node2D.new()
	guardian.add_child(fist)
	guardian.add_child(body)
	add_child(guardian)
	var stranger := auto_free(Node2D.new()) as Node2D
	add_child(stranger)
	var missed: Array[Enums.PlayerSkill] = []
	_ivo.skill_recall_missed.connect(func(skill: Enums.PlayerSkill) -> void: missed.append(skill))
	# Three damaging hits before the blow: enough life that none of them kills him (a death drops the window).
	_ivo.health.max_hp = 9
	_ivo.health.current_hp = 9
	_ivo.open_recall(_stats, guardian, fist)
	assert_bool(recall.is_armed()).is_true()
	for source: Node2D in [fist, body, stranger]:
		var damage := 0 if source == fist else 1
		_hit(damage, source)
		assert_bool(recall.is_armed()).override_failure_message("%s closed it" % source.name).is_true()
	_hit(1, fist)
	assert_bool(recall.is_armed()).is_false()
	assert_array(missed).contains_exactly([_stats.skill])
	assert_array(_recalled).is_empty()

## The Bloom burst's real recall (miss_damage 1): a touch of the stag's contact box in the window costs that touch only,
## and the window stays open; the burst's own box hitting Ivo closes it at the hit's cost, with no miss damage on top.
func test_a_bloom_contact_touch_costs_one_note_and_its_burst_closes_without_miss_damage() -> void:
	var bloom := auto_free((load("res://scenes/characters/guardians/bloom_guardian/bloom_guardian.tscn") as PackedScene).instantiate()) as Node2D
	var stats := load("res://resources/characters/guardians/bloom_guardian/recall_double_jump.tres") as AbilityRecallStats
	var recall := _ivo.get_node(^"AbilityRecall") as AbilityRecallComponent
	var contact := bloom.get_node(^"ContactHitbox") as Node2D
	var box := bloom.get_node(^"Hitbox") as Node2D
	_ivo.open_recall(stats, bloom, box)
	var before := _ivo.health.current_hp
	_hit(1, contact)
	assert_int(_ivo.health.current_hp).is_equal(before - 1)
	assert_bool(recall.is_armed()).override_failure_message("the contact closed the window").is_true()
	_hit(1, box)
	assert_bool(recall.is_armed()).is_false()
	assert_int(_ivo.health.current_hp).override_failure_message("miss damage on top of the blow").is_equal(before - 2)

## The Frost charge's fists closing the roll's window cost that hit only.
func test_a_frost_fist_hit_closes_the_roll_window_at_its_own_cost() -> void:
	var frost := auto_free((load("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn") as PackedScene).instantiate()) as Node2D
	var stats := load("res://resources/characters/guardians/frost_guardian/recall_roll.tres") as AbilityRecallStats
	var recall := _ivo.get_node(^"AbilityRecall") as AbilityRecallComponent
	_ivo.open_recall(stats, frost, frost.get_node(^"Hitbox") as Node2D)
	var before := _ivo.health.current_hp
	_hit(1, frost.get_node(^"Hitbox") as Node2D)
	assert_bool(recall.is_armed()).is_false()
	assert_int(_ivo.health.current_hp).is_equal(before - 1)

## A hit through Ivo's hurtbox with its i-frames spent, so each one counts.
func _hit(damage: int, source: Node2D) -> void:
	_ivo.hurtbox.set(&"_invulnerability_timer", 0.0)
	_ivo.hurtbox.receive_hit(damage, Vector2.ZERO, source)
