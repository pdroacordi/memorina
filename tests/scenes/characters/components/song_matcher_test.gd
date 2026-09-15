class_name SongMatcherTest extends GdUnitTestSuite

## SongMatcher is pure logic, so these run with no scene tree and no save file.

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

## A failure must leave the matcher ready for a fresh attempt straight away -
## the design calls for a silent reset, not a lockout.
func test_matcher_is_usable_again_after_a_failure() -> void:
	var freeze := _song(Enums.Song.FREEZE, [UP, LEFT, DOWN])
	var matcher := _matcher([freeze])
	matcher.feed(UP)
	matcher.feed(RIGHT)
	matcher.feed(UP)
	matcher.feed(LEFT)
	assert_int(matcher.feed(DOWN)).is_equal(SongMatcher.Result.MATCHED)

## Only songs the player knows are candidates, so an unknown song's sequence
## must read as noise rather than silently firing.
func test_a_song_outside_the_candidates_never_matches() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	assert_int(matcher.feed(RIGHT)).is_equal(SongMatcher.Result.FAILED)

func test_no_candidates_fails_instead_of_crashing() -> void:
	var matcher := SongMatcher.new()
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.FAILED)

func test_the_right_song_matches_when_several_share_a_prefix() -> void:
	var weaken := _song(Enums.Song.WEAKEN, [DOWN, LEFT, DOWN])
	var strip := _song(Enums.Song.STRIP, [DOWN, RIGHT, UP])
	var matcher := _matcher([weaken, strip])
	assert_int(matcher.feed(DOWN)).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(RIGHT)).is_equal(SongMatcher.Result.PROGRESS)
	assert_int(matcher.feed(UP)).is_equal(SongMatcher.Result.MATCHED)
	assert_object(matcher.matched_song()).is_same(strip)

func test_reset_discards_a_partial_sequence() -> void:
	var matcher := _matcher([_song(Enums.Song.FREEZE, [UP, LEFT, DOWN])])
	matcher.feed(UP)
	matcher.reset()
	assert_array(matcher.buffer()).is_empty()
	assert_int(matcher.feed(LEFT)).is_equal(SongMatcher.Result.FAILED)

## The buffer is a read-out, not a handle on the matcher's state.
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
