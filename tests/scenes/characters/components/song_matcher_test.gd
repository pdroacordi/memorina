class_name SongMatcherTest extends GdUnitTestSuite

## SongMatcher tests require no scene tree or save file.

const UP := Enums.Note.UP
const DOWN := Enums.Note.DOWN
const LEFT := Enums.Note.LEFT
const RIGHT := Enums.Note.RIGHT

func _song(id: Enums.Song, notes: Array[Enums.Note]) -> Song:
	var song := Song.new()
	song.id = id
	song.notes = notes
	return song

func _matcher(songs: Array[Song]) -> SongMatcher:
	var matcher := SongMatcher.new()
	matcher.set_candidates(songs)
	return matcher

func test_partial_sequence_reports_progress() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(LEFT)).is_equal(SongMatcher.Result.PROGRESS)
	assert_array(matcher.buffer()).is_equal([UP, LEFT])

func test_complete_sequence_matches_and_clears_buffer() -> void:
	var freeze := _song(Enums.Song.FREEZE, [UP, LEFT, DOWN])
	var matcher := _matcher([freeze])
	matcher.feed(UP)
	matcher.feed(LEFT)
	assert_int(matcher.feed(DOWN)).is_equal(SongMatcher.Result.MATCHED)
	assert_object(matcher.matched_song()).is_same(freeze)
	assert_array(matcher.buffer()).is_empty()

func test_wrong_note_fails_and_clears_buffer() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	matcher.feed(UP)
	assert_int(matcher.feed(RIGHT)).is_equal(SongMatcher.Result.FAILED)
	assert_array(matcher.buffer()).is_empty()
	assert_object(matcher.matched_song()).is_null()

## Failure resets the matcher without a lockout (docs/design/02_mecanicas.md section 6.2).
func test_matcher_is_usable_again_after_a_failure() -> void:
	var freeze := _song(Enums.Song.FREEZE, [UP, LEFT, DOWN])
	var matcher := _matcher([freeze])
	matcher.feed(UP)
	matcher.feed(RIGHT)
	matcher.feed(UP)
	matcher.feed(LEFT)
	assert_int(matcher.feed(DOWN)).is_equal(SongMatcher.Result.MATCHED)

## Only learned songs are candidates (docs/design/02_mecanicas.md section 6.2).
func test_a_song_outside_the_candidates_never_matches() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	assert_int(matcher.feed(RIGHT)).is_equal(SongMatcher.Result.FAILED)

func test_no_candidates_fails_instead_of_crashing() -> void:
	var matcher := SongMatcher.new()
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.FAILED)

func test_the_right_song_matches_when_several_share_a_prefix() -> void:
	var release := _song(Enums.Song.RELEASE, [DOWN, LEFT, DOWN])
	var gale := _song(Enums.Song.GALE, [DOWN, RIGHT, UP])
	var matcher := _matcher([release, gale])
	assert_int(matcher.feed(DOWN)).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(RIGHT)).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.MATCHED)
	assert_object(matcher.matched_song()).is_same(gale)

func test_reset_discards_a_partial_sequence() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	matcher.feed(UP)
	matcher.reset()
	assert_array(matcher.buffer()).is_empty()
	assert_int(matcher.feed(LEFT)).is_equal(SongMatcher.Result.FAILED)

## The returned buffer is a copy.
func test_buffer_returns_a_copy() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	matcher.feed(UP)
	var taken := matcher.buffer()
	taken.append(DOWN)
	assert_array(matcher.buffer()).has_size(1)

func test_setting_candidates_clears_a_sequence_in_flight() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	matcher.feed(UP)
	matcher.set_candidates([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	assert_array(matcher.buffer()).is_empty()

#############################################
##  H A L F   S O N G S                    ##
#############################################

const FIRST_HALF: Array[bool] = [true, true, true, false, false, false]
const SECOND_HALF: Array[bool] = [false, false, false, true, true, true]

func _jar() -> Song:
	return _song(Enums.Song.BELL_JAR, [UP, UP, DOWN, LEFT, RIGHT, DOWN])

func _half_matcher(known: Array[bool], whole: Array[Song] = []) -> SongMatcher:
	var matcher := SongMatcher.new()
	matcher.set_candidates(whole, [SongCandidate.new(_jar(), known)])
	return matcher

func _feed_all(matcher: SongMatcher, notes: Array[Enums.Note]) -> SongMatcher.Result:
	var result := SongMatcher.Result.PROGRESS
	for note: Enums.Note in notes:
		result = matcher.feed(note)
	return result

func test_a_wrong_known_note_is_rejected() -> void:
	var matcher := _half_matcher(FIRST_HALF)
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(LEFT)).is_equal(SongMatcher.Result.FAILED)

func test_blanks_take_any_note() -> void:
	var matcher := _half_matcher(FIRST_HALF)
	assert_int(_feed_all(matcher, [UP, UP, DOWN, UP, UP])).is_equal(SongMatcher.Result.PROGRESS)

func test_a_wrong_guess_fails_on_the_sixth() -> void:
	var matcher := _half_matcher(FIRST_HALF)
	assert_int(_feed_all(matcher, [UP, UP, DOWN, LEFT, RIGHT, UP])).is_equal(SongMatcher.Result.FAILED)
	assert_array(matcher.buffer()).is_empty()

func test_a_right_guess_matches_by_ear() -> void:
	var matcher := _half_matcher(FIRST_HALF)
	assert_int(_feed_all(matcher, [UP, UP, DOWN, LEFT, RIGHT, DOWN])).is_equal(SongMatcher.Result.MATCHED)
	assert_int(matcher.matched_song().id).is_equal(Enums.Song.BELL_JAR)
	assert_bool(matcher.matched_by_ear()).is_true()

func test_a_second_half_candidate_checks_four_to_six() -> void:
	var matcher := _half_matcher(SECOND_HALF)
	assert_int(_feed_all(matcher, [RIGHT, RIGHT, RIGHT])).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.FAILED)
	assert_int(_feed_all(matcher, [UP, UP, DOWN, LEFT, RIGHT, DOWN])).is_equal(SongMatcher.Result.MATCHED)
	assert_bool(matcher.matched_by_ear()).is_true()

func test_a_whole_song_beside_a_partial_is_not_by_ear() -> void:
	var freeze := _song(Enums.Song.FREEZE, [UP, UP, DOWN, RIGHT, RIGHT, RIGHT])
	var matcher := _half_matcher(FIRST_HALF, [freeze])
	assert_int(_feed_all(matcher, freeze.notes)).is_equal(SongMatcher.Result.MATCHED)
	assert_int(matcher.matched_song().id).is_equal(Enums.Song.FREEZE)
	assert_bool(matcher.matched_by_ear()).is_false()

## Accepted consequence (architecture/half-songs, Q10): a known song's typo is held until the blanks run out.
func test_blanks_suspend_early_rejection_of_other_songs() -> void:
	var freeze := _song(Enums.Song.FREEZE, [DOWN, DOWN, DOWN, LEFT, LEFT, LEFT])
	var matcher := _half_matcher(SECOND_HALF, [freeze])
	assert_int(_feed_all(matcher, [DOWN, UP, UP])).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.FAILED)
