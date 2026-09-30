class_name RoomMapValidator extends RefCounted

## Everything that makes a room map wrong, in one pass: what RoomMapParser
## finds in the text, plus what only the placed scenes can say - a param the
## entity does not have, or a value its property cannot take. The importer and
## the room-files suite both run this, so the game and the tests reject the
## same maps.

static func validate(text: String, legend: RoomLegend, source: String) -> RoomMapParser.Result:
	var result := RoomMapParser.parse(text, legend, source)
	if not result.ok():
		return result
	for placed: Dictionary in result.map.entities:
		var entry := legend.entry(placed.symbol)
		var node := entry.scene.instantiate()
		for problem: String in EntityParams.check(node, placed.params):
			result.errors.append("%s: entity '%s' at %s: %s" % [source, placed.symbol, placed.cell, problem])
		node.free()
	return result
