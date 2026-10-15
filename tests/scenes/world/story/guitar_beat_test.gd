class_name GuitarBeatTest extends GdUnitTestSuite

## The guitar beat shows the phrase up to its gap, lights each right note, lets a wrong one sound, drops a press inside
## min_gap, and ends after its dead presses or its silence at the gap; it stands its stand-ins in.

const BEAT := preload("res://scenes/world/story/guitar_beat.tscn")
const MORNING := preload("res://resources/story/morning_song.tres")

var _beat: GuitarBeat
var _log: Array[String] = []
var _finished: Array[int] = [0]


func before_test() -> void:
	_log.clear()
	_finished[0] = 0
	_beat = auto_free(BEAT.instantiate()) as GuitarBeat
	_beat.process_mode = Node.PROCESS_MODE_PAUSABLE
	var attempt := GuitarAttempt.new()
	attempt.melody = MORNING
	attempt.gap_index = 2
	attempt.end_after_silence = 0.3
	attempt.end_after_dead_presses = 3
	attempt.min_gap = 0.05
	_beat.attempt = attempt
	add_child(_beat)
	_beat.phrase_shown.connect(func(_notes: Array[Enums.Note], count: int, _glyphs: Enums.GlyphSet) -> void: _log.append("shown:%d" % count))
	_beat.phrase_lit.connect(func(index: int) -> void: _log.append("lit:%d" % index))
	_beat.finished.connect(func() -> void: _finished[0] += 1)

func _press(note: Enums.Note) -> void:
	_beat.receive_note(note, Enums.GlyphSet.KEYBOARD_ARROWS)
	await await_millis(80)

func test_it_holds_ivo_to_the_notes_with_the_guitar() -> void:
	assert_int(_beat.hold).is_equal(DialogueBeat.Hold.NOTES)
	assert_int(_beat.pose).is_equal(DialogueBeat.Pose.GUITAR)
	assert_int(_beat.strings.size()).is_equal(Enums.Note.size())
	assert_object(_beat.muted).is_not_null()

func test_right_notes_light_until_the_gap_and_dead_presses_end_it() -> void:
	_beat.start()
	assert_array(_log).is_equal(["shown:2"])
	await _press(MORNING.notes[0])
	await _press(Enums.Note.UP if MORNING.notes[1] != Enums.Note.UP else Enums.Note.DOWN)
	await _press(MORNING.notes[1])
	assert_array(_log).is_equal(["shown:2", "lit:0", "lit:1"])
	for i: int in 3:
		await _press(MORNING.notes[2])
	await await_idle_frame()
	assert_int(_finished[0]).is_equal(1)
	assert_bool(_beat.is_running()).is_false()

func test_silence_at_the_gap_ends_it() -> void:
	_beat.start()
	await _press(MORNING.notes[0])
	await _press(MORNING.notes[1])
	assert_int(_finished[0]).is_equal(0)
	await await_millis(450)
	assert_int(_finished[0]).is_equal(1)

## Before the gap it waits for him however long he stays silent.
func test_silence_before_the_gap_does_not_end_it() -> void:
	_beat.start()
	await await_millis(450)
	assert_int(_finished[0]).is_equal(0)

func test_a_press_inside_min_gap_is_dropped() -> void:
	_beat.start()
	_beat.receive_note(MORNING.notes[0], Enums.GlyphSet.KEYBOARD_ARROWS)
	_beat.receive_note(MORNING.notes[1], Enums.GlyphSet.KEYBOARD_ARROWS)
	assert_array(_log).is_equal(["shown:2", "lit:0"])

func test_it_stands_its_stand_ins_in() -> void:
	var staging := auto_free(FactStaging.new()) as FactStaging
	var stage := FactStage.new()
	stage.show = &"OnWall"
	staging.stages = [stage]
	for child: String in ["OnWall", "Lowered"]:
		var sprite := Sprite2D.new()
		sprite.name = child
		staging.add_child(sprite)
	add_child(staging)
	_beat.stand_ins = {_beat.get_path_to(staging): &"Lowered"}
	_beat.start()
	assert_str(String(staging.shown().name)).is_equal("Lowered")
