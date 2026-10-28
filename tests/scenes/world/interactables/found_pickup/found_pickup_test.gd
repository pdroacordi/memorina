class_name FoundPickupTest extends GdUnitTestSuite

## A letter lies until taken; a songbook lies while its second half would teach; both follow the save both ways.

const PICKUP := preload("res://scenes/world/interactables/found_pickup/found_pickup.tscn")
const LETTER := preload("res://assets/sprites/world/pickups/letter.png")
const BOOK := preload("res://assets/sprites/world/pickups/songbook.png")
const BELL_JAR := preload("res://resources/songs/bell_jar.tres")

var _letter: FoundPiece
var _book: FoundPiece


func before_test() -> void:
	SaveSystem.begin("", true)
	SaveSystem.commit()
	_letter = _piece(&"woods_hut_letter", LETTER, null)
	_book = _piece(&"woods_root_caves_alcove", BOOK, BELL_JAR)

func after_test() -> void:
	SaveSystem.begin("", true)

func _piece(slot_id: StringName, texture: Texture2D, song: Song) -> FoundPiece:
	var piece := FoundPiece.new()
	piece.slot_id = slot_id
	piece.texture = texture
	piece.song = song
	return piece

func _make(piece: FoundPiece) -> FoundPickup:
	var made := auto_free(PICKUP.instantiate()) as FoundPickup
	made.piece = piece
	add_child(made)
	return made

func test_a_letter_lies_until_found() -> void:
	var data := PlayerData.new()
	assert_bool(FoundPickup.lies(_letter, data)).is_true()
	data.found_pieces.append(&"woods_hut_letter")
	assert_bool(FoundPickup.lies(_letter, data)).is_false()

func test_a_songbook_lies_while_its_half_would_teach() -> void:
	var data := PlayerData.new()
	var song := Enums.Song.BELL_JAR
	assert_bool(FoundPickup.lies(_book, data)).is_true()
	data.song_first_halves[song] = true
	assert_bool(FoundPickup.lies(_book, data)).is_true()
	data.song_second_halves[song] = true
	assert_bool(FoundPickup.lies(_book, data)).is_false()

func test_a_songbook_lies_for_a_guessed_second_half_only() -> void:
	var data := PlayerData.new()
	var song := Enums.Song.BELL_JAR
	data.learned_songs[song] = true
	assert_bool(FoundPickup.lies(_book, data)).is_false()
	data.guessed_halves[song] = Enums.SongHalf.SECOND
	assert_bool(FoundPickup.lies(_book, data)).is_true()
	data.guessed_halves[song] = Enums.SongHalf.FIRST
	assert_bool(FoundPickup.lies(_book, data)).is_false()

func test_taking_a_letter_records_it_and_hides_it() -> void:
	var pickup := _make(_letter)
	var taken: Array[StringName] = []
	pickup.taken.connect(func(slot_id: StringName) -> void: taken.append(slot_id))
	assert_bool(pickup.is_available()).is_true()
	pickup.take()
	assert_bool(SaveSystem.has_found(&"woods_hut_letter")).is_true()
	assert_bool(pickup.is_lying()).is_false()
	assert_bool(pickup.is_available()).is_false()
	assert_array(taken).is_equal([&"woods_hut_letter"])

func test_a_book_teaches_its_song_and_a_letter_none() -> void:
	assert_object(_make(_book).teaches()).is_same(BELL_JAR)
	assert_object(_make(_letter).teaches()).is_null()

## A death before a bench forgets the take; the rebuilt world's pickup reads the rewound save on ready.
func test_a_rewind_puts_it_back() -> void:
	_make(_letter).take()
	SaveSystem.rewind()
	assert_bool(_make(_letter).is_lying()).is_true()

func test_the_prompt_stands_over_the_reach_and_starts_hidden() -> void:
	var pickup := _make(_letter)
	var prompt := pickup.get_node("Prompt") as Control
	assert_float(prompt.position.y + prompt.size.y).is_less(-2.0 * RoomMap.CELL_PX)
	assert_bool(prompt.visible).is_false()
