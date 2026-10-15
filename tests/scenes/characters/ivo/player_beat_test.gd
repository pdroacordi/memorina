class_name PlayerBeatTest extends GdUnitTestSuite

## A beat holds Ivo as it says: NOTES lets only the four note inputs through (to the director, not the Memorina) and
## the guitar strums on each; STILL keeps him blocked and its block does not refuse the resume; the pose shows until
## the talk ends. Driven with Input.parse_input_event.

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")

const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player
var _notes: Array[int] = []


func before_test() -> void:
	SaveSystem.begin("", true)
	_notes.clear()
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
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)
	_ivo.beat_note_pressed.connect(func(note: Enums.Note, _glyphs: Enums.GlyphSet) -> void: _notes.append(note))

func after_test() -> void:
	for action: StringName in [&"note_up", &"move_right", &"jump"]:
		_action(action, false)
	SaveSystem.begin("", true)

func _player_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

func _driver() -> AnimationDriver:
	return _ivo.get_node("AnimationDriver") as AnimationDriver

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func _action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _guitar() -> void:
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	_ivo.pause_talk(DialogueBeat.Hold.NOTES, DialogueBeat.Pose.GUITAR, Vector2(-100, FLOOR_Y))

func test_notes_reach_the_beat_and_nothing_else_moves_him() -> void:
	await _guitar()
	assert_bool(_player_input().notes_only).is_true()
	assert_bool(_player_input().blocked).is_false()
	assert_int(_ivo.facing).is_equal(-1)
	_action(&"note_up", true)
	await _frames(1)
	_action(&"note_up", false)
	_action(&"move_right", true)
	_action(&"jump", true)
	await _frames(10)
	_action(&"jump", false)
	_action(&"move_right", false)
	assert_array(_notes).is_equal([Enums.Note.UP])
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	assert_bool(_ivo.is_jumping()).is_false()
	assert_float(absf(_ivo.velocity.x)).is_less(1.0)

func test_the_guitar_pose_holds_and_strums_on_a_note() -> void:
	await _guitar()
	await _frames(2)
	assert_str(String(_driver().current)).is_equal(String(PlayerAnimationResolver.GUITAR_HOLD))
	_action(&"note_up", true)
	await _frames(2)
	_action(&"note_up", false)
	assert_str(String(_driver().current)).is_equal(String(PlayerAnimationResolver.GUITAR_STRUM))
	await _frames(30)
	assert_str(String(_driver().current)).is_equal(String(PlayerAnimationResolver.GUITAR_HOLD))

func test_the_memorina_pose_shows_without_drawing_it() -> void:
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	_ivo.pause_talk(DialogueBeat.Hold.STILL, DialogueBeat.Pose.MEMORINA)
	await _frames(2)
	assert_str(String(_driver().current)).is_equal(String(PlayerAnimationResolver.MEMORINA_IDLE))
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	# Held after the beat while the talk goes on, dropped at its end.
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	await _frames(2)
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.MEMORINA)
	_ivo.end_talk()
	await _frames(2)
	assert_int(_ivo.held_pose()).is_equal(DialogueBeat.Pose.NONE)
	assert_str(String(_driver().current)).is_not_equal(String(PlayerAnimationResolver.MEMORINA_IDLE))

## STILL keeps the talk's block; the resume does not count it as a refusal.
func test_a_still_beat_keeps_him_blocked_and_resumes() -> void:
	var resumed: Array[int] = [0]
	_ivo.talk_resumed.connect(func() -> void: resumed[0] += 1)
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	_ivo.pause_talk(DialogueBeat.Hold.STILL, DialogueBeat.Pose.NONE)
	assert_bool(_player_input().blocked).is_true()
	assert_bool(_ivo.can_open_map()).is_false()
	_ivo.request_talk_resume()
	await _frames(3)
	assert_int(resumed[0]).is_equal(1)

func test_the_end_of_the_talk_frees_the_notes() -> void:
	await _guitar()
	_ivo.end_talk()
	assert_bool(_player_input().notes_only).is_false()
	assert_bool(_player_input().blocked).is_false()
	_action(&"note_up", true)
	await _frames(1)
	_action(&"note_up", false)
	assert_array(_notes).is_empty()

## A FREE beat lets him walk, but Up takes no door and no item until the talk ends
## (bugs/up-takes-a-door-during-a-free-beat-and-strands-the-talk).
func test_up_takes_no_door_during_a_talk() -> void:
	var door := (load("res://scenes/world/interactables/door/door.tscn") as PackedScene).instantiate() as Door
	door.position = Vector2(0, FLOOR_Y)
	_holder.add_child(door)
	var entered: Array[Door] = []
	_ivo.door_entered.connect(func(taken: Door) -> void: entered.append(taken))
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	_ivo.pause_talk(DialogueBeat.Hold.FREE, DialogueBeat.Pose.NONE)
	_player_input().look_up_pressed.emit()
	await _frames(4)
	assert_array(entered).is_empty()
	_ivo.end_talk()
	_player_input().look_up_pressed.emit()
	await _frames(4)
	assert_array(entered).contains_exactly([door])

func test_up_takes_no_item_during_a_talk() -> void:
	SaveSystem.set_item_owned(Enums.PlayerItem.SWORD, false)
	var pickup := (load("res://scenes/world/interactables/item_pickup/item_pickup.tscn") as PackedScene).instantiate() as ItemPickup
	pickup.texture = load("res://assets/sprites/world/pickups/sword.png") as Texture2D
	pickup.position = Vector2(0, FLOOR_Y)
	_holder.add_child(pickup)
	await _land()
	_ivo.begin_talk(Vector2(100, FLOOR_Y))
	_ivo.pause_talk(DialogueBeat.Hold.FREE, DialogueBeat.Pose.NONE)
	_player_input().look_up_pressed.emit()
	await _frames(4)
	assert_bool(SaveSystem.has_item(Enums.PlayerItem.SWORD)).is_false()
