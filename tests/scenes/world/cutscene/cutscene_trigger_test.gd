class_name CutsceneTriggerTest extends GdUnitTestSuite

## A CutsceneTrigger plays its scene once its room is current, after its delay, when Ivo can begin a scene: in a room whose
## contents are added deferred on this visit (the new game's start, a respawn into an evicted room), after a door's
## arrival and in a room already resident. A seen scene does not replay, and leaving the room drops or disarms it
## (bugs/a-cutscene-trigger-in-a-first-visited-room-never-arms).

const C := preload("res://tests/resources/cutscene/cutscene_fixture.gd")
const D := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const SIZE := Vector2(640, 384)
const FLOOR_Y := 288.0

var _holder: Node2D
var _ivo: Player
var _director: CutsceneDirector


func before_test() -> void:
	SaveSystem.begin("", true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(200, FLOOR_Y - 60.0)
	_holder.add_child(_ivo)
	_director = CutsceneDirector.new()
	_director.ivo = _ivo
	_holder.add_child(_director)
	_director.scene_began.connect(_ivo.begin_scene.unbind(1))
	_director.scene_ended.connect(_ivo.end_scene.unbind(1))

func after_test() -> void:
	SaveSystem.begin("", true)

## A contents scene holding one trigger for a short scene `id`.
func _contents_with_trigger(id: StringName, delay: float = 0.0, from_black: bool = false) -> PackedScene:
	var root := Node2D.new()
	root.name = "Contents"
	var trigger := CutsceneTrigger.new()
	trigger.name = "Trigger"
	trigger.cutscene = C.scene(id, [C.wait(0.1)])
	trigger.delay = delay
	trigger.from_black = from_black
	root.add_child(trigger)
	trigger.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	return packed

func _empty_contents() -> PackedScene:
	var root := Node2D.new()
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	return packed

func _room(contents: PackedScene, at: Vector2) -> Room:
	var room := Room.new()
	room.contents_scene = contents
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

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _until_playing(frames: int) -> bool:
	for i: int in frames:
		await get_tree().physics_frame
		if _director.is_playing():
			return true
	return false

func test_it_wants_its_gates_and_an_unseen_scene() -> void:
	var trigger := auto_free(CutsceneTrigger.new()) as CutsceneTrigger
	trigger.cutscene = C.scene(&"arrive", [])
	assert_bool(trigger.wants(SaveSystem.player_data)).is_true()
	trigger.when = [D.fact(SaveFact.Kind.DIALOGUE_HEARD, &"talk")]
	assert_bool(trigger.wants(SaveSystem.player_data)).is_false()
	SaveSystem.mark_dialogue_heard(&"talk")
	assert_bool(trigger.wants(SaveSystem.player_data)).is_true()
	SaveSystem.mark_scene_seen(&"arrive")
	assert_bool(trigger.wants(SaveSystem.player_data)).is_false()
	trigger.repeat = true
	assert_bool(trigger.wants(SaveSystem.player_data)).is_true()

## The new game's start and a respawn into an evicted room: room_changed in the frame the contents are made.
func test_a_first_visited_room_arms_its_trigger() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"arrive"), Vector2.ZERO)
	room.activate()
	assert_bool(room.contents().is_inside_tree()).is_false()
	_director.on_room_changed(room)
	assert_bool(await _until_playing(10)).is_true()
	await _frames(20)
	assert_bool(_director.is_playing()).is_false()
	assert_bool(SaveSystem.is_scene_seen(&"arrive")).is_true()

## A door's arrival (Game._land_in) emits once the contents are ready.
func test_a_door_arrival_arms_its_trigger() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"arrive"), Vector2.ZERO)
	room.activate()
	await get_tree().process_frame
	assert_bool(room.contents().is_node_ready()).is_true()
	_director.on_room_changed(room)
	assert_bool(await _until_playing(10)).is_true()

## A respawn or a walk into a room a neighbour already made resident.
func test_a_resident_room_arms_its_trigger() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"arrive"), Vector2.ZERO)
	room.activate()
	await _frames(3)
	room.deactivate()
	room.activate()
	_director.on_room_changed(room)
	assert_bool(await _until_playing(10)).is_true()

func test_its_delay_and_ivo_hold_it() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"arrive", 0.3), Vector2.ZERO)
	room.activate()
	_ivo.block_input()
	_director.on_room_changed(room)
	await _frames(30)
	assert_bool(_director.is_playing()).is_false()
	_ivo.unblock_input()
	assert_bool(await _until_playing(10)).is_true()

func test_a_seen_scene_does_not_replay() -> void:
	await _land()
	SaveSystem.mark_scene_seen(&"arrive")
	var room := _room(_contents_with_trigger(&"arrive"), Vector2.ZERO)
	room.activate()
	_director.on_room_changed(room)
	assert_bool(await _until_playing(10)).is_false()

func test_leaving_the_room_disarms_it() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"arrive", 0.5), Vector2.ZERO)
	var other := _room(_empty_contents(), Vector2(SIZE.x, 0))
	room.activate()
	other.activate()
	_director.on_room_changed(room)
	await _frames(5)
	_director.on_room_changed(other)
	assert_bool(await _until_playing(60)).is_false()

## A scene whose host is not in the new room is dropped, unrecorded.
func test_a_room_change_drops_its_scene() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"long"), Vector2.ZERO)
	var other := _room(_empty_contents(), Vector2(SIZE.x, 0))
	room.activate()
	other.activate()
	await _frames(2)
	var trigger := room.contents().get_node("Trigger") as CutsceneTrigger
	trigger.cutscene = C.scene(&"long", [C.wait(30.0)])
	_director.on_room_changed(room)
	assert_bool(await _until_playing(10)).is_true()
	_director.on_room_changed(other)
	assert_bool(_director.is_playing()).is_false()
	assert_bool(_ivo.is_in_scene()).is_false()
	assert_bool(SaveSystem.is_scene_seen(&"long")).is_false()

## The new game's opening plays in black at once, without waiting for Ivo's gates (he is still behind the first fade).
func test_a_scene_from_black_does_not_wait_for_ivo() -> void:
	await _land()
	var room := _room(_contents_with_trigger(&"morning", 0.0, true), Vector2.ZERO)
	room.activate()
	_ivo.block_input()
	_director.on_room_changed(room)
	assert_bool(await _until_playing(10)).is_true()
	_ivo.unblock_input()
