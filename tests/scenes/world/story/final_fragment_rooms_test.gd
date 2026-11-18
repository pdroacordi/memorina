class_name FinalFragmentRoomsTest extends GdUnitTestSuite

## STORY-42 in the lantern: its triggers in order (the awakening, the fragment, the restoration) replay what a quit or a
## death missed, in order, and the fragment runs in the real contents, then hands over to the restoration
## (architecture/story42-the-final-fragment, "Source of truth and replay").

const LANTERN := preload("res://scenes/world/rooms/frost_edge/contents/lighthouse_top_contents.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const LETTERBOX := preload("res://scenes/ui/letterbox/letterbox.tscn")
const ENGRAVING := preload("res://scenes/ui/engraving/engraving_view.tscn")
const FRAGMENT := preload("res://resources/cutscene/story/final_fragment.tres")
const RESTORATION := preload("res://resources/cutscene/story/world_restoration.tres")
## Px: Ivo's origin above the floor when he stands at a mark.
const STAND_LIFT := 30.0

var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	TranslationServer.set_locale("en")
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.mark_dialogue_heard(&"mentor_gift")
	for guardian: Enums.Guardian in Enums.Guardian.values():
		SaveSystem.restore_guardian(guardian)
	SaveSystem.mark_scene_seen(&"mentor_wakes")

func after_test() -> void:
	SaveSystem.begin("", true)
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()

func _triggers(lantern: Node) -> Array[CutsceneTrigger]:
	var found: Array[CutsceneTrigger] = []
	for child: Node in lantern.get_node("Triggers").get_children():
		found.append(child as CutsceneTrigger)
	return found

## The trigger the director arms on entry: the first whose gates hold (CutsceneDirector.on_room_changed).
func _armed(lantern: Node) -> String:
	for trigger: CutsceneTrigger in _triggers(lantern):
		if trigger.wants(SaveSystem.player_data):
			return String(trigger.name)
	return ""

func test_the_lanterns_triggers_are_the_awakening_the_fragment_and_the_restoration() -> void:
	var lantern := auto_free(LANTERN.instantiate()) as Node
	var names: Array[String] = []
	for trigger: CutsceneTrigger in _triggers(lantern):
		names.append(String(trigger.name))
	assert_array(names).is_equal(["MentorWakes", "FinalFragment", "WorldRestoration"])
	var fragment := lantern.get_node("Triggers/FinalFragment") as CutsceneTrigger
	assert_object(fragment.cutscene).is_same(FRAGMENT)
	assert_object(fragment.zone).is_null()
	assert_float(fragment.delay).is_equal(0.0)

func test_each_entry_arms_the_first_scene_missed() -> void:
	var lantern := auto_free(LANTERN.instantiate()) as Node
	assert_str(_armed(lantern)).is_equal("")
	SaveSystem.restore_world()
	assert_str(_armed(lantern)).is_equal("FinalFragment")
	SaveSystem.mark_scene_seen(&"final_fragment")
	assert_str(_armed(lantern)).is_equal("WorldRestoration")
	SaveSystem.mark_scene_seen(&"world_restoration")
	assert_str(_armed(lantern)).is_equal("")

## The victory's commit runs before the fragment, so the save a quit or a death goes back to holds the world restored and
## neither scene seen.
func test_the_committed_save_arms_the_fragment_again() -> void:
	var lantern := auto_free(LANTERN.instantiate()) as Node
	SaveSystem.restore_world()
	SaveSystem.mark_scene_seen(&"final_fragment")
	SaveSystem.rewind()
	assert_bool(SaveSystem.is_world_restored()).is_true()
	assert_bool(SaveSystem.is_scene_seen(&"final_fragment")).is_false()
	assert_str(_armed(lantern)).is_equal("FinalFragment")

func test_the_fragment_runs_in_the_lantern_and_hands_over_to_the_restoration() -> void:
	SaveSystem.restore_world()
	var world := auto_free(Node2D.new()) as Node2D
	add_child(world)
	var layer := CanvasLayer.new()
	world.add_child(layer)
	var letterbox := LETTERBOX.instantiate() as Letterbox
	layer.add_child(letterbox)
	var engraving := ENGRAVING.instantiate() as EngravingView
	layer.add_child(engraving)
	var fade := Fade.new()
	fade.color = Color(0, 0, 0, 0)
	layer.add_child(fade)
	var director := CutsceneDirector.new()
	director.letterbox = letterbox
	director.engraving = engraving
	director.fade = fade
	world.add_child(director)
	var lantern := LANTERN.instantiate() as Node2D
	world.add_child(lantern)
	var ivo := IVO.instantiate() as Player
	ivo.position = (lantern.get_node("Marks/IvoStand") as Node2D).position - Vector2(0, STAND_LIFT)
	world.add_child(ivo)
	director.ivo = ivo
	director.scene_began.connect(ivo.begin_scene.unbind(1))
	director.scene_ended.connect(ivo.end_scene.unbind(1))
	var health := ivo.get_node(^"Health") as Health
	var hp := health.current_hp
	await get_tree().physics_frame
	assert_bool(director.play(FRAGMENT, lantern.get_node("Triggers/FinalFragment"))).is_true()
	await await_millis(4500)
	assert_object(director.playing()).is_same(FRAGMENT)
	assert_bool(engraving.visible).is_true()
	assert_bool(letterbox.is_open()).is_true()
	assert_str(engraving.caption_label().text).is_equal(tr(&"FINAL_FRAGMENT_1_1"))
	director.request_skip()
	await get_tree().physics_frame
	await get_tree().process_frame
	assert_bool(SaveSystem.is_scene_seen(&"final_fragment")).is_true()
	assert_object(director.playing()).is_same(RESTORATION)
	assert_object(director.host()).is_same(lantern.get_node("MentorGuardian"))
	assert_int(health.current_hp).is_equal(hp)
	director.request_skip()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(SaveSystem.is_scene_seen(&"world_restoration")).is_true()
	ivo.queue_free()
	await get_tree().physics_frame
