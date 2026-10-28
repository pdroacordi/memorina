class_name FoundCatalog
extends Resource
## The found pieces by slot id (design 07, architecture/found-pieces).

const DEFAULT_PATH := "res://resources/world/found/found_catalog.tres"

@export var pieces: Array[FoundPiece] = []


## The piece in `slot_id`; null when the slot holds none.
func get_piece(slot_id: StringName) -> FoundPiece:
	for piece: FoundPiece in pieces:
		if piece.slot_id == slot_id:
			return piece
	return null

## Every problem found; empty when valid. Each halved song in `songs` needs exactly one book.
func validate(songs: SongCatalog) -> PackedStringArray:
	var problems := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	var books: Dictionary[int, int] = {}
	for piece: FoundPiece in pieces:
		if piece == null or piece.slot_id == &"":
			problems.append("a piece has no slot id")
			continue
		if seen.has(piece.slot_id):
			problems.append("%s is listed twice" % piece.slot_id)
		seen[piece.slot_id] = true
		if piece.texture == null:
			problems.append("%s has no texture" % piece.slot_id)
		if piece.song != null:
			if not piece.song.learned_in_halves:
				problems.append("%s teaches song %d, which is not learned in halves" % [piece.slot_id, piece.song.id])
			books[piece.song.id] = books.get(piece.song.id, 0) + 1
	for song: Song in songs.songs:
		if song.learned_in_halves and books.get(song.id, 0) != 1:
			problems.append("song %d has %d songbooks" % [song.id, books.get(song.id, 0)])
	return problems
