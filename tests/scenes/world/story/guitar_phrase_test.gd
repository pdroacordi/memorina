class_name GuitarPhraseTest extends GdUnitTestSuite

## Before the gap a right note plays, a wrong one sounds and changes nothing; at the gap every press is dead; and no
## sequence of presses ever finishes the song (systems/story).

const FIRST := preload("res://resources/story/guitar_first.tres")
const AGAIN := preload("res://resources/story/guitar_again.tres")


func test_the_two_attempts_stop_one_note_apart() -> void:
	assert_int(FIRST.gap_index).is_equal(5)
	assert_int(AGAIN.gap_index).is_equal(4)
	assert_object(FIRST.melody).is_same(AGAIN.melody)

func test_right_notes_play_until_the_gap_then_every_press_is_dead() -> void:
	var phrase := GuitarPhrase.new(FIRST)
	var notes := FIRST.melody.notes
	for i: int in FIRST.gap_index:
		assert_int(phrase.press(notes[i])).is_equal(GuitarPhrase.Press.PLAYED)
	assert_bool(phrase.at_gap()).is_true()
	assert_int(phrase.press(notes[FIRST.gap_index])).is_equal(GuitarPhrase.Press.DEAD)
	for note: int in Enums.Note.values():
		assert_int(phrase.press(note)).is_equal(GuitarPhrase.Press.DEAD)
	assert_int(phrase.played()).is_equal(FIRST.gap_index)
	assert_int(phrase.dead_presses()).is_equal(5)

## "Sounds, doesn't advance (Recommended)" (user, 2026-10-15).
func test_a_wrong_note_before_the_gap_misses_and_does_not_advance() -> void:
	var phrase := GuitarPhrase.new(FIRST)
	var wrong := Enums.Note.UP if FIRST.melody.notes[0] != Enums.Note.UP else Enums.Note.DOWN
	assert_int(phrase.press(wrong)).is_equal(GuitarPhrase.Press.MISSED)
	assert_int(phrase.played()).is_equal(0)
	assert_int(phrase.press(FIRST.melody.notes[0])).is_equal(GuitarPhrase.Press.PLAYED)

## Every sequence of seven presses (all 4^7, past both gaps), and the whole melody played twice over, leave the song
## unfinished: `played() <= gap_index < notes.size()`.
func test_no_sequence_of_presses_finishes_the_song() -> void:
	for attempt: GuitarAttempt in [FIRST, AGAIN]:
		var length := attempt.melody.notes.size()
		assert_int(attempt.gap_index).is_less(length)
		var presses := 7
		var total := int(pow(4, presses))
		var best := 0
		for code: int in total:
			var phrase := GuitarPhrase.new(attempt)
			var rest := code
			for i: int in presses:
				phrase.press(rest % 4)
				rest /= 4
			best = maxi(best, phrase.played())
		assert_int(best).is_equal(attempt.gap_index)
		assert_int(best).is_less(length)
		var twice := GuitarPhrase.new(attempt)
		for note: Enums.Note in attempt.melody.notes + attempt.melody.notes:
			twice.press(note)
		assert_int(twice.played()).is_equal(attempt.gap_index)
