class_name CutsceneDirectorTest extends GdUnitTestSuite

## The director plays one scene at a time: its end records SCENE_SEEN and uncovers the staging on its new rest in the
## same frame, a skip lands and records, a drop restores the rest shown before unrecorded, a director swapped out writes
## nothing, and a hold stops its clock.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const DAUGHTER := preload("res://scenes/characters/story_actor/daughter/daughter_actor.tscn")
const LETTERBOX := preload("res://scenes/ui/letterbox/letterbox.tscn")
const FLOOR_Y := 288.0

var _world: Node2D
var _contents: Node2D
var _staging: FactStaging
var _actor: StoryActor
var _host: Node
var _ivo: Player
var _director: CutsceneDirector
var _letterbox: Letterbox
## What scene_ended saw, the frame it was emitted.
var _at_end: Dictionary = {}


func before_test() -> void:
	SaveSystem.begin("", true)
	_at_end = {}
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
	_contents = _build_contents()
	_world.add_child(_contents)
	_staging = _contents.get_node("Daughter") as FactStaging
	_actor = _contents.get_node("Cast/Daughter") as StoryActor
	_host = _contents.get_node("Host")
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(200, FLOOR_Y - 60.0)
	_world.add_child(_ivo)
	var layer := CanvasLayer.new()
	_world.add_child(layer)
	_letterbox = LETTERBOX.instantiate() as Letterbox
	layer.add_child(_letterbox)
	_director = CutsceneDirector.new()
	_director.ivo = _ivo
	_director.letterbox = _letterbox
	_world.add_child(_director)
	_director.scene_began.connect(_ivo.begin_scene.unbind(1))
	_director.scene_ended.connect(_ivo.end_scene.unbind(1))
	_director.ivo_driven.connect(_ivo.drive)
	_director.scene_ended.connect(_on_scene_ended)

func after_test() -> void:
	SaveSystem.begin("", true)

## A contents scene as the game builds one: the staging (Standing, or InBedTurned once the scene is seen), its actor
## under Cast, a mark and the host, all owned by the root.
func _build_contents() -> Node2D:
	var root := Node2D.new()
	root.name = "Contents"
	var staging := FactStaging.new()
	staging.name = "Daughter"
	var seen := FactStage.new()
	seen.when = [D.fact(SaveFact.Kind.SCENE_SEEN, &"to_bed")]
	seen.show = &"InBedTurned"
	var rest := FactStage.new()
	rest.show = &"Standing"
	staging.stages = [seen, rest]
	for child: String in ["Standing", "InBedTurned"]:
		var sprite := Sprite2D.new()
		sprite.name = child
		sprite.position = Vector2(90 if child == "Standing" else 58, FLOOR_Y)
		staging.add_child(sprite)
	root.add_child(staging)
	var cast := Node2D.new()
	cast.name = "Cast"
	root.add_child(cast)
	var actor := DAUGHTER.instantiate() as StoryActor
	actor.stands_for = NodePath("../../Daughter")
	cast.add_child(actor)
	var mark := CutsceneMark.new()
	mark.name = "BedEdge"
	mark.mark_id = &"bed_edge"
	mark.position = Vector2(58, FLOOR_Y)
	root.add_child(mark)
	var host := Node.new()
	host.name = "Host"
	root.add_child(host)
	for node: Node in [staging, cast, actor, mark, host]:
		node.owner = root
	return root

func _on_scene_ended(_scene: Cutscene) -> void:
	_at_end = {
		"seen": SaveSystem.is_scene_seen(&"to_bed"),
		"staging_visible": _staging.visible,
		"shown": String(_staging.shown().name) if _staging.shown() != null else "",
		"actor_visible": _actor.visible,
	}

func _scene(steps: Array[CutsceneStep]) -> Cutscene:
	return C.scene(&"to_bed", steps)

func _walk_to_bed() -> CutsceneWalk:
	var walk := C.walk(&"daughter", 0.0, 1.0)
	walk.mark = &"bed_edge"
	return walk

func _settle() -> void:
	for i: int in 30:
		await get_tree().physics_frame
		if _ivo.is_on_floor():
			return

func _until_ended(frames: int) -> void:
	for i: int in frames:
		await get_tree().physics_frame
		if not _director.is_playing():
			return

func test_the_end_records_then_uncovers_in_one_frame() -> void:
	await _settle()
	assert_bool(_director.play(_scene([_walk_to_bed(), C.wait(0.1)]), _host)).is_true()
	assert_bool(_ivo.is_in_scene()).is_true()
	await get_tree().physics_frame
	assert_bool(_actor.visible).is_true()
	assert_bool(_staging.visible).is_false()
	await _until_ended(300)
	assert_bool(_director.is_playing()).is_false()
	assert_dict(_at_end).is_equal({"seen": true, "staging_visible": true, "shown": "InBedTurned", "actor_visible": false})
	assert_bool(_ivo.is_in_scene()).is_false()

func test_a_skip_lands_the_end_and_records() -> void:
	await _settle()
	_director.play(_scene([_walk_to_bed(), C.wait(30.0)]), _host)
	await get_tree().physics_frame
	assert_bool(_director.can_skip()).is_true()
	_director.request_skip()
	await get_tree().physics_frame
	assert_bool(_director.is_playing()).is_false()
	assert_dict(_at_end).is_equal({"seen": true, "staging_visible": true, "shown": "InBedTurned", "actor_visible": false})

func test_an_unskippable_scene_offers_no_skip() -> void:
	var scene := _scene([C.wait(30.0)])
	scene.skippable = false
	_director.play(scene, _host)
	assert_bool(_director.can_skip()).is_false()
	_director.interrupt()

func test_a_drop_restores_the_rest_unrecorded() -> void:
	await _settle()
	_director.play(_scene([_walk_to_bed(), C.wait(30.0)]), _host)
	for i: int in 10:
		await get_tree().physics_frame
	_director.interrupt()
	assert_bool(SaveSystem.is_scene_seen(&"to_bed")).is_false()
	assert_dict(_at_end).is_equal({"seen": false, "staging_visible": true, "shown": "Standing", "actor_visible": false})

func test_only_one_scene_plays_at_a_time() -> void:
	assert_bool(_director.play(_scene([C.wait(30.0)]), _host)).is_true()
	assert_bool(_director.play(_scene([C.wait(1.0)]), _host)).is_false()
	_director.interrupt()

func test_bars_close_when_the_scene_ends() -> void:
	var bars := CutsceneBars.new()
	bars.seconds = 0.0
	_director.play(_scene([bars, C.wait(30.0)]), _host)
	await get_tree().physics_frame
	assert_bool(_letterbox.is_open()).is_true()
	_director.interrupt()
	assert_bool(_letterbox.is_open()).is_false()

## A death's SceneSwap frees the world with the director in it: the scene writes nothing.
func test_a_director_out_of_the_tree_writes_nothing() -> void:
	_director.play(_scene([C.wait(0.05)]), _host)
	_world.remove_child(_director)
	assert_bool(_director.is_playing()).is_false()
	assert_bool(SaveSystem.is_scene_seen(&"to_bed")).is_false()
	_director.free()

## Pausable: a menu's hold stops the scene's clock (gotchas/gdunit-await-millis-never-resumes-while-the-tree-is-paused).
func test_a_hold_stops_the_clock() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_director.play(_scene([C.wait(0.2)]), _host)
	freeze.hold()
	await get_tree().create_timer(0.5, true, false, true).timeout
	assert_bool(_director.is_playing()).is_true()
	freeze.release()
	await _until_ended(60)
	assert_bool(_director.is_playing()).is_false()
	remove_child(freeze)
	freeze.free()
