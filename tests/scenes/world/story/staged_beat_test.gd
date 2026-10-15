class_name StagedBeatTest extends GdUnitTestSuite

## A staged beat lasts its duration (at least its melody's), on the pausable clock, and stands its stand-ins in;
## the MelodyPlayer sounds each note on its onset.

const BEAT := preload("res://scenes/world/story/staged_beat.tscn")
const MORNING := preload("res://resources/story/morning_song.tres")

var _beat: StagedBeat
var _finished: Array[int] = [0]


func before_test() -> void:
	_finished[0] = 0
	_beat = auto_free(BEAT.instantiate()) as StagedBeat
	_beat.process_mode = Node.PROCESS_MODE_PAUSABLE
	_beat.duration = 0.3
	add_child(_beat)
	_beat.finished.connect(func() -> void: _finished[0] += 1)

func test_it_holds_still_by_default_and_ends_after_its_duration() -> void:
	assert_int(_beat.hold).is_equal(DialogueBeat.Hold.STILL)
	_beat.start()
	await await_millis(150)
	assert_int(_finished[0]).is_equal(0)
	await await_millis(300)
	assert_int(_finished[0]).is_equal(1)

func test_a_melody_lasts_at_least_its_notes() -> void:
	_beat.melody = MORNING
	_beat.melody_count = 2
	_beat.start()
	await await_millis(600)
	assert_int(_finished[0]).is_equal(0)
	await await_millis(450)
	assert_int(_finished[0]).is_equal(1)

## A hold stops the beat's clock: it does not end while the world is held.
func test_a_hold_stops_its_clock() -> void:
	var freeze := WorldFreeze.new()
	add_child(freeze)
	_beat.start()
	freeze.hold()
	await get_tree().create_timer(0.6, true, false, true).timeout
	assert_int(_finished[0]).is_equal(0)
	freeze.release()
	remove_child(freeze)
	freeze.free()
	await await_millis(450)
	assert_int(_finished[0]).is_equal(1)

func test_the_melody_player_sounds_each_note_on_its_onset() -> void:
	var player := auto_free(MelodyPlayer.new()) as MelodyPlayer
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	var played: Array[int] = []
	var done: Array[int] = [0]
	player.note_played.connect(func(index: int) -> void: played.append(index))
	player.finished.connect(func() -> void: done[0] += 1)
	player.play(MORNING, 3)
	await await_millis(100)
	assert_array(played).is_equal([0])
	await await_millis(450)
	assert_array(played).is_equal([0, 1])
	await await_millis(1100)
	assert_array(played).is_equal([0, 1, 2])
	assert_int(done[0]).is_equal(1)
	assert_bool(player.is_playing()).is_false()

## A releasing beat gives back only its own stand-in, so it cannot undo a later beat's.
func test_a_beat_cannot_release_another_beats_stand_in() -> void:
	var staging := auto_free(FactStaging.new()) as FactStaging
	staging.name = "Staging"
	var still := FactStage.new()
	still.show = &"Still"
	staging.stages = [still]
	for child: String in ["Still", "Mine", "Theirs"]:
		var sprite := Sprite2D.new()
		sprite.name = child
		staging.add_child(sprite)
	add_child(staging)
	_beat.stand_ins = {_beat.get_path_to(staging): &"Mine"}
	_beat.release_stand_ins = true
	_beat.start()
	assert_str(String(staging.shown().name)).is_equal("Mine")
	staging.stand_in(&"Theirs")
	await await_millis(450)
	assert_int(_finished[0]).is_equal(1)
	assert_str(String(staging.shown().name)).is_equal("Theirs")
	staging.release(&"Theirs")
	assert_str(String(staging.shown().name)).is_equal("Still")
