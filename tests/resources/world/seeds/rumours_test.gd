class_name RumoursTest extends GdUnitTestSuite

## A rumour points at the first piece in catalog order that still lies and was not told; a mark goes once the piece is taken.

const SONGS := preload("res://resources/songs/song_catalog.tres")
const LETTER := preload("res://assets/sprites/world/pickups/letter.png")

var _found: FoundCatalog


func before_test() -> void:
	_found = FoundCatalog.new()
	_found.pieces.append(_piece(&"book", SONGS.get_song(Enums.Song.BELL_JAR)))
	_found.pieces.append(_piece(&"letter_a", null))
	_found.pieces.append(_piece(&"letter_b", null))

func test_next_follows_catalog_order_and_skips_told_pieces() -> void:
	var data := PlayerData.new()
	assert_str(String(Rumours.next(_found, data).slot_id)).is_equal("book")
	data.rumours.append(&"book")
	assert_str(String(Rumours.next(_found, data).slot_id)).is_equal("letter_a")

func test_next_skips_a_taken_letter_and_a_book_that_cannot_teach() -> void:
	var data := PlayerData.new()
	data.song_second_halves[Enums.Song.BELL_JAR] = true
	data.found_pieces.append(&"letter_a")
	assert_str(String(Rumours.next(_found, data).slot_id)).is_equal("letter_b")

func test_next_is_null_when_none_is_left() -> void:
	var data := PlayerData.new()
	data.rumours.append_array([&"book", &"letter_a", &"letter_b"])
	assert_object(Rumours.next(_found, data)).is_null()

func test_marked_drops_a_taken_piece() -> void:
	var data := PlayerData.new()
	data.rumours.append_array([&"letter_b", &"letter_a"])
	assert_int(Rumours.marked(_found, data).size()).is_equal(2)
	assert_str(String(Rumours.marked(_found, data)[0].slot_id)).is_equal("letter_b")
	data.found_pieces.append(&"letter_b")
	var marked := Rumours.marked(_found, data)
	assert_int(marked.size()).is_equal(1)
	assert_str(String(marked[0].slot_id)).is_equal("letter_a")

func _piece(slot_id: StringName, song: Song) -> FoundPiece:
	var piece := FoundPiece.new()
	piece.slot_id = slot_id
	piece.texture = LETTER
	piece.song = song
	return piece
