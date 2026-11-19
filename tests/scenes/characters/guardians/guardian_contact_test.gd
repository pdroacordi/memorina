class_name GuardianContactTest extends GdUnitTestSuite

## The body hurts on touch while a guardian fights, except during a move whose own box is its only hit: the Frost
## charge ("Só a investida", user, 2026-10-30; GRD-10).

const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")
const CHARGE := preload("res://resources/characters/guardians/frost_guardian/frost_charge.tres")
const SWIPE := preload("res://resources/characters/guardians/frost_guardian/frost_swipe.tres")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _guardian: Guardian
var _ivo: Player


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	_guardian = FROST.instantiate() as Guardian
	holder.add_child(_guardian)
	# Far off, so the AI picks nothing itself.
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(2000, 0)
	holder.add_child(ivo)
	_ivo = ivo
	_guardian.call(&"_on_player_entered")
	assert_int(_guardian.phase()).is_equal(GuardianFight.Phase.PRESSURE)

func after_test() -> void:
	SaveSystem.begin("", true)

func test_the_charge_hurts_only_with_its_own_box() -> void:
	var contact := _guardian.get_node(^"ContactHitbox") as Hitbox
	var ai := _guardian.get_node(^"AI") as GuardianAI
	await _frames(2)
	assert_bool(contact.monitoring).is_true()
	ai.call(&"_start_telegraph", CHARGE)
	await _frames(2)
	assert_bool(_guardian.body_hurts()).is_false()
	assert_bool(contact.monitoring).is_false()
	ai.cancel_attack()
	ai.call(&"_start_telegraph", SWIPE)
	await _frames(2)
	assert_bool(contact.monitoring).is_true()

func test_only_the_frost_charge_drops_body_contact() -> void:
	for path: String in ["bloom_guardian/bloom_lash", "bloom_guardian/bloom_burst", "bloom_guardian/bloom_pounce",
			"frost_guardian/frost_slam",
			"frost_guardian/frost_swipe"]:
		var attack := load("res://resources/characters/guardians/%s.tres" % path) as GuardianAttack
		assert_bool(attack.body_contact).override_failure_message(path).is_true()
	assert_bool(CHARGE.body_contact).is_false()

## A no-contact move that ends with its body over Ivo (a skid onto a rolled Ivo, a charge into a pinned one) spares
## him until he is out of the body or GuardianBodyContact.GRACE runs out
## (bugs/the-frost-charge-skids-onto-ivo-harmlessly-and-its-body-hurts-the-instant-its-recovery-ends).
func test_a_body_carried_onto_ivo_spares_him_until_he_is_out_of_it() -> void:
	var contact := _guardian.get_node(^"ContactHitbox") as Hitbox
	var ai := _guardian.get_node(^"AI") as GuardianAI
	var move := GuardianAttack.new()
	move.body_contact = false
	move.telegraph = 0.1
	move.duration = 0.2
	move.recovery = 0.1
	move.cooldown = 5.0
	ai.cancel_attack()
	ai.provoke()
	ai.call(&"_start_telegraph", move)
	await _frames(1)
	# Inside the body while the move spares him, as a skid or a charge into a wall leaves him.
	_ivo.teleport(_guardian.global_position)
	while ai.is_attacking():
		await _frames(1)
	await _frames(2)
	assert_bool(contact.monitoring).override_failure_message("hurt the instant the move ended").is_false()
	await _seconds(GuardianBodyContact.GRACE + 0.1)
	assert_bool(contact.monitoring).override_failure_message("the grace never ended").is_true()

## A lunge with no body contact stopped by a wall ahead spares Ivo with its box for the rest of the strike: a pinned
## Ivo who jumped it lands into nothing (playtests/2026-11-19-grd16-sun-fight). Before the wall it spares no one.
func test_a_lunge_stopped_by_a_wall_spares_ivo_for_the_rest_of_its_strike() -> void:
	var holder := _guardian.get_parent() as Node2D
	# Pinned: the wall is right behind him.
	_ivo.teleport(_guardian.global_position + Vector2(120.0, 0.0))
	holder.add_child(_solid(Vector2(0.0, 16.0), Vector2(2000.0, 32.0)))
	holder.add_child(_solid(Vector2(160.0, -100.0), Vector2(32.0, 200.0)))
	var ai := _guardian.get_node(^"AI") as GuardianAI
	var hitbox := _guardian.get_node(^"Hitbox") as Hitbox
	await _frames(4)
	var lunge := GuardianAttack.new()
	lunge.clip_index = 1
	lunge.body_contact = false
	lunge.telegraph = 0.1
	lunge.duration = CHARGE.duration
	lunge.lunge_speed = 300.0
	lunge.cooldown = 5.0
	ai.cancel_attack()
	ai.provoke()
	ai.call(&"_start_telegraph", lunge)
	while not ai.is_swinging():
		await _frames(1)
	await _frames(2)
	assert_object(hitbox.spared).override_failure_message("spared before the wall").is_null()
	var waited := 0
	while waited < 60 and not ai.blocked_ahead:
		await _frames(1)
		waited += 1
	assert_bool(ai.blocked_ahead).override_failure_message("never reached the wall").is_true()
	await _frames(2)
	assert_object(hitbox.spared).is_same(_ivo.hurtbox)
	while ai.is_swinging():
		await _frames(1)
	await _frames(1)
	assert_object(hitbox.spared).override_failure_message("still spared after the strike").is_null()

## A lunge that starts against the wall it faces has not run there: the box is not spared, so an Ivo between the body
## and the wall is still hit.
func test_a_lunge_begun_against_a_wall_spares_no_one() -> void:
	var holder := _guardian.get_parent() as Node2D
	holder.add_child(_solid(Vector2(0.0, 16.0), Vector2(2000.0, 32.0)))
	holder.add_child(_solid(Vector2(60.0, -100.0), Vector2(32.0, 200.0)))
	_ivo.teleport(_guardian.global_position + Vector2(20.0, 0.0))
	var ai := _guardian.get_node(^"AI") as GuardianAI
	var hitbox := _guardian.get_node(^"Hitbox") as Hitbox
	await _frames(4)
	var lunge := GuardianAttack.new()
	lunge.clip_index = 1
	lunge.body_contact = false
	lunge.telegraph = 0.1
	lunge.duration = CHARGE.duration
	lunge.lunge_speed = 300.0
	lunge.cooldown = 5.0
	ai.cancel_attack()
	ai.provoke()
	ai.call(&"_start_telegraph", lunge)
	var waited := 0
	while waited < 60 and not ai.is_swinging():
		await _frames(1)
		waited += 1
	await _frames(6)
	assert_bool(ai.blocked_ahead).override_failure_message("not against the wall").is_true()
	assert_object(hitbox.spared).is_null()

## A lunge with `lunge_past` stops that far beyond Ivo's live position and stays there for the rest of its strike.
func test_a_lunge_stops_its_past_beyond_ivo() -> void:
	var holder := _guardian.get_parent() as Node2D
	holder.add_child(_solid(Vector2(0.0, 16.0), Vector2(4000.0, 32.0)))
	_ivo.teleport(_guardian.global_position + Vector2(120.0, 0.0))
	var ai := _guardian.get_node(^"AI") as GuardianAI
	await _frames(4)
	var lunge := _lunge()
	lunge.lunge_past = 80.0
	ai.cancel_attack()
	ai.provoke()
	ai.call(&"_start_telegraph", lunge)
	while not ai.is_swinging():
		await _frames(1)
	# Untouched by the box, so no knockback moves him.
	(_guardian.get_node(^"Hitbox") as Hitbox).spared = _ivo.hurtbox
	while ai.is_swinging() and ai.swing_elapsed() < lunge.duration - 0.1:
		await _frames(1)
	var past := (_guardian.global_position.x - _ivo.global_position.x)
	assert_float(past).override_failure_message("ended %.0f px past Ivo" % past).is_between(80.0, 80.0 + 300.0 / 60.0 + 1.0)
	assert_float(_guardian.velocity.x).is_equal(0.0)

## Ivo's death stops a lunge where it is: the guardian does not slide on in its idle pose.
func test_a_lunge_cut_by_ivos_death_stops_at_once() -> void:
	var holder := _guardian.get_parent() as Node2D
	holder.add_child(_solid(Vector2(0.0, 16.0), Vector2(4000.0, 32.0)))
	_ivo.teleport(_guardian.global_position + Vector2(400.0, 0.0))
	var ai := _guardian.get_node(^"AI") as GuardianAI
	await _frames(4)
	var lunge := _lunge()
	ai.cancel_attack()
	ai.provoke()
	ai.call(&"_start_telegraph", lunge)
	while not ai.is_swinging() or ai.swing_elapsed() < 0.2:
		await _frames(1)
	_guardian.call(&"_on_player_died")
	var at := _guardian.global_position.x
	await _frames(10)
	assert_float(absf(_guardian.global_position.x - at)).override_failure_message("slid on after the death").is_less(2.0)

func _lunge() -> GuardianAttack:
	var lunge := GuardianAttack.new()
	lunge.clip_index = 1
	lunge.body_contact = false
	lunge.telegraph = 0.1
	lunge.duration = CHARGE.duration
	lunge.lunge_speed = 300.0
	lunge.cooldown = 5.0
	return lunge

## A static box of `size` centred at `centre`, on the world's solid layer.
func _solid(centre: Vector2, size: Vector2) -> StaticBody2D:
	var body := auto_free(StaticBody2D.new()) as StaticBody2D
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = centre
	return body

## The charge's recall is opened by the guardian at its lead before the fists, not by the recall's distance cue
## (bugs/a-prompt-roll-on-a-frost-charge-thrown-from-170-220-px-runs-out-of-grace-before-the-fists-arrive).
func test_the_charge_opens_its_recall_a_lead_before_the_fists() -> void:
	var ai := _guardian.get_node(^"AI") as GuardianAI
	var recall := _ivo.get_node(^"AbilityRecall") as AbilityRecallComponent
	_ivo.teleport(_guardian.global_position + Vector2(200.0, 0.0))
	await _frames(2)
	ai.cancel_attack()
	ai.provoke()
	ai.call(&"_start_telegraph", CHARGE)
	var opened_at := -1.0
	var distance := 0.0
	var waited := 0
	while waited < 180 and opened_at < 0.0:
		await _frames(1)
		waited += 1
		if recall.is_armed():
			opened_at = ai.swing_elapsed()
			distance = absf(_ivo.global_position.x - _guardian.global_position.x)
	assert_float(opened_at).override_failure_message("the recall never opened").is_greater(0.0)
	# One physics frame of the lunge between the check and the read.
	assert_float(CHARGE.seconds_to_blow(opened_at, distance)).is_less_equal(CHARGE.recall_lead + 1.0 / 60.0)
	assert_float(CHARGE.seconds_to_blow(opened_at, distance)).is_greater(CHARGE.recall_lead - 2.0 / 60.0)

func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout

## physics_frame is emitted before the nodes' own physics step, so one frame is not enough to see its write.
func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
