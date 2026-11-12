class_name GuitarJamBeatTest extends GdUnitTestSuite

## The jam beat holds Ivo to the notes with the guitar, sounds every press detuned, stands her laugh in at the third
## mismatch and releases it, and ends after its presses, its silence, or a silence before any press.

const BEAT := preload("res://scenes/world/story/guitar_jam_beat.tscn")
const MORNING := preload("res://resources/story/morning_song.tres")

var _beat: GuitarJamBeat
var _alba: FactStaging
var _finished: Array[int] = [0]


func before_test() -> void:
	_finished[0] = 0
	var root := auto_free(Node2D.new()) as Node2D
	_alba = _staging("Alba", ["Stone"], &"Stone")
	root.add_child(_alba)
	var laugh := _staging("AlbaLaugh", ["Laughing"], &"")
	root.add_child(laugh)
	_beat = BEAT.instantiate() as GuitarJamBeat
	_beat.process_mode = Node.PROCESS_MODE_PAUSABLE
	var setup := GuitarJamSetup.new()
	setup.melody = MORNING
	setup.max_presses = 5
	setup.laugh_at = 3
	setup.laugh_seconds = 0.3
	setup.end_after_silence = 0.4
	setup.end_before_first = 0.6
	setup.min_gap = 0.05
	_beat.setup = setup
	_beat.laugh_stand_ins = {NodePath("../Alba"): &"", NodePath("../AlbaLaugh"): &"Laughing"}
	root.add_child(_beat)
	add_child(root)
	_beat.finished.connect(func() -> void: _finished[0] += 1)

## A staging whose one stage (no gate) shows `shown`; empty shows nothing.
func _staging(staging_name: String, children: Array[String], shown: StringName) -> FactStaging:
	var staging := FactStaging.new()
	staging.name = staging_name
	var stage := FactStage.new()
	stage.show = shown
	staging.stages = [stage]
	for child_name: String in children:
		var child := Node2D.new()
		child.name = child_name
		staging.add_child(child)
	return staging

func _wrong(index: int) -> Enums.Note:
	var expected := MORNING.notes[index % MORNING.notes.size()]
	return Enums.Note.UP if expected != Enums.Note.UP else Enums.Note.DOWN

func _press(note: Enums.Note) -> void:
	_beat.receive_note(note, Enums.GlyphSet.KEYBOARD_ARROWS)
	await await_millis(70)

func test_it_holds_ivo_to_the_notes_with_the_guitar() -> void:
	assert_int(_beat.hold).is_equal(DialogueBeat.Hold.NOTES)
	assert_int(_beat.pose).is_equal(DialogueBeat.Pose.GUITAR)
	assert_int(_beat.strings.size()).is_equal(Enums.Note.size())

func test_the_third_mismatch_stands_her_laugh_in_then_releases_it() -> void:
	_beat.start()
	await _press(_wrong(0))
	await _press(MORNING.notes[1])
	await _press(_wrong(2))
	assert_bool(_beat.is_laughing()).is_false()
	await _press(_wrong(3))
	assert_bool(_beat.is_laughing()).is_true()
	assert_object(_alba.shown()).is_null()
	assert_str(str((_alba.get_parent().get_node("AlbaLaugh") as FactStaging).shown().name)).is_equal("Laughing")
	await await_millis(350)
	assert_bool(_beat.is_laughing()).is_false()
	assert_str(str(_alba.shown().name)).is_equal("Stone")

func test_it_ends_after_its_presses_and_sounds_each_detuned() -> void:
	_beat.start()
	var voice := _beat.get_child(0) as AudioStreamPlayer
	for i: int in 5:
		await _press(MORNING.notes[i])
		assert_bool(absf(voice.pitch_scale - 1.0) > 0.01).is_true()
	await await_idle_frame()
	assert_int(_finished[0]).is_equal(1)
	assert_bool(_beat.is_running()).is_false()
	assert_str(str(_alba.shown().name)).is_equal("Stone")

func test_silence_after_a_press_ends_it() -> void:
	_beat.start()
	await _press(Enums.Note.UP)
	await await_millis(250)
	assert_int(_finished[0]).is_equal(0)
	await await_millis(300)
	assert_int(_finished[0]).is_equal(1)

func test_silence_before_any_press_waits_longer() -> void:
	_beat.start()
	await await_millis(450)
	assert_int(_finished[0]).is_equal(0)
	await await_millis(300)
	assert_int(_finished[0]).is_equal(1)
