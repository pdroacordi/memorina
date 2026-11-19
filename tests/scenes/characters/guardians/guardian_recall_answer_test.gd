class_name GuardianRecallAnswerTest extends GdUnitTestSuite

## An answered recall is never punished by the move that asked for it, however early the answer came
## (bugs/a-prompt-answer-to-the-leaf-gust-recall-slides-ivo-back-into-its-floor-blow); and a guardian stops where it
## stands when Ivo dies (playtests/2026-11-18-grd15-leaf-feel: a claw string thrown during the death fade).

const AUTUMN := preload("res://scenes/characters/guardians/autumn_guardian/autumn_guardian.tscn")
const GUST := preload("res://resources/characters/guardians/autumn_guardian/autumn_gust.tres")
const SWEEP := preload("res://resources/characters/guardians/autumn_guardian/autumn_sweep.tres")
const BLADES := preload("res://resources/characters/guardians/autumn_guardian/autumn_leaf_blades.tres")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _guardian: Guardian
var _ivo: Player
var _ai: GuardianAI
var _hitbox: Hitbox


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	# A floor, or the guardian falls out of its own sight in a second.
	var floor_body := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000.0, 40.0)
	floor_shape.shape = rect
	floor_shape.position = Vector2(0.0, 20.0)
	floor_body.add_child(floor_shape)
	holder.add_child(floor_body)
	_guardian = AUTUMN.instantiate() as Guardian
	holder.add_child(_guardian)
	# In sight, out of every reach but the gust's, and held still: no floor here, and the gust would carry him off.
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(300, 0)
	holder.add_child(ivo)
	ivo.set_physics_process(false)
	_ivo = ivo
	_guardian.call(&"_on_player_entered")
	_ai = _guardian.get_node(^"AI") as GuardianAI
	_hitbox = _guardian.get_node(^"Hitbox") as Hitbox

func after_test() -> void:
	SaveSystem.begin("", true)

## Pressed 0.06, 0.36 or 1.8 s into the strike, the answer spares Ivo from the gust's own box for the rest of the
## move, and only for it.
func test_an_answered_recall_is_spared_the_teaching_blow() -> void:
	# Its push off: there is no wall here, and Ivo would be carried out of sight.
	var gust := GUST.duplicate() as GuardianAttack
	gust.push_speed = 0.0
	_ai.attacks = [gust]
	for pressed: float in [0.06, 0.36, 1.8]:
		_ai.cancel_attack()
		_ai.call(&"_start_telegraph", gust)
		await _until(func() -> bool: return _ai.is_swinging() and _ai.swing_elapsed() >= pressed)
		assert_bool(_ai.is_swinging()).override_failure_message("pressed at %.2f" % pressed).is_true()
		_ivo.skill_recalled.emit(Enums.PlayerSkill.WALL_CLIMB)
		assert_object(_hitbox.spared).override_failure_message("pressed at %.2f" % pressed).is_same(_ivo.hurtbox)
		var hp := _ivo.health.current_hp
		_hitbox.call(&"_hit", _ivo.hurtbox)
		assert_int(_ivo.health.current_hp).override_failure_message("hit after pressing at %.2f" % pressed).is_equal(hp)
		await _until(func() -> bool: return not _ai.is_swinging())
		assert_object(_hitbox.spared).override_failure_message("still spared after the gust").is_null()
		SaveSystem.begin("", true)
		SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)

## Outside a recall move nothing is spared: a skill learned elsewhere does not shield Ivo from a sweep.
func test_only_the_teaching_move_spares() -> void:
	_ai.call(&"_start_telegraph", SWEEP)
	await _seconds(SWEEP.telegraph + 0.1)
	_ivo.skill_recalled.emit(Enums.PlayerSkill.WALL_CLIMB)
	assert_object(_hitbox.spared).is_null()

func test_the_guardian_stops_when_ivo_dies() -> void:
	_ai.call(&"_start_telegraph", BLADES)
	await _seconds(BLADES.telegraph + 0.3)
	var spawner := _guardian.get_node(^"Spawner") as GuardianSpawner
	assert_int(spawner.get_child_count()).is_greater(0)
	_ivo.died.emit()
	await _frames(3)
	assert_bool(_ai.is_attacking()).is_false()
	assert_bool(_ai.active).is_false()
	await _frames(3)
	assert_int(spawner.get_child_count()).is_equal(0)

## Dead in PRESSURE, the body's contact no longer hurts the corpse (a hit-stop and a shake each time its i-frames lapse).
func test_a_dead_ivo_is_not_touched_by_the_body() -> void:
	var contact := _guardian.get_node(^"ContactHitbox") as Hitbox
	await _frames(2)
	assert_bool(contact.monitoring).is_true()
	_ivo.died.emit()
	await _frames(2)
	assert_bool(contact.monitoring).is_false()

## Dead during a lucidity (the finale's mixed note can kill him there), no clock advances: no leap, no call staged, no
## window timed out into a relapse, the AI never on again (bugs/a-guardian-stopped-by-ivos-death-outside-the-pressure-fights-again-in-the-death-fade).
func test_a_death_in_a_lucidity_stops_every_clock() -> void:
	_guardian.fight().call(&"_transition", GuardianFight.Phase.LUCIDITY)
	_guardian.call(&"_open_lucidity")
	_ivo.died.emit()
	for i: int in 360:
		await get_tree().physics_frame
		assert_bool(_ai.active).is_false()
		assert_bool(_guardian.is_leaping()).is_false()
	assert_int(_guardian.phase()).is_equal(GuardianFight.Phase.LUCIDITY)
	_guardian.fight().open_window(0.5)
	await _frames(120)
	assert_int(_guardian.phase()).override_failure_message("the window ran on a dead Ivo").is_equal(GuardianFight.Phase.LUCIDITY)
	assert_bool(_ai.active).is_false()

## Dead before the opening hold ends, or as a relapse hands back to the pressure, the AI stays off.
func test_a_death_keeps_the_ai_off_through_the_opening_and_the_relapse() -> void:
	_ivo.died.emit()
	_guardian.call(&"_on_opening_ended")
	assert_bool(_ai.active).is_false()
	_guardian.call(&"_on_phase_changed", GuardianFight.Phase.RELAPSE, GuardianFight.Phase.PRESSURE)
	assert_bool(_ai.active).is_false()
	_guardian.call(&"_close_call", true)
	assert_bool(_ai.active).is_false()

## Waits on the scaled clock's own state (a recall slows the world), at most 3000 physics frames.
func _until(condition: Callable) -> void:
	for i: int in 3000:
		if condition.call():
			return
		await get_tree().physics_frame

func _seconds(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		await get_tree().physics_frame
		left -= 1.0 / Engine.physics_ticks_per_second

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
