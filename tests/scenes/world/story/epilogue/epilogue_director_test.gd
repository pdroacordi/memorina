class_name EpilogueDirectorTest extends GdUnitTestSuite

## The ending's order (architecture/story-07-epilogue): the epilogue, then the credits on the same host, then a rest on the
## stone's bench; a skipped epilogue still rolls the credits, a dropped one or a dropped credits asks no rest, a credits
## played again (from the stone) rests, and a world swapped out mid-ending writes nothing.

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

var _world: Node2D
var _host: Node
var _cutscenes: CutsceneDirector
var _director: EpilogueDirector
var _rests: Array[StringName] = []
var _events: Array[String] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	_rests.clear()
	_events.clear()
	_world = auto_free(Node2D.new()) as Node2D
	add_child(_world)
	var contents := Node2D.new()
	contents.name = "Contents"
	_host = Node.new()
	_host.name = "Host"
	contents.add_child(_host)
	_host.owner = contents
	_world.add_child(contents)
	var ivo := IVO.instantiate() as Player
	_world.add_child(ivo)
	_cutscenes = CutsceneDirector.new()
	_cutscenes.ivo = ivo
	_world.add_child(_cutscenes)
	_cutscenes.scene_began.connect(ivo.begin_scene.unbind(1))
	_cutscenes.scene_ended.connect(ivo.end_scene.unbind(1))
	_director = EpilogueDirector.new()
	_director.epilogue = C.scene(EpilogueSchedule.EPILOGUE_ID, [C.wait(0.1)])
	_director.credits = C.scene(EpilogueSchedule.CREDITS_ID, [C.wait(0.1)])
	_director.cutscenes = _cutscenes
	_world.add_child(_director)
	_director.rest_requested.connect(func(id: StringName) -> void: _rests.append(id))
	_director.ending_began.connect(func() -> void: _events.append("began"))
	_director.ending_ended.connect(func() -> void: _events.append("ended"))
	_cutscenes.scene_began.connect(func(scene: Cutscene) -> void: _events.append("play:%s:%s" % [scene.id, _cutscenes.host().name]))

func after_test() -> void:
	SaveSystem.begin("", true)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func test_the_epilogue_rolls_the_credits_on_its_host_then_asks_a_rest_on_the_stone() -> void:
	assert_bool(_cutscenes.play(_director.epilogue, _host)).is_true()
	await _frames(40)
	assert_array(_events).is_equal(["began", "play:epilogue:Host", "play:credits:Host", "ended"])
	assert_array(_rests).is_equal([&"garden_stone"])
	assert_bool(SaveSystem.is_scene_seen(EpilogueSchedule.CREDITS_ID)).is_true()
	assert_bool(_director.is_in_ending()).is_false()

func test_a_skipped_epilogue_still_rolls_the_credits() -> void:
	_director.epilogue.steps = [C.wait(30.0)]
	_cutscenes.play(_director.epilogue, _host)
	await _frames(2)
	_cutscenes.request_skip()
	await _frames(40)
	assert_bool(SaveSystem.is_scene_seen(EpilogueSchedule.EPILOGUE_ID)).is_true()
	assert_array(_rests).is_equal([&"garden_stone"])

func test_a_dropped_epilogue_rolls_nothing_and_ends_the_ending() -> void:
	_director.epilogue.steps = [C.wait(30.0)]
	_cutscenes.play(_director.epilogue, _host)
	await _frames(2)
	_cutscenes.interrupt()
	await _frames(10)
	assert_array(_events).is_equal(["began", "play:epilogue:Host", "ended"])
	assert_array(_rests).is_empty()
	assert_bool(SaveSystem.is_scene_seen(EpilogueSchedule.EPILOGUE_ID)).is_false()

## The stone plays the credits again while the epilogue is seen and the credits are not (its CreditsSeat).
func test_a_dropped_credits_asks_no_rest_and_a_credits_played_again_does() -> void:
	_director.credits.steps = [C.wait(30.0)]
	_cutscenes.play(_director.epilogue, _host)
	await _frames(20)
	assert_object(_cutscenes.playing()).is_same(_director.credits)
	_cutscenes.interrupt()
	await _frames(2)
	assert_array(_rests).is_empty()
	_director.credits.steps = [C.wait(0.1)]
	_cutscenes.play(_director.credits, _host)
	await _frames(20)
	assert_array(_rests).is_equal([&"garden_stone"])
	assert_array(_events).is_equal(["began", "play:epilogue:Host", "play:credits:Host", "ended", "began",
			"play:credits:Host", "ended"])

func test_a_world_swapped_out_mid_ending_writes_nothing() -> void:
	_director.epilogue.steps = [C.wait(30.0)]
	_cutscenes.play(_director.epilogue, _host)
	await _frames(2)
	remove_child(_world)
	await _frames(40)
	assert_array(_rests).is_empty()
	assert_bool(SaveSystem.is_scene_seen(EpilogueSchedule.EPILOGUE_ID)).is_false()
	assert_bool(_director.is_in_ending()).is_false()
	add_child(_world)

func test_other_scenes_are_not_the_ending() -> void:
	_cutscenes.play(C.scene(&"elsewhere", [C.wait(0.1)]), _host)
	await _frames(20)
	assert_array(_events).is_equal(["play:elsewhere:Host"])
	assert_array(_rests).is_empty()

## game.tscn holds the director, wired to the cutscenes, Game's rest and the life notes.
func test_the_game_wires_the_ending() -> void:
	var state := (load("res://scenes/world/game.tscn") as PackedScene).get_state()
	var wired: Array[String] = []
	for i: int in state.get_connection_count():
		wired.append("%s>%s.%s" % [state.get_connection_signal(i), state.get_connection_target(i), state.get_connection_method(i)])
	assert_array(wired).contains([
		"rest_requested>..rest_at_bench",
		"ending_began>CanvasLayer/LifeHud.on_ending_began",
		"ending_ended>CanvasLayer/LifeHud.on_ending_ended",
	])
	var found := false
	for node: int in state.get_node_count():
		if state.get_node_name(node) != &"EpilogueDirector":
			continue
		found = true
		var props := {}
		for i: int in state.get_node_property_count(node):
			props[state.get_node_property_name(node, i)] = state.get_node_property_value(node, i)
		assert_str(String(props[&"cutscenes"])).is_equal("../CutsceneDirector")
		assert_str(String(props[&"fade"])).is_equal("../../CanvasLayer/Fade")
		assert_str(String((props[&"epilogue"] as Cutscene).id)).is_equal(String(EpilogueSchedule.EPILOGUE_ID))
		assert_str(String((props[&"credits"] as Cutscene).id)).is_equal(String(EpilogueSchedule.CREDITS_ID))
	assert_bool(found).is_true()

## The credits end on black: the rest lands under it, then the director clears it (a recorded end never does).
func test_the_black_the_credits_end_on_clears_after_the_rest() -> void:
	var fade := Fade.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_world.add_child(fade)
	_cutscenes.fade = fade
	_director.fade = fade
	var cover := CutsceneFade.new()
	cover.seconds = 0.0
	var black_at_rest: Array[bool] = []
	_director.rest_requested.connect(func(_id: StringName) -> void: black_at_rest.append(fade.is_black()))
	_director.credits.steps = [C.wait(0.1), cover]
	_cutscenes.play(_director.credits, _host)
	await _frames(20)
	assert_array(black_at_rest).is_equal([true])
	await get_tree().create_timer(EpilogueDirector.CLEAR_SECONDS + 0.3).timeout
	assert_bool(fade.is_black()).is_false()
