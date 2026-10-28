class_name SongHalvesTest extends GdUnitTestSuite

## How halves, guesses and found halves combine in the save (architecture/half-songs).

const SONG := Enums.Song.BELL_JAR

func test_one_half_leaves_the_song_unlearned() -> void:
	var data := PlayerData.new()
	assert_bool(SongHalves.teach(data, SONG, Enums.SongHalf.FIRST)).is_true()
	assert_bool(data.learned_songs[SONG]).is_false()
	assert_int(SongHalves.state(data, SONG)).is_equal(SongHalves.State.FIRST_HALF)

func test_both_halves_in_either_order_learn_it() -> void:
	for order: Array in [[Enums.SongHalf.FIRST, Enums.SongHalf.SECOND], [Enums.SongHalf.SECOND, Enums.SongHalf.FIRST]]:
		var data := PlayerData.new()
		SongHalves.teach(data, SONG, order[0])
		assert_int(SongHalves.state(data, SONG)).is_not_equal(SongHalves.State.LEARNED)
		SongHalves.teach(data, SONG, order[1])
		assert_bool(data.learned_songs[SONG]).is_true()
		assert_int(SongHalves.state(data, SONG)).is_equal(SongHalves.State.LEARNED)

func test_a_known_half_changes_nothing() -> void:
	var data := PlayerData.new()
	SongHalves.teach(data, SONG, Enums.SongHalf.SECOND)
	assert_bool(SongHalves.teach(data, SONG, Enums.SongHalf.SECOND)).is_false()

func test_a_guess_records_the_missing_half() -> void:
	for known: Enums.SongHalf in [Enums.SongHalf.FIRST, Enums.SongHalf.SECOND]:
		var data := PlayerData.new()
		SongHalves.teach(data, SONG, known)
		assert_bool(SongHalves.guess(data, SONG)).is_true()
		assert_bool(data.learned_songs[SONG]).is_true()
		var expected := Enums.SongHalf.SECOND if known == Enums.SongHalf.FIRST else Enums.SongHalf.FIRST
		assert_int(data.guessed_halves[SONG]).is_equal(expected)
		assert_int(SongHalves.state(data, SONG)).is_equal(SongHalves.State.BY_EAR)

func test_a_guess_needs_exactly_one_half() -> void:
	var data := PlayerData.new()
	assert_bool(SongHalves.guess(data, SONG)).is_false()
	SongHalves.teach(data, SONG, Enums.SongHalf.FIRST)
	SongHalves.teach(data, SONG, Enums.SongHalf.SECOND)
	assert_bool(SongHalves.guess(data, SONG)).is_false()
	assert_int(data.guessed_halves[SONG]).is_equal(Enums.SongHalf.NONE)

func test_finding_the_guessed_half_confirms() -> void:
	var data := PlayerData.new()
	SongHalves.teach(data, SONG, Enums.SongHalf.FIRST)
	SongHalves.guess(data, SONG)
	assert_bool(SongHalves.teach(data, SONG, Enums.SongHalf.SECOND)).is_true()
	assert_int(SongHalves.state(data, SONG)).is_equal(SongHalves.State.BY_EAR_CONFIRMED)

func test_masks_per_state() -> void:
	var data := PlayerData.new()
	SongHalves.teach(data, SONG, Enums.SongHalf.SECOND)
	assert_array(SongHalves.known_mask(data, SONG)).is_equal([false, false, false, true, true, true])
	assert_array(SongHalves.guessed_mask(data, SONG)).is_equal([false, false, false, false, false, false])
	SongHalves.guess(data, SONG)
	assert_array(SongHalves.known_mask(data, SONG)).is_equal([true, true, true, true, true, true])
	assert_array(SongHalves.guessed_mask(data, SONG)).is_equal([true, true, true, false, false, false])

func test_a_song_learned_whole_is_learned() -> void:
	var data := PlayerData.new()
	data.learned_songs[SONG] = true
	assert_int(SongHalves.state(data, SONG)).is_equal(SongHalves.State.LEARNED)
	assert_int(SongHalves.missing(data, SONG)).is_equal(Enums.SongHalf.NONE)

## A songbook's rule (architecture/found-pieces): a half teaches while unknown, unless the song is learned without guessing it.
func test_can_teach_per_state() -> void:
	var data := PlayerData.new()
	assert_bool(SongHalves.can_teach(data, SONG, Enums.SongHalf.SECOND)).is_true()
	SongHalves.teach(data, SONG, Enums.SongHalf.FIRST)
	assert_bool(SongHalves.can_teach(data, SONG, Enums.SongHalf.FIRST)).is_false()
	assert_bool(SongHalves.can_teach(data, SONG, Enums.SongHalf.SECOND)).is_true()
	SongHalves.guess(data, SONG)
	assert_bool(SongHalves.can_teach(data, SONG, Enums.SongHalf.SECOND)).is_true()
	SongHalves.teach(data, SONG, Enums.SongHalf.SECOND)
	assert_bool(SongHalves.can_teach(data, SONG, Enums.SongHalf.SECOND)).is_false()
	var whole := PlayerData.new()
	whole.learned_songs[SONG] = true
	assert_bool(SongHalves.can_teach(whole, SONG, Enums.SongHalf.SECOND)).is_false()
	var guessed_first := PlayerData.new()
	SongHalves.teach(guessed_first, SONG, Enums.SongHalf.SECOND)
	SongHalves.guess(guessed_first, SONG)
	assert_bool(SongHalves.can_teach(guessed_first, SONG, Enums.SongHalf.FIRST)).is_true()
	assert_bool(SongHalves.can_teach(guessed_first, SONG, Enums.SongHalf.SECOND)).is_false()

func test_part_known_is_a_save_fact() -> void:
	var data := PlayerData.new()
	assert_bool(SaveFact.check(SaveFact.Kind.SONG_PART_KNOWN, SONG, data)).is_false()
	SongHalves.teach(data, SONG, Enums.SongHalf.FIRST)
	assert_bool(SaveFact.check(SaveFact.Kind.SONG_PART_KNOWN, SONG, data)).is_true()
	assert_bool(SaveFact.check(SaveFact.Kind.SONG, SONG, data)).is_false()

func test_an_old_save_grows_the_half_arrays() -> void:
	var data := PlayerData.new()
	data.song_first_halves.clear()
	data.guessed_halves.clear()
	data.migrate()
	assert_int(data.song_first_halves.size()).is_equal(Enums.Song.size())
	assert_int(data.guessed_halves.size()).is_equal(Enums.Song.size())
	assert_int(data.guessed_halves[SONG]).is_equal(Enums.SongHalf.NONE)
