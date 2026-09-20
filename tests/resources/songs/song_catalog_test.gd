class_name SongCatalogTest extends GdUnitTestSuite

## Runs validate() against the catalog the game actually ships, so an
## authoring mistake in a .tres fails here rather than as a song that
## mysteriously never plays.

const CATALOG_PATH := "res://resources/songs/song_catalog.tres"

func _catalog() -> SongCatalog:
	return load(CATALOG_PATH) as SongCatalog

func test_the_shipped_catalog_loads() -> void:
	assert_object(_catalog()).is_not_null()

func test_the_shipped_catalog_is_valid() -> void:
	_catalog().validate()

func test_every_song_in_the_enum_is_present() -> void:
	var catalog := _catalog()
	for id: int in Enums.Song.size():
		assert_object(catalog.get_song(id)).is_not_null()

func test_each_season_carries_exactly_two_songs() -> void:
	var catalog := _catalog()
	for season: int in Enums.Season.size():
		assert_array(catalog.songs_for_season(season)).has_size(2)

func test_an_unknown_id_looks_up_to_nothing() -> void:
	assert_object(_catalog().get_song(Enums.Song.size() as Enums.Song)).is_null()

## The case a prefix test misses: neither sequence is a strict prefix of the
## other, but the matcher resolves on the first hit, so the second song would be
## unplayable forever.
func test_no_two_songs_share_an_identical_sequence() -> void:
	var seen: Dictionary = {}
	for song: Song in _catalog().songs:
		var key := str(song.notes)
		assert_bool(seen.has(key)).override_failure_message(
			"songs %d and %s have identical sequences" % [song.id, seen.get(key)]).is_false()
		seen[key] = song.id

## Every song needs a translation key, because none of these names may ever be
## a literal in a script or scene.
func test_every_song_and_season_has_a_translation_key() -> void:
	for song: Song in _catalog().songs:
		assert_str(song.name_key).is_not_empty()
		assert_str(song.palette.name_key).is_not_empty()

func test_every_song_is_six_notes_long() -> void:
	for song: Song in _catalog().songs:
		assert_array(song.notes).override_failure_message(
			"song %d is not %d notes long" % [song.id, Song.NOTE_COUNT]).has_size(Song.NOTE_COUNT)

func test_every_song_has_a_title_and_a_track() -> void:
	for song: Song in _catalog().songs:
		assert_str(song.title_key).override_failure_message("song %d has no title_key" % song.id).is_not_empty()
		assert_object(song.track).override_failure_message("song %d has no track" % song.id).is_not_null()
		assert_object(song.performance_stream()).is_not_null()

## cues() always yields one time per note, in playback order and before the
## excerpt is cut - whether authored or spaced evenly by the fallback - so the
## sheet lights every slot in order.
func test_every_song_yields_one_ascending_cue_per_note_inside_the_excerpt() -> void:
	for song: Song in _catalog().songs:
		var cues := song.cues()
		assert_int(cues.size()).override_failure_message(
			"song %d yields %d cues for %d notes" % [song.id, cues.size(), song.notes.size()]).is_equal(song.notes.size())
		for i: int in range(1, cues.size()):
			assert_float(cues[i]).override_failure_message(
				"song %d cue %d is not after cue %d" % [song.id, i, i - 1]).is_greater(cues[i - 1])
		if song.excerpt_duration > 0.0:
			assert_float(cues[-1]).override_failure_message(
				"song %d's last cue is after the excerpt cut" % song.id).is_less(song.excerpt_duration)

## An untuned or editor-stripped song still lights up: no cues in the data,
## six evenly-spaced ones out of cues().
func test_a_song_without_authored_cues_falls_back_to_even_spacing() -> void:
	var song := Song.new()
	song.notes = [Enums.Note.UP, Enums.Note.DOWN, Enums.Note.LEFT]
	song.excerpt_duration = 8.0
	assert_int(song.cues().size()).is_equal(3)
	assert_array(song.cues()).is_equal(PackedFloat32Array([2.0, 4.0, 6.0]))
