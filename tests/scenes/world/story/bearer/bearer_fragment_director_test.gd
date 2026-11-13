class_name BearerFragmentDirectorTest extends GdUnitTestSuite

## A world performance of a restored guardian's song arms its fragment; once the song's pulse is gone and every start
## gate holds, the call plays in the room, Ivo travels to the stage under the paper, the engraving plays, and he comes
## back under black to the same point and facing for the returning scene. A lesson, a fight, a talk, a scene, the map,
## a seat, the past and another acting pulse refuse it; the grace runs out; a dropped call stays due
## (architecture/story-04-bearer-fragments). Game's travel is stood in for by `_land`.

const B := preload("res://tests/resources/story/bearers/bearer_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const ENGRAVING := preload("res://scenes/ui/engraving/engraving_view.tscn")
const PULSE := preload("res://scenes/world/memory/color_pulse/color_pulse.tscn")
const FREEZE := preload("res://resources/songs/freeze.tres")
const ROOT := preload("res://resources/songs/root.tres")
const SIZE := Vector2(640, 384)
const FLOOR_Y := 288.0
const STAGE_AT := Vector2(1280, 0)

var _holder: Node2D
var _ivo: Player
var _cutscenes: CutsceneDirector
var _dialogue: DialogueDirector
var _director: BearerFragmentDirector
var _view: EngravingView
var _fragment: BearerFragment
var _present: Room
var _stage: Room
## [room, colour, seconds] per travel asked.
var _travels: Array = []
## Travels the stand-in Game refuses next.
var _refusals: int = 0


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	SaveSystem.restore_guardian(Enums.Guardian.FROST)
	_travels.clear()
	_refusals = 0
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(1000, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_present = _room("res://fixture/fixture_present.tscn", Vector2.ZERO)
	_stage = _room("res://fixture/bearer_stage.tscn", STAGE_AT)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(200, FLOOR_Y - 60.0)
	_holder.add_child(_ivo)
	var layer := CanvasLayer.new()
	_holder.add_child(layer)
	_view = ENGRAVING.instantiate() as EngravingView
	layer.add_child(_view)
	_fragment = B.fragment()
	_cutscenes = CutsceneDirector.new()
	_cutscenes.ivo = _ivo
	_cutscenes.engraving = _view
	_cutscenes.catalog = B.cutscenes([_fragment])
	_holder.add_child(_cutscenes)
	_cutscenes.scene_began.connect(_ivo.begin_scene.unbind(1))
	_cutscenes.scene_ended.connect(_ivo.end_scene.unbind(1))
	_dialogue = DialogueDirector.new()
	_dialogue.listener = _ivo
	_holder.add_child(_dialogue)
	_dialogue.talk_began.connect(_ivo.begin_talk)
	_dialogue.talk_ended.connect(_ivo.end_talk)
	_director = BearerFragmentDirector.new()
	_director.cutscenes = _cutscenes
	_director.ivo = _ivo
	_director.engraving = _view
	_director.start_grace = 0.5
	_holder.add_child(_director)
	# After _ready: the fixture's short engraving would fail the debug build's catalog assert.
	_director.catalog = B.catalog([_fragment])
	_director.travel_requested.connect(_on_travel_requested)
	_present.activate()
	_stage.activate()
	await get_tree().process_frame
	_director.on_room_changed(_present)
	_cutscenes.on_room_changed(_present)

func after_test() -> void:
	SaveSystem.begin("", true)

func _room(path: String, at: Vector2) -> Room:
	var root := Node2D.new()
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var room := Room.new()
	room.contents_scene = packed
	room.scene_file_path = path
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = SIZE * 0.5
	room.add_child(shape)
	room.position = at
	_holder.add_child(room)
	return room

## Stands in for Game.travel: lands Ivo a frame later, then room_changed and travelled, in Game's order.
func _on_travel_requested(point: TravelPoint, colour: Color, seconds: float) -> void:
	if _refusals > 0:
		_refusals -= 1
		_director.on_travelled(false)
		return
	_travels.append([point.room, colour, seconds])
	_land.call_deferred(point)

func _land(point: TravelPoint) -> void:
	point.place(_ivo)
	_director.on_room_changed(point.room)
	_cutscenes.on_room_changed(point.room)
	_director.on_travelled(true)

func _settle() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _until_playing(scene: Cutscene, frames: int = 90) -> bool:
	for i: int in frames:
		if _cutscenes.playing() == scene:
			return true
		await get_tree().physics_frame
	return _cutscenes.playing() == scene

func _until_idle(frames: int = 120) -> void:
	for i: int in frames:
		if not _cutscenes.is_playing() and _director.pending() == null:
			return
		await get_tree().physics_frame

func _visit_music() -> bool:
	var playing := Music.playing()
	return playing != null and playing.cue == _fragment.music and playing.layer == MusicRequest.Layer.SCENE

## A live pulse of `song` at Ivo, acting unless `acts` is false.
func _pulse(song: Song, acts: bool = true) -> ColorPulse:
	var pulse := PULSE.instantiate() as ColorPulse
	_holder.add_child(pulse)
	pulse.global_position = _ivo.global_position
	pulse.start(song, null, acts)
	return pulse

func test_a_lesson_never_arms_it() -> void:
	await _settle()
	assert_bool(_ivo.learn_song(FREEZE)).is_true()
	var performance := _ivo.get_node("SongPerformance") as SongPerformance
	for i: int in 600:
		if performance.is_playing():
			break
		await get_tree().physics_frame
	performance.stop()
	performance.finished.emit()
	await _frames(5)
	assert_object(_director.pending()).is_null()
	assert_bool(_cutscenes.is_playing()).is_false()

func test_a_guardian_not_restored_never_arms_it() -> void:
	SaveSystem.begin("", true)
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_object(_director.pending()).is_null()

func test_another_song_never_arms_it() -> void:
	await _settle()
	_ivo.song_performed.emit(ROOT)
	assert_object(_director.pending()).is_null()

func test_it_waits_out_the_songs_pulse_then_calls() -> void:
	await _settle()
	var pulse := _pulse(FREEZE)
	_ivo.song_performed.emit(FREEZE)
	await _frames(60)
	assert_object(_director.pending()).is_same(_fragment)
	assert_bool(_cutscenes.is_playing()).is_false()
	pulse.free()
	assert_bool(await _until_playing(_fragment.call)).is_true()

func test_a_guardians_pulse_does_not_hold_it() -> void:
	await _settle()
	var pulse := _pulse(ROOT, false)
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.call)).is_true()
	pulse.free()

func test_another_acting_pulse_refuses_it_until_the_grace_runs_out() -> void:
	await _settle()
	var pulse := _pulse(ROOT)
	_ivo.song_performed.emit(FREEZE)
	await await_millis(800)
	assert_object(_director.pending()).is_null()
	assert_bool(_cutscenes.is_playing()).is_false()
	pulse.free()

func test_a_drawn_memorina_refuses_it() -> void:
	await _settle()
	(_ivo.get_node("PlayerInput") as PlayerInput).draw_memorina_pressed.emit()
	for i: int in 30:
		await get_tree().physics_frame
		if _ivo.is_memorina_drawn():
			break
	assert_bool(_ivo.is_memorina_drawn()).is_true()
	_ivo.song_performed.emit(FREEZE)
	await await_millis(800)
	assert_object(_director.pending()).is_null()
	assert_bool(_cutscenes.is_playing()).is_false()

func test_a_talk_refuses_it() -> void:
	await _settle()
	assert_bool(_dialogue.start_dialogue(D.dialogue(&"chat", [D.line("SPEAKER_ELDER")]), _ivo.global_position)).is_true()
	_ivo.song_performed.emit(FREEZE)
	await await_millis(800)
	assert_object(_director.pending()).is_null()
	_dialogue.interrupt()

func test_a_scene_playing_refuses_it() -> void:
	await _settle()
	var other := B.C.scene(&"other", [B.C.wait(30.0)])
	assert_bool(_cutscenes.play(other, _present.contents())).is_true()
	_ivo.song_performed.emit(FREEZE)
	await await_millis(800)
	assert_object(_director.pending()).is_null()
	_cutscenes.interrupt()

func test_the_past_refuses_it() -> void:
	await _settle()
	_ivo.in_past = true
	_ivo.song_performed.emit(FREEZE)
	await await_millis(800)
	assert_object(_director.pending()).is_null()
	_ivo.in_past = false

func test_a_gate_that_opens_inside_the_grace_starts_it() -> void:
	_director.start_grace = 5.0
	await _settle()
	_ivo.in_past = true
	_ivo.song_performed.emit(FREEZE)
	await _frames(10)
	assert_bool(_cutscenes.is_playing()).is_false()
	_ivo.in_past = false
	assert_bool(await _until_playing(_fragment.call)).is_true()

func test_there_and_back_to_the_same_point_and_facing() -> void:
	await _settle()
	_ivo.face_towards(-1)
	var feet := _ivo.global_position
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.engraving)).is_true()
	assert_int(_travels.size()).is_equal(1)
	assert_object(_travels[0][0]).is_same(_stage)
	assert_that(_travels[0][1]).is_equal(_view.paper)
	assert_float(_travels[0][2]).is_equal(0.0)
	assert_vector(_ivo.global_position).is_equal_approx(STAGE_AT + _fragment.arrival, Vector2(0.5, 0.5))
	assert_bool(_director.is_visiting()).is_true()
	assert_bool(_visit_music()).is_true()
	assert_bool(await _until_playing(_fragment.returning)).is_true()
	assert_int(_travels.size()).is_equal(2)
	assert_object(_travels[1][0]).is_same(_present)
	assert_that(_travels[1][1]).is_equal(Color.BLACK)
	assert_float(_travels[1][2]).is_equal(0.0)
	assert_vector(_ivo.global_position).is_equal_approx(feet, Vector2(0.5, 0.5))
	assert_int(_ivo.facing).is_equal(-1)
	assert_bool(_visit_music()).is_true()
	await _until_idle()
	assert_object(_director.pending()).is_null()
	assert_bool(_visit_music()).is_false()
	assert_bool(SaveSystem.is_scene_seen(_fragment.engraving.id)).is_true()
	assert_bool(BearerSchedule.due(SaveSystem.player_data, _fragment)).is_false()
	assert_bool(_view.visible).is_false()

func test_a_seen_fragment_never_plays_again() -> void:
	SaveSystem.mark_scene_seen(_fragment.engraving.id)
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_object(_director.pending()).is_null()

func test_a_dropped_call_stays_due() -> void:
	_fragment.call.steps = [B.C.wait(30.0)]
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.call)).is_true()
	await _frames(3)
	_cutscenes.interrupt()
	await _frames(10)
	assert_int(_travels.size()).is_equal(0)
	assert_object(_director.pending()).is_null()
	assert_bool(BearerSchedule.due(SaveSystem.player_data, _fragment)).is_true()

## A call recorded on an earlier attempt and dropped now still stays in the room.
func test_a_dropped_call_after_a_recorded_one_stays_in_the_room() -> void:
	SaveSystem.mark_scene_seen(_fragment.call.id)
	_fragment.call.steps = [B.C.wait(30.0)]
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.call)).is_true()
	_cutscenes.interrupt()
	await _frames(10)
	assert_int(_travels.size()).is_equal(0)

func test_a_skipped_engraving_records_and_returns() -> void:
	(_fragment.engraving.steps[0] as CutsceneEngraving).frame.seconds = 30.0
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.engraving)).is_true()
	await _frames(2)
	assert_bool(_cutscenes.can_skip()).is_true()
	_cutscenes.request_skip()
	assert_bool(await _until_playing(_fragment.returning)).is_true()
	assert_bool(SaveSystem.is_scene_seen(_fragment.engraving.id)).is_true()
	assert_object(_travels[1][0]).is_same(_present)

func test_a_refused_travel_in_drops_it_and_stays_due() -> void:
	_refusals = 1
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	await _until_idle()
	assert_int(_travels.size()).is_equal(0)
	assert_object(_director.pending()).is_null()
	assert_bool(_visit_music()).is_false()
	assert_bool(BearerSchedule.due(SaveSystem.player_data, _fragment)).is_true()

func test_a_refused_travel_back_is_asked_again() -> void:
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.engraving)).is_true()
	_refusals = 1
	assert_bool(await _until_playing(_fragment.returning)).is_true()
	assert_object(_travels[1][0]).is_same(_present)

func test_a_flashback_travel_is_not_its_own() -> void:
	await _settle()
	_director.on_travelled(true)
	_director.on_travelled(false)
	assert_object(_director.pending()).is_null()
	assert_bool(_cutscenes.is_playing()).is_false()

## A quit or a death's SceneSwap mid-visit: nothing is recorded, so the fragment is still due at the bench.
func test_leaving_the_tree_mid_visit_writes_nothing() -> void:
	(_fragment.engraving.steps[0] as CutsceneEngraving).frame.seconds = 30.0
	await _settle()
	_ivo.song_performed.emit(FREEZE)
	assert_bool(await _until_playing(_fragment.engraving)).is_true()
	var seen := SaveSystem.player_data.scenes_seen.duplicate()
	_holder.remove_child(_director)
	assert_object(_director.pending()).is_null()
	assert_object(_director.return_point()).is_null()
	assert_array(SaveSystem.player_data.scenes_seen).is_equal(seen)
	assert_bool(BearerSchedule.due(SaveSystem.player_data, _fragment)).is_true()
	_director.free()
	_cutscenes.interrupt()
	await _frames(5)
	assert_bool(_visit_music()).is_false()

## game.tscn holds the director, wired to Game's travel and room changes and to the engraving view.
func test_the_game_wires_it() -> void:
	var state := (load("res://scenes/world/game.tscn") as PackedScene).get_state()
	var wired: Array[String] = []
	for i: int in state.get_connection_count():
		wired.append("%s>%s.%s" % [state.get_connection_signal(i), state.get_connection_target(i), state.get_connection_method(i)])
	assert_array(wired).contains([
		"travel_requested>..travel",
		"travelled>World/BearerFragmentDirector.on_travelled",
		"room_changed>World/BearerFragmentDirector.on_room_changed",
	])
	var found := false
	for i: int in state.get_node_count():
		if state.get_node_name(i) == &"BearerFragmentDirector":
			found = true
			var props := {}
			for p: int in state.get_node_property_count(i):
				props[state.get_node_property_name(i, p)] = state.get_node_property_value(i, p)
			for key: StringName in [&"catalog", &"cutscenes", &"flashbacks", &"ivo", &"engraving"]:
				assert_bool(props.has(key)).override_failure_message(String(key)).is_true()
	assert_bool(found).is_true()
