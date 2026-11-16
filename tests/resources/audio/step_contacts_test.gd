class_name StepContactsTest extends GdUnitTestSuite

## Ivo's footfalls name only PlayerAnimationResolver clips, each a loop with contacts inside its length.

const FOOTFALLS := preload("res://resources/audio/sfx/ivo/ivo_footfalls.tres")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")


func _resolver_clips() -> Array[StringName]:
	var clips: Array[StringName] = []
	var constants := (PlayerAnimationResolver as Script).get_script_constant_map()
	for value: Variant in constants.values():
		if value is StringName:
			clips.append(value)
	return clips

func test_every_clip_is_a_resolver_const() -> void:
	var clips := _resolver_clips()
	assert_bool(FOOTFALLS.contacts.is_empty()).is_false()
	for clip: StringName in FOOTFALLS.contacts:
		assert_bool(clips.has(clip)).override_failure_message("%s is not a resolver clip" % clip).is_true()

func test_every_contact_lies_inside_its_looping_clip() -> void:
	var ivo := auto_free(IVO.instantiate()) as Player
	var player := ivo.get_node("AnimationPlayer") as AnimationPlayer
	var machine := (ivo.get_node("AnimationTree") as AnimationTree).tree_root as AnimationNodeStateMachine
	for clip: StringName in FOOTFALLS.contacts:
		assert_bool(machine.has_node(clip)).override_failure_message("%s is no state" % clip).is_true()
		var animation := player.get_animation((machine.get_node(clip) as AnimationNodeAnimation).animation)
		assert_object(animation).override_failure_message("%s has no animation" % clip).is_not_null()
		assert_int(animation.loop_mode).is_not_equal(Animation.LOOP_NONE)
		for contact: float in FOOTFALLS.contacts_of(clip):
			assert_float(contact).is_greater_equal(0.0)
			assert_float(contact).is_less(animation.length)

func test_a_clip_without_contacts_is_empty() -> void:
	assert_int(FOOTFALLS.contacts_of(PlayerAnimationResolver.IDLE).size()).is_equal(0)
