class_name PhraseEchoTest extends GdUnitTestSuite

## A teacher's phrase judged note by note, beside the song matcher (systems/teaching-creatures).

const L := Enums.Note.LEFT
const R := Enums.Note.RIGHT
const U := Enums.Note.UP


func _echo(phrase: Array[Enums.Note]) -> PhraseEcho:
	return PhraseEcho.new(phrase)

func test_right_notes_count() -> void:
	var echo := _echo([L, R, L])
	assert_int(echo.feed(L)).is_equal(PhraseEcho.Result.RIGHT)
	assert_int(echo.feed(R)).is_equal(PhraseEcho.Result.RIGHT)
	assert_int(echo.count()).is_equal(2)
	assert_bool(echo.is_complete()).is_false()

func test_the_third_completes() -> void:
	var echo := _echo([L, R, L])
	echo.feed(L)
	echo.feed(R)
	assert_int(echo.feed(L)).is_equal(PhraseEcho.Result.COMPLETE)
	assert_bool(echo.is_complete()).is_true()

func test_a_wrong_note_resets() -> void:
	var echo := _echo([L, R, L])
	echo.feed(L)
	assert_int(echo.feed(L)).is_equal(PhraseEcho.Result.WRONG)
	assert_int(echo.count()).is_equal(0)
	assert_int(echo.feed(L)).is_equal(PhraseEcho.Result.RIGHT)

func test_a_repeated_note_phrase() -> void:
	var echo := _echo([R, R, R])
	assert_int(echo.feed(R)).is_equal(PhraseEcho.Result.RIGHT)
	assert_int(echo.feed(R)).is_equal(PhraseEcho.Result.RIGHT)
	assert_int(echo.feed(R)).is_equal(PhraseEcho.Result.COMPLETE)

func test_notes_after_completion_are_ignored() -> void:
	var echo := _echo([R, R, R])
	for i: int in 3:
		echo.feed(R)
	assert_int(echo.feed(U)).is_equal(PhraseEcho.Result.IGNORED)
	assert_int(echo.feed(R)).is_equal(PhraseEcho.Result.IGNORED)
	assert_int(echo.count()).is_equal(3)

func test_reset_starts_over() -> void:
	var echo := _echo([L, R, L])
	echo.feed(L)
	echo.feed(R)
	echo.feed(L)
	echo.reset()
	assert_bool(echo.is_complete()).is_false()
	assert_int(echo.feed(L)).is_equal(PhraseEcho.Result.RIGHT)

## The echo keeps its own copy: changing the caller's array changes nothing.
func test_the_phrase_is_copied() -> void:
	var phrase: Array[Enums.Note] = [L, R, L]
	var echo := _echo(phrase)
	phrase[0] = U
	assert_int(echo.feed(L)).is_equal(PhraseEcho.Result.RIGHT)
