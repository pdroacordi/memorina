class_name PlayerSongPerformedTest extends GdUnitTestSuite

## `song_performed` fires for a matched performance in the world, never after a lesson (architecture/story-04-bearer-fragments).

const IVO := preload("res://scenes/characters/ivo/ivo.tscn")
const FREEZE := preload("res://resources/songs/freeze.tres")
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

func _land() -> void:
	for i: int in 120:
		await get_tree().physics_frame
		if _ivo.is_on_floor() and _ivo.is_still():
			return
	fail("Ivo never landed on the test floor")

## Waits for the pending track to start, then ends it as its stream would.
func _finish_performance() -> void:
	var performance := _ivo.get_node("SongPerformance") as SongPerformance
	for i: int in 600:
		if performance.is_playing():
			break
		await get_tree().physics_frame
	assert_bool(performance.is_playing()).is_true()
	performance.stop()
	performance.finished.emit()

func _memorina() -> MemorinaComponent:
	return _ivo.get_node("Memorina") as MemorinaComponent

func test_a_matched_performance_emits_it() -> void:
	SaveSystem.learn_song(FREEZE.id)
	await _land()
	var memorina := _memorina()
	memorina.enabled = true
	assert_bool(memorina.try_draw(true, [FREEZE] as Array[Song])).is_true()
	var monitor := monitor_signals(_ivo)
	for note: Enums.Note in FREEZE.notes:
		memorina.receive_note(note)
	await _finish_performance()
	await assert_signal(monitor).is_emitted("song_played", [FREEZE, _ivo.global_position])
	await assert_signal(monitor).is_emitted("song_performed", [FREEZE])

func test_a_lesson_does_not_emit_it() -> void:
	await _land()
	var monitor := monitor_signals(_ivo)
	assert_bool(_ivo.learn_song(FREEZE)).is_true()
	await _finish_performance()
	await assert_signal(monitor).is_emitted("song_played", [FREEZE, _ivo.global_position])
	await assert_signal(monitor).is_not_emitted("song_performed")

func test_a_by_ear_lesson_does_not_emit_it() -> void:
	await _land()
	var monitor := monitor_signals(_ivo)
	_memorina().song_guessed.emit(FREEZE)
	assert_bool(_ivo.is_in_lesson()).is_true()
	await _finish_performance()
	await assert_signal(monitor).is_emitted("song_played", [FREEZE, _ivo.global_position])
	await assert_signal(monitor).is_not_emitted("song_performed")

func test_a_completing_half_does_not_emit_it() -> void:
	SaveSystem.learn_song_half(BELL_JAR.id, Enums.SongHalf.SECOND)
	await _land()
	var monitor := monitor_signals(_ivo)
	assert_bool(_ivo.learn_song_half(BELL_JAR, Enums.SongHalf.FIRST, false)).is_true()
	await _finish_performance()
	await assert_signal(monitor).is_emitted("song_played", [BELL_JAR, _ivo.global_position])
	await assert_signal(monitor).is_not_emitted("song_performed")

func test_a_performance_after_a_lesson_emits_it() -> void:
	await _land()
	assert_bool(_ivo.learn_song(FREEZE)).is_true()
	await _finish_performance()
	await _land()
	var memorina := _memorina()
	memorina.enabled = true
	assert_bool(memorina.try_draw(true, [FREEZE] as Array[Song])).is_true()
	var monitor := monitor_signals(_ivo)
	for note: Enums.Note in FREEZE.notes:
		memorina.receive_note(note)
	await _finish_performance()
	await assert_signal(monitor).is_emitted("song_performed", [FREEZE])
