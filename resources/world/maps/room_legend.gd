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
			RoomLegendEntry.Kind.ROOF:
				if candidate.ground == Enums.Ground.NONE:
					found.append("roof '%s' has no material" % candidate.symbol)
			RoomLegendEntry.Kind.GROUND, RoomLegendEntry.Kind.PLATFORM:
				if candidate.ground == Enums.Ground.NONE:
					found.append("ground '%s' has no material" % candidate.symbol)
				if candidate.look == BiomeTileset.Look.WALL:
					found.append("ground '%s' cannot have the wall look: walls are [back] only" % candidate.symbol)
			RoomLegendEntry.Kind.BACK:
				if candidate.ground != Enums.Ground.NONE:
					found.append("back wall '%s' cannot have a material" % candidate.symbol)
			RoomLegendEntry.Kind.SECRET:
				if candidate.ground != Enums.Ground.NONE:
					found.append("secret '%s' cannot have a material: a secret cell is air" % candidate.symbol)
				if candidate.look == BiomeTileset.Look.WALL:
					found.append("secret '%s' cannot have the wall look" % candidate.symbol)
	return found
