class_name GuitarJamTest extends GdUnitTestSuite

## The free guitar of flashback 1 (systems/story): every press sounds out of tune, none is ever a played note, she laughs
## once at the third mismatch, and the jam ends at its presses. Every press sequence, the morning melody included.

const SETUP := preload("res://resources/story/flashback_1_jam.tres")
const PLAYED_NAMES: Array[String] = ["PLAYED", "MATCHED", "RIGHT"]


func test_the_jam_has_no_played_outcome() -> void:
	for key: String in GuitarJam.Strum.keys():
		assert_bool(PLAYED_NAMES.has(key)).override_failure_message(key).is_false()
	assert_int(GuitarJam.Strum.size()).is_equal(2)

func test_every_press_is_out_of_tune() -> void:
	var jam := GuitarJam.new(SETUP)
	for index: int in SETUP.max_presses * 3:
		assert_float(absf(jam.cents(index))).is_greater_equal(GuitarJam.MIN_DETUNE_CENTS)
		assert_bool(absf(jam.pitch_scale(index) - 1.0) > 0.01).is_true()
	for cents: float in SETUP.detune_cents:
		assert_float(absf(cents)).is_greater_equal(GuitarJam.MIN_DETUNE_CENTS)

## All 4^n sequences of as many presses as the melody has notes, and the melody itself twice over: every outcome is ALONG
## or ASTRAY, the laugh comes exactly on the third mismatch, and nothing ever counts as the song played.
func test_no_press_sequence_plays_the_song() -> void:
	var notes := SETUP.melody.notes
	var length := notes.size()
	var total := int(pow(4, length))
	var problems := 0
	for code: int in total:
		var jam := GuitarJam.new(SETUP)
		var rest := code
		var laughs := 0
		for i: int in length:
			var strum := jam.press(rest % 4)
			rest /= 4
			if strum != GuitarJam.Strum.ALONG and strum != GuitarJam.Strum.ASTRAY:
				problems += 1
			if jam.laughs():
				laughs += 1
				if jam.mismatches() != SETUP.laugh_at:
					problems += 1
		if laughs != (1 if jam.mismatches() >= SETUP.laugh_at else 0):
			problems += 1
	assert_int(problems).is_equal(0)
	var melody := GuitarJam.new(SETUP)
	for note: Enums.Note in notes + notes:
		assert_int(melody.press(note)).is_equal(GuitarJam.Strum.ALONG)
		assert_bool(melody.laughs()).is_false()
	assert_int(melody.mismatches()).is_equal(0)

func test_the_third_mismatch_laughs_once() -> void:
	var jam := GuitarJam.new(SETUP)
	var wrong := Enums.Note.UP if SETUP.melody.notes[0] != Enums.Note.UP else Enums.Note.DOWN
	jam.press(wrong)
	assert_bool(jam.laughs()).is_false()
	jam.press(SETUP.melody.notes[1])
	jam.press(Enums.Note.UP if SETUP.melody.notes[2] != Enums.Note.UP else Enums.Note.DOWN)
	assert_bool(jam.laughs()).is_false()
	jam.press(Enums.Note.UP if SETUP.melody.notes[3] != Enums.Note.UP else Enums.Note.DOWN)
	assert_int(jam.mismatches()).is_equal(3)
	assert_bool(jam.laughs()).is_true()
	jam.press(Enums.Note.UP if SETUP.melody.notes[4] != Enums.Note.UP else Enums.Note.DOWN)
	assert_bool(jam.laughs()).is_false()

func test_it_is_over_after_its_presses() -> void:
	var jam := GuitarJam.new(SETUP)
	for i: int in SETUP.max_presses - 1:
		jam.press(Enums.Note.UP)
	assert_bool(jam.is_over()).is_false()
	jam.press(Enums.Note.UP)
	assert_bool(jam.is_over()).is_true()
