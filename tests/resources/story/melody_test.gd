class_name MelodyTest extends GdUnitTestSuite

## The morning song is E G E D | C D E C on the Memorina's inputs, beats 1 1 1.5 0.5 1 1 1 2.5 at 0.42 s
## ("Approve melody (Recommended)", user, 2026-10-15); onsets follow the beats.

const MORNING := preload("res://resources/story/morning_song.tres")


func test_the_morning_song_is_the_approved_melody() -> void:
	var expected: Array[Enums.Note] = [
		Enums.Note.RIGHT, Enums.Note.UP, Enums.Note.RIGHT, Enums.Note.LEFT,
		Enums.Note.DOWN, Enums.Note.LEFT, Enums.Note.RIGHT, Enums.Note.DOWN,
	]
	assert_array(MORNING.notes).is_equal(expected)
	assert_array(Array(MORNING.beats)).is_equal([1.0, 1.0, 1.5, 0.5, 1.0, 1.0, 1.0, 2.5])
	assert_float(MORNING.beat_seconds).is_equal_approx(0.42, 0.0001)
	assert_array(Array(MORNING.validate())).is_empty()

func test_onsets_follow_the_beats() -> void:
	var onsets := MORNING.onsets(4)
	assert_int(onsets.size()).is_equal(4)
	assert_float(onsets[0]).is_equal(0.0)
	assert_float(onsets[1]).is_equal_approx(0.42, 0.0001)
	assert_float(onsets[2]).is_equal_approx(0.84, 0.0001)
	assert_float(onsets[3]).is_equal_approx(1.47, 0.0001)
	assert_float(MORNING.duration(4)).is_equal_approx(1.68, 0.0001)
	assert_float(MORNING.duration()).is_equal_approx(9.5 * 0.42, 0.0001)

func test_tempo_scales_the_onsets() -> void:
	assert_float(MORNING.onsets(2, 2.0)[1]).is_equal_approx(0.21, 0.0001)

func test_a_broken_melody_is_named() -> void:
	var broken := Melody.new()
	broken.notes = [Enums.Note.UP, Enums.Note.DOWN]
	broken.beats = PackedFloat32Array([1.0])
	assert_str(", ".join(broken.validate())).contains("1 beats for 2 notes")
