class_name FoundPiece
extends Resource
## What one COLLECTIBLE reward slot holds: a letter, or a songbook that teaches a song's second half (architecture/found-pieces).

## The RewardSlot that holds it; also the PIECE_FOUND fact id of its notebook entry.
@export var slot_id: StringName
## The id of the room whose `.room` holds the slot; a rumour reads its region (room_files_test pins it).
@export var room: StringName
## Drawn lying on the slot's floor.
@export var texture: Texture2D
## The song a songbook teaches the second half of; null for a letter.
@export var song: Song
