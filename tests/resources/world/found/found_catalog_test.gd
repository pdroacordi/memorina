class_name FoundCatalogTest extends GdUnitTestSuite

## The shipped catalog holds design 07's 17 pieces, one songbook per halved song on its approved slot.

const SONGS := preload("res://resources/songs/song_catalog.tres")
const LETTER := preload("res://assets/sprites/world/pickups/letter.png")
const BOOKS: Dictionary[StringName, Enums.Song] = {
	&"woods_hut_letter": Enums.Song.BELL_JAR,
	&"lake_shore_far_niche": Enums.Song.RAIN,
	&"caldera_seesaw_ledge": Enums.Song.GALE,
	&"orchard_ridge_letter": Enums.Song.SOLSTICE,
}

var _catalog: FoundCatalog


func before_test() -> void:
	_catalog = load(FoundCatalog.DEFAULT_PATH) as FoundCatalog

func test_the_shipped_catalog_is_valid() -> void:
	assert_array(Array(_catalog.validate(SONGS))).is_empty()
	assert_int(_catalog.pieces.size()).is_equal(17)

func test_the_books_lie_on_their_approved_slots() -> void:
	for slot_id: StringName in BOOKS:
		var piece := _catalog.get_piece(slot_id)
		assert_object(piece).is_not_null()
		assert_int(piece.song.id).is_equal(BOOKS[slot_id])
	var letters := _catalog.pieces.filter(func(piece: FoundPiece) -> bool: return piece.song == null)
	assert_int(letters.size()).is_equal(13)

func test_the_life_note_slot_holds_nothing() -> void:
	assert_object(_catalog.get_piece(&"caldera_temple_sanctum")).is_null()

## Each piece has exactly one Found notebook entry reading its slot id, so no entry is impossible to get.
func test_found_entries_and_pieces_are_one_to_one() -> void:
	var notebook := load("res://resources/ui/notebook/notebook_catalog.tres") as NotebookCatalog
	var entry_ids: Array[StringName] = []
	for entry: NotebookEntry in notebook.in_section(NotebookEntry.Section.FOUND):
		assert_int(entry.requirement).is_equal(SaveFact.Kind.PIECE_FOUND)
		entry_ids.append(entry.fact_id)
	var slot_ids: Array[StringName] = []
	for piece: FoundPiece in _catalog.pieces:
		slot_ids.append(piece.slot_id)
	assert_array(entry_ids).contains_exactly(slot_ids)

func test_a_bad_catalog_reports_each_problem() -> void:
	var bad := FoundCatalog.new()
	bad.pieces.append(_piece(&"a", LETTER, null))
	bad.pieces.append(_piece(&"a", null, null))
	bad.pieces.append(_piece(&"b", LETTER, SONGS.get_song(Enums.Song.FREEZE)))
	var problems := "\n".join(bad.validate(SONGS))
	assert_str(problems).contains("a is listed twice")
	assert_str(problems).contains("a has no texture")
	assert_str(problems).contains("not learned in halves")
	assert_str(problems).contains("song %d has 0 songbooks" % Enums.Song.BELL_JAR)

func _piece(slot_id: StringName, texture: Texture2D, song: Song) -> FoundPiece:
	var piece := FoundPiece.new()
	piece.slot_id = slot_id
	piece.texture = texture
	piece.song = song
	return piece
