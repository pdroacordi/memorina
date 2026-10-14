class_name ReachPuzzles extends Resource

## What each world mover and song gate needs, keyed by room and entity id; ReachWorldLoader reports a placement with
## no entry and an entry with no placement (architecture/room-reachability-audit, TECH-08).

const DEFAULT_PATH := "res://resources/world/maps/reach_puzzles.tres"

@export var entries: Array[ReachPuzzle] = []

static func load_default() -> ReachPuzzles:
	return load(DEFAULT_PATH) as ReachPuzzles

## The entry for entity `id` of `room`, or null.
func find(room: StringName, id: StringName) -> ReachPuzzle:
	for entry: ReachPuzzle in entries:
		if entry.room == room and entry.id == id:
			return entry
	return null
