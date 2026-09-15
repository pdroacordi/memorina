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
