@tool
class_name RoomLegend extends Resource

## Room-map symbols are defined in docs/maps/README.md; `.` is reserved for empty cells.

const DEFAULT_PATH := "res://resources/world/maps/room_legend.tres"
const EMPTY := "."

@export var entries: Array[RoomLegendEntry] = []

static func load_default() -> RoomLegend:
	return load(DEFAULT_PATH) as RoomLegend

func entry(symbol: String) -> RoomLegendEntry:
	for candidate: RoomLegendEntry in entries:
		if candidate.symbol == symbol:
			return candidate
	return null

## Duplicate or malformed symbols, as messages; empty when the legend is sound.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	var seen := {}
	for candidate: RoomLegendEntry in entries:
		if candidate.symbol.length() != 1:
			found.append("symbol '%s' is not exactly one character" % candidate.symbol)
		elif candidate.symbol == EMPTY:
			found.append("'%s' is reserved for empty cells" % EMPTY)
		elif seen.has(candidate.symbol):
			found.append("symbol '%s' is defined twice" % candidate.symbol)
		seen[candidate.symbol] = true
		match candidate.kind:
			RoomLegendEntry.Kind.WATER:
				if candidate.water_layer == null:
					found.append("water '%s' has no water_layer" % candidate.symbol)
				if candidate.reach and not candidate.takes_reach:
					found.append("reach '%s' cannot refuse a reach" % candidate.symbol)
			RoomLegendEntry.Kind.ENTITY:
				if candidate.scene == null:
					found.append("entity '%s' has no scene" % candidate.symbol)
	return found
