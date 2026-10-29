class_name Rumours
extends RefCounted
## Which found piece a rumour points at, and which rumours still mark the map (systems/seeds-and-the-seller).


## The first piece in catalog order that still lies and was not rumoured; null when none is left.
static func next(found: FoundCatalog, data: PlayerData) -> FoundPiece:
	for piece: FoundPiece in found.pieces:
		if not data.rumours.has(piece.slot_id) and FoundPickup.lies(piece, data):
			return piece
	return null

## The rumoured pieces that still lie, in the order rumoured.
static func marked(found: FoundCatalog, data: PlayerData) -> Array[FoundPiece]:
	var pieces: Array[FoundPiece] = []
	for slot_id: StringName in data.rumours:
		var piece := found.get_piece(slot_id)
		if piece != null and FoundPickup.lies(piece, data):
			pieces.append(piece)
	return pieces
