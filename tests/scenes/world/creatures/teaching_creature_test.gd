class_name TeachingCreatureTest extends GdUnitTestSuite

## A teacher with a real Ivo: coloured by its own shield, no mark, no body; the echo opens in reach while its half
## would teach (systems/teaching-creatures).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const SNAIL := preload("res://scenes/world/creatures/snail/snail.tscn")
const BALLOON := preload("res://scenes/ui/teacher_balloon/teacher_balloon.tscn")
const SPECIES: Array[String] = ["snail", "thrush", "kestrel", "lizard"]
const FLOOR_Y := 30.0
const L := Enums.Note.LEFT
const R := Enums.Note.RIGHT

var _holder: Node2D
var _ivo: Player
var _snail: TeachingCreature
## The teacher's stand-in room, so a test can idle it as RoomResidency does.
var _room: Node2D
var _balloon: TeacherBalloon


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.set_item_owned(Enums.PlayerItem.MEMORINA, true)
	_holder = auto_free(Node2D.new()) as Node2D
	add_child(_holder)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 2
	floor_body.position = Vector2(0, FLOOR_Y + 10.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(6000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_balloon = BALLOON.instantiate() as TeacherBalloon
	_holder.add_child(_balloon)

func after_test() -> void:
	SaveSystem.begin("", true)

func _place(ivo_x: float) -> void:
	_room = Node2D.new()
	_holder.add_child(_room)
	_snail = SNAIL.instantiate() as TeachingCreature
	_snail.position = Vector2(0, FLOOR_Y)
	_room.add_child(_snail)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(ivo_x, -20)
	_holder.add_child(_ivo)

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func _ivo_input() -> PlayerInput:
	return _ivo.get_node("PlayerInput") as PlayerInput

## Presses a note once the voice would take it (the minimum gap between notes is real time).
func _press(note: Enums.Note) -> void:
	await await_millis(300)
	_ivo_input().note_pressed.emit(note, Enums.GlyphSet.KEYBOARD_ARROWS)
	await _frames(2)

func test_each_species_is_shielded_unmarked_and_has_no_body() -> void:
	for species: String in SPECIES:
		var teacher := auto_free(load("res://scenes/world/creatures/%s/%s.tscn" % [species, species]).instantiate()) as TeachingCreature
		assert_object(teacher).override_failure_message(species).is_not_null()
		assert_object(teacher.lesson).override_failure_message(species).is_not_null()
		var shield := teacher.get_node(^"GreyhushShield") as GreyhushShield
		assert_int(shield.mode).override_failure_message(species).is_equal(GreyhushShield.Mode.SILHOUETTE)
		assert_float(shield.amount).is_equal(1.0)
		# No material: the corruption edge's mark would hide it from every shield.
		assert_object((teacher.get_node(^"Sprite2D") as Sprite2D).material).override_failure_message(species).is_null()
		assert_bool(teacher.find_children("*", "CollisionObject2D", true, false).is_empty()).override_failure_message(species).is_true()
		assert_float((teacher.get_node(^"Call/Voice/AudioStreamPlayer") as AudioStreamPlayer).pitch_scale).is_equal(2.0)
		assert_float((teacher.get_node(^"Duet/Voice/AudioStreamPlayer") as AudioStreamPlayer).pitch_scale).is_equal(1.0)
		assert_int(teacher.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)

func test_the_echo_opens_in_reach_and_closes_out_of_it() -> void:
	_place(40.0)
	await _land()
	await _frames(2)
	assert_bool(_ivo.is_echo_open()).is_true()
	assert_array(_ivo.echo_phrase()).is_equal([L, R, L])
	_ivo.teleport(Vector2(1000.0, FLOOR_Y))
	await _frames(3)
	assert_bool(_ivo.is_echo_open()).is_false()

func test_it_sings_into_the_balloon_on_approach() -> void:
	_place(40.0)
	await _land()
	await await_millis(600)
	assert_object(_balloon.speaker()).is_same(_snail.get_node(^"BalloonAnchor"))
	assert_bool(_snail.is_singing()).is_true()

func test_a_taught_teacher_opens_no_echo() -> void:
	SaveSystem.learn_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)
	_place(40.0)
	await _land()
	await _frames(3)
	assert_bool(_ivo.is_echo_open()).is_false()
	assert_int(_snail.flow().state()).is_equal(TeachingFlow.State.TAUGHT_QUIET)

## A death rewinds the save: the half is unknown again and the teacher teaches.
func test_a_rewound_half_reopens_the_echo() -> void:
	SaveSystem.learn_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)
	_place(40.0)
	await _land()
	SaveSystem.player_data.song_first_halves[Enums.Song.BELL_JAR] = false
	SaveSystem.progress_changed.emit()
	await _frames(3)
	assert_bool(_ivo.is_echo_open()).is_true()

func test_echoing_the_phrase_teaches_the_first_half_with_no_sheet() -> void:
	_place(40.0)
	await _land()
	var monitor := monitor_signals(_ivo)
	_ivo_input().draw_memorina_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_true()
	for note: Enums.Note in [L, R, L]:
		await _press(note)
	await _frames(3)
	assert_bool(SaveSystem.knows_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)).is_true()
	assert_bool(SaveSystem.player_data.learned_songs[Enums.Song.BELL_JAR]).is_false()
	assert_int(_snail.flow().state()).is_equal(TeachingFlow.State.FLOURISH)
	assert_bool(_ivo.is_echo_open()).is_false()
	await assert_signal(monitor).is_not_emitted("song_half_learned")

func test_a_wrong_note_teaches_nothing() -> void:
	_place(40.0)
	await _land()
	_ivo_input().draw_memorina_pressed.emit()
	await _frames(3)
	await _press(L)
	await _press(L)
	assert_bool(SaveSystem.knows_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)).is_false()
	assert_bool(_ivo.is_echo_open()).is_true()

## The half that completes the song: the teacher and Ivo's voice sing it together, then the lesson starts.
func test_a_completing_echo_duets_then_starts_the_lesson() -> void:
	SaveSystem.learn_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.SECOND)
	_place(40.0)
	await _land()
	_ivo_input().draw_memorina_pressed.emit()
	await _frames(3)
	for note: Enums.Note in [L, R, L]:
		await _press(note)
	await _frames(3)
	assert_int(_snail.flow().state()).is_equal(TeachingFlow.State.DUET)
	assert_bool(SaveSystem.knows_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)).is_false()
	for i: int in 240:
		await get_tree().physics_frame
		if _ivo.is_in_lesson():
			break
	assert_bool(_ivo.is_in_lesson()).is_true()
	assert_bool(SaveSystem.player_data.learned_songs[Enums.Song.BELL_JAR]).is_true()
	assert_object(_balloon.speaker()).is_null()

## bugs/a-sheathe-mid-echo-leaves-the-teachers-balloon-ahead-of-the-instrument: a sheathe clears the teacher's count
## with the instrument's, so after a redraw one right note lights one glyph, and the teacher sings again.
func test_a_sheathe_mid_echo_resets_the_teacher() -> void:
	_place(40.0)
	await _land()
	_ivo_input().draw_memorina_pressed.emit()
	await _frames(3)
	await _press(L)
	await _press(R)
	assert_bool(_balloon.is_lit(1)).is_true()
	_ivo_input().draw_memorina_pressed.emit()
	await _frames(3)
	assert_bool(_ivo.is_memorina_drawn()).is_false()
	assert_bool(_balloon.is_lit(0)).is_false()
	var waited := 0
	while _snail.flow().state() != TeachingFlow.State.SINGING and waited < 360:
		await get_tree().physics_frame
		waited += 1
	assert_int(_snail.flow().state()).override_failure_message("never sang again").is_equal(TeachingFlow.State.SINGING)
	await await_millis(300)
	_ivo_input().draw_memorina_pressed.emit()
	await _frames(3)
	await _press(L)
	assert_bool(_balloon.is_lit(0)).is_true()
	assert_bool(_balloon.is_lit(1)).is_false()

## bugs/a-teacher-whose-room-idles-leaves-ivos-echo-open: an idled room closes its teacher's echo.
func test_an_idled_room_closes_the_echo() -> void:
	_place(40.0)
	await _land()
	await _frames(2)
	assert_bool(_ivo.is_echo_open()).is_true()
	_room.process_mode = Node.PROCESS_MODE_DISABLED
	assert_bool(_ivo.is_echo_open()).is_false()
	assert_object(_balloon.speaker()).is_null()
	_room.process_mode = Node.PROCESS_MODE_INHERIT
	await _frames(3)
	assert_bool(_ivo.is_echo_open()).is_true()

func test_a_freed_teacher_closes_the_echo() -> void:
	_place(40.0)
	await _land()
	await _frames(2)
	_room.free()
	assert_bool(_ivo.is_echo_open()).is_false()

