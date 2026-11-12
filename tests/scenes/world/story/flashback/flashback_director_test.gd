class_name FlashbackDirectorTest extends GdUnitTestSuite

## A recorded crossing takes Ivo to the past under white, plays the opening there, and the recorded leaving brings him back
## under a 0 s black to the same step and facing, where the returning scene plays. A dropped crossing never travels, an
## open talk is waited out (at the crossing and at the leaving), the visit's music plays from the crossing's end to the
## leaving's and silence from there to the returning's end, and a director leaving the
## tree mid-visit writes nothing (architecture/story-05-playable-flashbacks). Game's travel is stood in for by `_land`.

const F := preload("res://tests/resources/story/flashbacks/flashback_fixture.gd")
const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const LETTERBOX := preload("res://scenes/ui/letterbox/letterbox.tscn")
const SIZE := Vector2(640, 384)
const FLOOR_Y := 288.0
const PAST_AT := Vector2(1280, 0)

var _holder: Node2D
var _ivo: Player
var _cutscenes: CutsceneDirector
var _dialogue: DialogueDirector
var _director: FlashbackDirector
var _letterbox: Letterbox
var _flashback: Flashback
var _present: Room
var _past: Room
## [room, colour, seconds] per travel asked.
var _travels: Array = []


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_travels.clear()
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
	_past = _room("res://fixture/fixture_past.tscn", PAST_AT)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(200, FLOOR_Y - 60.0)
	_holder.add_child(_ivo)
	_letterbox = LETTERBOX.instantiate() as Letterbox
	_holder.add_child(_letterbox)
	_flashback = F.flashback(1)
	_cutscenes = CutsceneDirector.new()
	_cutscenes.ivo = _ivo
	_cutscenes.catalog = F.cutscenes([_flashback])
	_holder.add_child(_cutscenes)
	_cutscenes.scene_began.connect(_ivo.begin_scene.unbind(1))
	_cutscenes.scene_ended.connect(_ivo.end_scene.unbind(1))
	_dialogue = DialogueDirector.new()
	_dialogue.listener = _ivo
	_holder.add_child(_dialogue)
	_director = FlashbackDirector.new()
	_director.catalog = F.catalog([_flashback])
	_director.cutscenes = _cutscenes
	_director.dialogue = _dialogue
	_director.ivo = _ivo
	_director.letterbox = _letterbox
	_holder.add_child(_director)
	_director.travel_requested.connect(_on_travel_requested)
	_present.activate()
	_past.activate()
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

## Waits up to `frames` physics frames for `scene` to play; true when it does.
func _until_playing(scene: Cutscene, frames: int = 60) -> bool:
	for i: int in frames:
		if _cutscenes.playing() == scene:
			return true
		await get_tree().physics_frame
	return _cutscenes.playing() == scene

func _until_idle(frames: int = 60) -> void:
	for i: int in frames:
		if not _cutscenes.is_playing():
			return
		await get_tree().physics_frame

func _visit_music() -> bool:
	var playing := Music.playing()
	return playing != null and playing.cue == _flashback.music and playing.layer == MusicRequest.Layer.SCENE

func _silence_holds() -> bool:
	var playing := Music.playing()
	return playing != null and playing.cue.id == FlashbackDirector.SILENCE and playing.layer == MusicRequest.Layer.SCENE

## Plays the crossing in the present and waits for the opening in the past to end.
func _cross() -> void:
	assert_bool(_cutscenes.play(_flashback.crossing, _present.contents())).is_true()
	assert_bool(await _until_playing(_flashback.opening)).is_true()
	await _until_idle()

## Flashback 4 cuts to night: the travel in is covered in the flashback's own colour.
func test_the_travel_in_takes_the_flashbacks_colour() -> void:
	_flashback.entry_colour = Color.BLACK
	await _settle()
	await _cross()
	assert_that(_travels[0][1]).is_equal(Color.BLACK)

func test_there_and_back_to_the_same_step_and_facing() -> void:
	await _settle()
	_ivo.face_towards(-1)
	var feet := _ivo.global_position
	await _cross()
	assert_int(_travels.size()).is_equal(1)
	assert_object(_travels[0][0]).is_same(_past)
	assert_that(_travels[0][1]).is_equal(Color.WHITE)
	assert_float(_travels[0][2]).is_equal(_flashback.entry_fade)
	assert_float(_letterbox.rest_thickness).is_equal(_flashback.bars_thin)
	assert_int(_ivo.facing).is_equal(1)
	assert_bool(_past.get_bounds().has_point(_ivo.global_position)).is_true()
	# Free play: he walks off in the past before the leaving scene.
	_ivo.teleport(PAST_AT + Vector2(400, FLOOR_Y))
	assert_bool(_cutscenes.play(_flashback.leaving, _past.contents())).is_true()
	assert_bool(await _until_playing(_flashback.returning)).is_true()
	assert_int(_travels.size()).is_equal(2)
	assert_object(_travels[1][0]).is_same(_present)
	assert_that(_travels[1][1]).is_equal(Color.BLACK)
	assert_float(_travels[1][2]).is_equal(0.0)
	assert_vector(_ivo.global_position).is_equal_approx(feet, Vector2(0.5, 0.5))
	assert_int(_ivo.facing).is_equal(-1)
	assert_float(_letterbox.rest_thickness).is_equal(0.0)
	await _until_idle()
	assert_object(_director.visiting()).is_null()
	assert_bool(SaveSystem.is_scene_seen(FlashbackSchedule.id(1))).is_true()
	assert_int(FlashbackSchedule.due(SaveSystem.player_data)).is_equal(0)

func test_a_dropped_crossing_stays_in_the_present() -> void:
	await _settle()
	var long_crossing := C.scene(_flashback.crossing.id, [C.wait(30.0)])
	assert_bool(_cutscenes.play(long_crossing, _present.contents())).is_true()
	await _frames(3)
	_cutscenes.interrupt()
	await _frames(20)
	assert_int(_travels.size()).is_equal(0)
	assert_object(_director.visiting()).is_null()
	assert_bool(_visit_music()).is_false()

## A FlashbackSwap of `number` over the whole present room's contents.
func _swap_in_present(number: int, at: Vector2 = Vector2.ZERO) -> FlashbackSwap:
	var swap := FlashbackSwap.new()
	swap.number = number
	swap.position = at
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = SIZE * 0.5
	swap.add_child(shape)
	_present.contents().add_child(swap)
	return swap

## Flashback 5's hidden swap: inside the room's FlashbackSwap Ivo crosses to the twin pixel of the past with no cover,
## his facing kept; the visit announces itself as it begins.
func test_a_swap_hides_the_travel_in() -> void:
	_swap_in_present(1)
	var began: Array[Flashback] = []
	_director.visit_began.connect(func(flashback: Flashback) -> void: began.append(flashback))
	await _settle()
	_ivo.face_towards(-1)
	var feet := _ivo.global_position
	await _cross()
	assert_array(began).has_size(1)
	assert_that(_travels[0][1]).is_equal(Color.TRANSPARENT)
	assert_float(_travels[0][2]).is_equal(0.0)
	assert_vector(_ivo.global_position).is_equal_approx(feet + PAST_AT, Vector2(0.5, 0.5))
	assert_int(_ivo.facing).is_equal(-1)

## Outside the swap the flashback's own entry plays: its colour, its fade, its arrival.
func test_outside_the_swap_the_flashbacks_own_entry_plays() -> void:
	_swap_in_present(1, Vector2(0, -2000))
	await _settle()
	await _cross()
	assert_that(_travels[0][1]).is_equal(Color.WHITE)
	assert_float(_travels[0][2]).is_equal(_flashback.entry_fade)
	assert_int(_ivo.facing).is_equal(_flashback.arrival_facing)

## A crossing played from a talk's beat ends inside the talk: the travel waits for its end.
func test_an_open_talk_is_waited_out() -> void:
	await _settle()
	assert_bool(_dialogue.start_dialogue(D.dialogue(&"ribbon", [D.line("SPEAKER_ELDER")]), _ivo.global_position)).is_true()
	assert_bool(_cutscenes.play(_flashback.crossing, _present.contents())).is_true()
	await _until_idle()
	await _frames(20)
	assert_int(_travels.size()).is_equal(0)
	assert_object(_director.visiting()).is_same(_flashback)
	_dialogue.interrupt()
	assert_bool(await _until_playing(_flashback.opening)).is_true()
	assert_int(_travels.size()).is_equal(1)

func test_the_music_lives_the_visit() -> void:
	await _settle()
	assert_bool(_cutscenes.play(_flashback.crossing, _present.contents())).is_true()
	await _until_idle()
	await _frames(2)
	assert_bool(_visit_music()).is_true()
	assert_bool(await _until_playing(_flashback.opening)).is_true()
	assert_bool(_visit_music()).is_true()
	await _until_idle()
	await _frames(10)
	assert_bool(_visit_music()).is_true()
	assert_bool(_cutscenes.play(_flashback.leaving, _past.contents())).is_true()
	assert_bool(await _until_playing(_flashback.returning)).is_true()
	# The voice is cut with the image; silence holds the SCENE layer through the returning scene.
	assert_bool(_visit_music()).is_false()
	assert_bool(_silence_holds()).is_true()
	await _until_idle()
	assert_bool(_visit_music()).is_false()
	assert_bool(_silence_holds()).is_false()

## A leaving scene played from a talk's beat ends inside the talk: the travel back waits for its end.
func test_a_talk_open_at_the_leaving_is_waited_out() -> void:
	await _settle()
	await _cross()
	assert_bool(_dialogue.start_dialogue(D.dialogue(&"guitar", [D.line("SPEAKER_ELDER")]), _ivo.global_position)).is_true()
	assert_bool(_cutscenes.play(_flashback.leaving, _past.contents())).is_true()
	await _until_idle()
	await _frames(20)
	assert_int(_travels.size()).is_equal(1)
	assert_bool(_silence_holds()).is_true()
	_dialogue.interrupt()
	assert_bool(await _until_playing(_flashback.returning)).is_true()
	assert_int(_travels.size()).is_equal(2)

## A quit or a death's SceneSwap mid-visit: nothing is recorded, so the flashback is still due at the bench.
func test_leaving_the_tree_mid_visit_writes_nothing() -> void:
	await _settle()
	await _cross()
	var seen := SaveSystem.player_data.scenes_seen.duplicate()
	_holder.remove_child(_director)
	assert_object(_director.visiting()).is_null()
	assert_object(_director.return_point()).is_null()
	assert_array(SaveSystem.player_data.scenes_seen).is_equal(seen)
	assert_int(FlashbackSchedule.due(SaveSystem.player_data)).is_equal(1)
	_director.free()
	await _frames(5)
	assert_bool(_visit_music()).is_false()

## game.tscn wires the director to Game's travel and room changes.
func test_the_game_wires_the_travel() -> void:
	var state := (load("res://scenes/world/game.tscn") as PackedScene).get_state()
	var wired: Array[String] = []
	for i: int in state.get_connection_count():
		wired.append("%s>%s.%s" % [state.get_connection_signal(i), state.get_connection_target(i), state.get_connection_method(i)])
	assert_array(wired).contains([
		"travel_requested>..travel",
		"travelled>World/FlashbackDirector.on_travelled",
		"room_changed>World/FlashbackDirector.on_room_changed",
	])
