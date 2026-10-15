class_name PlayerTalkTest extends GdUnitTestSuite

## Up at a Talkable starts a talk under the door's gates, a door in reach wins, the map is refused while talking, an
## auto start waits for the gates, and with the director and the box wired as in game.tscn neither the press that closes
## a talk jumps nor an auto start with Z held skips a line.

const F := preload("res://tests/resources/dialogue/dialogue_fixture.gd")
const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const DOOR := preload("res://scenes/world/interactables/door/door.tscn")
const TALKABLE := preload("res://scenes/world/interactables/talkable/talkable.tscn")
const BOX := preload("res://scenes/ui/dialogue_box/dialogue_box.tscn")

## Top of the test floor.
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _talkable: Talkable
var _started: Array[Talkable] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	_started.clear()
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
	_talkable = TALKABLE.instantiate() as Talkable
	_talkable.position = Vector2(0, FLOOR_Y)
	var dialogues: Array[Dialogue] = [F.dialogue(&"talk", [F.line("DIALOGUE_TRIAL_FIRST_01"), F.line("DIALOGUE_TRIAL_FIRST_02")])]
	_talkable.talk = F.dialogue_set(dialogues)
	_holder.add_child(_talkable)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)
	_ivo.talk_started.connect(func(talkable: Talkable) -> void: _started.append(talkable))

func after_test() -> void:
	get_viewport().gui_release_focus()
	SaveSystem.begin("", true)

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func _key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)

## A Z tap, as the player makes it: a press, a few frames, a release.
func _tap_z() -> void:
	_key(KEY_Z, true)
	await _frames(3)
	_key(KEY_Z, false)
	await _frames(3)

## The director and the box, wired as game.tscn wires them.
func _wire() -> DialogueBox:
	var director := DialogueDirector.new()
	director.listener = _ivo
	_holder.add_child(director)
	var box := BOX.instantiate() as DialogueBox
	_holder.add_child(box)
	_ivo.talk_started.connect(director.start)
	_ivo.hurt.connect(director.interrupt)
	director.talk_began.connect(_ivo.begin_talk)
	director.talk_ended.connect(_ivo.end_talk)
	director.talk_paused.connect(_ivo.pause_talk)
	director.resume_wanted.connect(_ivo.request_talk_resume)
	_ivo.talk_resumed.connect(director.resume)
	director.box_placed.connect(box.place)
	director.line_shown.connect(box.show_line)
	director.choices_shown.connect(box.show_choices)
	director.box_closed.connect(box.close)
	box.advanced.connect(director.advance)
	box.chosen.connect(director.choose)
	return box

func test_up_at_a_talkable_starts_a_talk_once() -> void:
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(_started).contains_exactly([_talkable])

func test_a_door_in_reach_wins_over_a_talk() -> void:
	var door := DOOR.instantiate() as Door
	door.position = Vector2(0, FLOOR_Y)
	_holder.add_child(door)
	var entered: Array[Door] = []
	_ivo.door_entered.connect(func(taken: Door) -> void: entered.append(taken))
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(entered).contains_exactly([door])
	assert_array(_started).is_empty()

## Inside the zone but airborne: the on-floor gate refuses the press.
func test_up_in_the_air_does_not_talk() -> void:
	await _land()
	_player_input().jump_pressed.emit()
	await _frames(4)
	assert_bool(_ivo.is_on_floor()).is_false()
	assert_object((_ivo.get_node("Talks") as TalkComponent).reachable()).is_same(_talkable)
	_player_input().look_up_pressed.emit()
	await _frames(2)
	assert_array(_started).is_empty()

func test_up_with_the_memorina_drawn_is_a_note_not_a_talk() -> void:
	await _land()
	_player_input().draw_memorina_pressed.emit()
	for i: int in 30:
		await get_tree().physics_frame
		if _ivo.is_memorina_drawn():
			break
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(_started).is_empty()

func test_a_talkable_with_nothing_to_say_lets_up_pass() -> void:
	SaveSystem.mark_dialogue_heard(&"talk")
	_talkable.talk.dialogues[0].once = true
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(5)
	assert_array(_started).is_empty()

func test_a_talk_blocks_him_faces_the_talker_and_refuses_the_map() -> void:
	await _land()
	_ivo.face_towards(1.0)
	_ivo.begin_talk(Vector2(-200, FLOOR_Y))
	assert_bool(_ivo.is_talking()).is_true()
	assert_bool(_player_input().blocked).is_true()
	assert_int(_ivo.facing).is_equal(-1)
	assert_bool(_ivo.can_open_map()).is_false()
	_ivo.end_talk()
	assert_bool(_player_input().blocked).is_false()
	assert_bool(_ivo.can_open_map()).is_true()

func test_an_auto_start_waits_while_he_is_blocked() -> void:
	_talkable.auto_start = true
	await _land()
	_ivo.block_input()
	await await_millis(int(_talkable.auto_delay * 1000.0) + 200)
	assert_array(_started).is_empty()
	_ivo.unblock_input()
	await _frames(3)
	assert_array(_started).contains_exactly([_talkable])
	await _frames(10)
	assert_array(_started).has_size(1)

## The release of the Z that closes the talk must not reach Ivo as a jump.
func test_the_press_that_closes_a_talk_does_not_jump() -> void:
	var box := _wire()
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_talking()).is_true()
	# Complete and advance each of the two lines; the fourth tap ends the talk.
	for i: int in 4:
		await _tap_z()
	assert_bool(_ivo.is_talking()).is_false()
	assert_bool(box.visible).is_false()
	await _frames(10)
	assert_bool(_ivo.is_jumping()).is_false()
	assert_bool(_ivo.is_on_floor()).is_true()
	assert_bool(SaveSystem.is_dialogue_heard(&"talk")).is_true()

## Z held while an auto start opens the box: its release has no press there, so the first line is not skipped.
func test_an_auto_start_with_z_held_skips_nothing() -> void:
	var box := _wire()
	_talkable.auto_start = true
	_ivo.position = Vector2(400, -60)
	await _land()
	_key(KEY_Z, true)
	await _frames(2)
	_ivo.teleport(Vector2(0, FLOOR_Y))
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_talking():
			break
	assert_bool(_ivo.is_talking()).is_true()
	_key(KEY_Z, false)
	await _frames(3)
	assert_bool(box.visible).is_true()
	assert_str(box.text_label().text).is_equal(tr("DIALOGUE_TRIAL_FIRST_01"))
	assert_bool(box.is_typing()).is_true()

## A press while a due auto start is refused still expires after UP_BUFFER (bugs/an-up-press-in-a-due-auto-start-zone-never-expires).
func test_an_up_press_expires_while_a_due_auto_start_is_refused() -> void:
	_talkable.auto_start = true
	await _land()
	_ivo.block_input()
	await await_millis(int(_talkable.auto_delay * 1000.0) + 200)
	assert_object((_ivo.get_node("Talks") as TalkComponent).auto_ready()).is_same(_talkable)
	_player_input().look_up_pressed.emit()
	assert_float(float(_ivo.get("_up_buffer"))).is_greater(0.0)
	await await_millis(int(Player.UP_BUFFER * 1000.0) + 100)
	assert_float(float(_ivo.get("_up_buffer"))).is_equal(0.0)
	assert_array(_started).is_empty()

## Between the Talkable's origin and the villager beside it, he turns to the villager (bugs/ivo-faces-the-talkable-not-the-villager-beside-it).
func test_he_faces_the_speaker_not_the_talkable() -> void:
	_wire()
	_talkable.speaker_offset = 48.0
	await _land()
	_ivo.teleport(Vector2(16, FLOOR_Y))
	_ivo.face_towards(-1.0)
	await _frames(2)
	_player_input().look_up_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_talking()).is_true()
	assert_int(_ivo.facing).is_equal(1)

## During a beat Ivo is free but still in the talk: the map stays refused, and the talk resumes only once he is free
## again and not blocked (bugs/a-beat-that-ends-resumes-the-talk-without-the-start-gates).
func test_the_map_is_refused_during_a_beat_and_the_resume_waits_for_the_gates() -> void:
	var resumed: Array[int] = [0]
	_ivo.talk_resumed.connect(func() -> void: resumed[0] += 1)
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	_ivo.pause_talk()
	assert_bool(_player_input().blocked).is_false()
	assert_bool(_ivo.is_talking()).is_true()
	assert_bool(_ivo.can_open_map()).is_false()
	_ivo.block_input()
	_ivo.request_talk_resume()
	await _frames(5)
	assert_int(resumed[0]).is_equal(0)
	_ivo.unblock_input()
	await _frames(3)
	assert_int(resumed[0]).is_equal(1)
	_ivo.end_talk()
	assert_bool(_ivo.can_open_map()).is_true()
	assert_bool(_player_input().blocked).is_false()

## The box opens at the top in the trial's usual framing: both stand low on screen.
func test_a_talk_low_on_screen_opens_the_box_at_the_top() -> void:
	var box := _wire()
	await _land()
	_player_input().look_up_pressed.emit()
	await _frames(3)
	var height := _ivo.get_viewport_rect().size.y
	var feet := (_ivo.get_canvas_transform() * _ivo.global_position).y
	var expected := DialogueBoxSide.Side.BOTTOM if feet < height * 0.5 else DialogueBoxSide.Side.TOP
	var shift := (box.get_node("Art/Box") as Control).position.y
	assert_float(shift).is_equal(DialogueBox.TOP_SHIFT if expected == DialogueBoxSide.Side.TOP else 0.0)
