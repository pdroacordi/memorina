class_name PlayerEchoTest extends GdUnitTestSuite

## Ivo's echo mode: a teacher opens and closes it; a teacher's half shows no sheet (systems/teaching-creatures).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const BELL_JAR := preload("res://resources/songs/bell_jar.tres")
const FLOOR_Y := 30.0

var _holder: Node2D
var _ivo: Player


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
	rect.size = Vector2(4000, 20)
	shape.shape = rect
	floor_body.add_child(shape)
	_holder.add_child(floor_body)
	_ivo = IVO.instantiate() as Player
	_ivo.position = Vector2(0, -60)
	_holder.add_child(_ivo)

func after_test() -> void:
	SaveSystem.begin("", true)

func _phrase() -> Array[Enums.Note]:
	return [Enums.Note.LEFT, Enums.Note.RIGHT, Enums.Note.LEFT]

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

func test_open_and_close_announce_once() -> void:
	var monitor := monitor_signals(_ivo)
	_ivo.open_echo(_phrase())
	_ivo.open_echo(_phrase())
	assert_bool(_ivo.is_echo_open()).is_true()
	assert_array(_ivo.echo_phrase()).is_equal(_phrase())
	await assert_signal(monitor).is_emitted("echo_opened")
	_ivo.close_echo()
	_ivo.close_echo()
	assert_bool(_ivo.is_echo_open()).is_false()
	await assert_signal(monitor).is_emitted("echo_closed")

func test_a_teachers_half_shows_no_sheet() -> void:
	await _land()
	var monitor := monitor_signals(_ivo)
	assert_bool(_ivo.learn_song_half(BELL_JAR, Enums.SongHalf.FIRST, false)).is_true()
	assert_bool(SaveSystem.knows_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.FIRST)).is_true()
	await assert_signal(monitor).is_not_emitted("song_half_learned")

func test_a_songbooks_half_still_shows_its_sheet() -> void:
	await _land()
	var monitor := monitor_signals(_ivo)
	assert_bool(_ivo.learn_song_half(BELL_JAR, Enums.SongHalf.SECOND)).is_true()
	await assert_signal(monitor).is_emitted("song_half_learned", [BELL_JAR, Enums.SongHalf.SECOND, Enums.GlyphSet.KEYBOARD_ARROWS])

func test_learning_closes_the_echo() -> void:
	await _land()
	_ivo.open_echo(_phrase())
	assert_bool(_ivo.learn_song_half(BELL_JAR, Enums.SongHalf.FIRST, false)).is_true()
	assert_bool(_ivo.is_echo_open()).is_false()

func test_a_completing_half_starts_the_lesson() -> void:
	SaveSystem.learn_song_half(Enums.Song.BELL_JAR, Enums.SongHalf.SECOND)
	await _land()
	_ivo.open_echo(_phrase())
	assert_bool(_ivo.learn_song_half(BELL_JAR, Enums.SongHalf.FIRST, false)).is_true()
	assert_bool(_ivo.is_in_lesson()).is_true()
	assert_bool(SaveSystem.player_data.learned_songs[Enums.Song.BELL_JAR]).is_true()
