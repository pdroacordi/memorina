class_name GuardianContactTest extends GdUnitTestSuite

## The body hurts on touch while a guardian fights, except during a move whose own box is its only hit: the Frost
## charge ("Só a investida", user, 2026-10-30; GRD-10).

const FROST := preload("res://scenes/characters/guardians/frost_guardian/frost_guardian.tscn")
const CHARGE := preload("res://resources/characters/guardians/frost_guardian/frost_charge.tres")
const SWIPE := preload("res://resources/characters/guardians/frost_guardian/frost_swipe.tres")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _guardian: Guardian


func before_test() -> void:
	SaveSystem.begin("", true)
	var holder := auto_free(Node2D.new()) as Node2D
	add_child(holder)
	_guardian = FROST.instantiate() as Guardian
	holder.add_child(_guardian)
	# Far off, so the AI picks nothing itself.
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(2000, 0)
	holder.add_child(ivo)
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

## physics_frame is emitted before the nodes' own physics step, so one frame is not enough to see its write.
func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame
