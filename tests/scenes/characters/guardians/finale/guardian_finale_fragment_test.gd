class_name GuardianFinaleFragmentTest extends GdUnitTestSuite

## STORY-42: the victory plays the final fragment, not the restoration; a recorded or skipped end hands over to the
## restoration under its black on the next frame, a drop plays nothing, a seen restoration is not replayed, and a refused
## play clears the black (architecture/story42-the-final-fragment, "Flow and seam").

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const MENTOR := preload("res://scenes/characters/guardians/mentor_guardian/mentor_guardian.tscn")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const LETTERBOX := preload("res://scenes/ui/letterbox/letterbox.tscn")
const ENGRAVING := preload("res://scenes/ui/engraving/engraving_view.tscn")
const FLOOR_Y := 30.0

var _world: Node2D
var _director: CutsceneDirector
var _fade: Fade
var _mentor: Guardian
var _finale: GuardianFinale
var _fragment: Cutscene
var _restoration: Cutscene
var _began: Array[StringName] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_began.clear()
	_world = auto_free(Node2D.new()) as Node2D
	add_child(_world)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = GroundCollision.COLLISION_LAYER | 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_world.add_child(floor_body)
	var ivo := IVO.instantiate() as Player
	ivo.position = Vector2(0, FLOOR_Y - 30.0)
	_world.add_child(ivo)
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	var letterbox := LETTERBOX.instantiate() as Letterbox
	layer.add_child(letterbox)
	var engraving := ENGRAVING.instantiate() as EngravingView
	layer.add_child(engraving)
	_fade = Fade.new()
	_fade.color = Color(0, 0, 0, 0)
	layer.add_child(_fade)
	_director = CutsceneDirector.new()
	_director.ivo = ivo
	_director.letterbox = letterbox
	_director.engraving = engraving
	_director.fade = _fade
	_world.add_child(_director)
	_director.scene_began.connect(ivo.begin_scene.unbind(1))
	_director.scene_ended.connect(ivo.end_scene.unbind(1))
	_director.scene_began.connect(func(scene: Cutscene) -> void: _began.append(scene.id))
	var black := CutsceneFade.new()
	black.seconds = 0.0
	_fragment = C.scene(&"final_fragment", [C.wait(0.2), black])
	_restoration = C.scene(&"world_restoration", [C.wait(0.3)])
	_mentor = MENTOR.instantiate() as Guardian
	_mentor.position = Vector2(300, FLOOR_Y)
	_mentor.cutscene_id = &"mentor"
	_mentor.stats = _mentor.stats.duplicate()
	_mentor.stats.finale = _mentor.stats.finale.duplicate()
	_mentor.stats.finale.final_fragment = _fragment
	_mentor.stats.finale.restoration_scene = _restoration
	_world.add_child(_mentor)
	_finale = _mentor.get_node(^"Finale") as GuardianFinale

func after_test() -> void:
	SaveSystem.begin("", true)
	var left := Music.playing()
	while left != null:
		Music.release(left, 0.0)
		left = Music.playing()

func _physics(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _until_ended(scene: Cutscene, limit: int) -> void:
	for i: int in limit:
		if _director.playing() != scene:
			return
		await get_tree().physics_frame

func test_the_victory_writes_the_world_and_plays_the_fragment_not_the_restoration() -> void:
	_finale.restored()
	assert_bool(SaveSystem.is_world_restored()).is_true()
	assert_object(_director.playing()).is_same(_fragment)
	assert_object(_director.host()).is_same(_mentor)
	assert_bool(_finale.is_performing()).is_false()

func test_a_recorded_end_plays_the_restoration_on_the_next_frame_under_the_black() -> void:
	_finale.restored()
	await _until_ended(_fragment, 120)
	assert_bool(SaveSystem.is_scene_seen(&"final_fragment")).is_true()
	assert_bool(_fade.is_opaque()).is_true()
	await get_tree().process_frame
	assert_object(_director.playing()).is_same(_restoration)
	assert_bool(_finale.is_performing()).is_true()
	assert_array(_began).is_equal([&"final_fragment", &"world_restoration"])

func test_a_skip_records_and_hands_over_too() -> void:
	_finale.restored()
	await get_tree().physics_frame
	_director.request_skip()
	await _physics(2)
	assert_bool(SaveSystem.is_scene_seen(&"final_fragment")).is_true()
	assert_object(_director.playing()).is_same(_restoration)

func test_a_dropped_fragment_plays_nothing() -> void:
	_finale.restored()
	await get_tree().physics_frame
	_director.interrupt()
	await _physics(3)
	assert_bool(SaveSystem.is_scene_seen(&"final_fragment")).is_false()
	assert_object(_director.playing()).is_null()
	assert_array(_began).is_equal([&"final_fragment"])

## An old save saw the restoration before STORY-42: the fragment's own end branch clears its cover, nothing replays.
func test_a_seen_restoration_is_not_replayed() -> void:
	SaveSystem.mark_scene_seen(&"world_restoration")
	_finale.restored()
	await _until_ended(_fragment, 120)
	await _physics(3)
	assert_object(_director.playing()).is_null()
	assert_array(_began).is_equal([&"final_fragment"])

func test_a_refused_restoration_clears_the_black() -> void:
	# Something else takes the director between the fragment's end and the deferred hand-over.
	var other := C.scene(&"other", [C.wait(5.0)])
	_director.scene_ended.connect(func(_scene: Cutscene) -> void: _director.play(other, _mentor), CONNECT_ONE_SHOT)
	_finale.restored()
	await _until_ended(_fragment, 120)
	await await_millis(700)
	assert_str(String(_director.playing().id)).is_equal("other")
	assert_bool(_fade.is_black()).is_false()

func test_without_a_fragment_the_victory_plays_the_restoration() -> void:
	_mentor.stats.finale.final_fragment = null
	_finale.restored()
	assert_object(_director.playing()).is_same(_restoration)

## Out of the tree mid-fragment (a quit, a death's swap): nothing is written and nothing plays after it.
func test_leaving_the_tree_writes_nothing() -> void:
	_finale.restored()
	await get_tree().physics_frame
	_world.remove_child(_director)
	_director.queue_free()
	await _physics(3)
	assert_bool(SaveSystem.is_scene_seen(&"final_fragment")).is_false()
	assert_bool(SaveSystem.is_scene_seen(&"world_restoration")).is_false()
