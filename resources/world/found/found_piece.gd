class_name FoundPiece
extends Resource
## What one COLLECTIBLE reward slot holds: a letter, or a songbook that teaches a song's second half (architecture/found-pieces).

## The RewardSlot that holds it; also the PIECE_FOUND fact id of its notebook entry.
@export var slot_id: StringName
## Drawn lying on the slot's floor.
@export var texture: Texture2D
## The song a songbook teaches the second half of; null for a letter.
@export var song: Song
