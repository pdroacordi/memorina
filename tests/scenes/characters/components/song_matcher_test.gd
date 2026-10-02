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
