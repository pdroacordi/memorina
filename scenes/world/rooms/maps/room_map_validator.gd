class_name RoomMapValidator extends RefCounted

## Validates parsed room text and placed-scene properties and links; importer and room-file checks share this validator.

static func validate(text: String, legend: RoomLegend, source: String) -> RoomMapParser.Result:
	var result := RoomMapParser.parse(text, legend, source)
	if not result.ok():
		return result
	var ids := {}
	for placed: Dictionary in result.map.entities:
		if placed.params.has(EntityParams.ID):
			ids[str(placed.params[EntityParams.ID])] = true
	for placed: Dictionary in result.map.entities:
		var entry := legend.entry(placed.symbol)
		for required: String in entry.required_params:
			if str(placed.params.get(required, "")).is_empty():
				result.errors.append("%s: entity '%s' at %s: needs a '%s' param" % [source, placed.symbol, placed.cell, required])
		var node := entry.scene.instantiate()
		for problem: String in EntityParams.check(node, placed.params):
			result.errors.append("%s: entity '%s' at %s: %s" % [source, placed.symbol, placed.cell, problem])
		for target: String in EntityParams.links(node, placed.params):
			if not ids.has(target):
				result.errors.append("%s: entity '%s' at %s: links to '%s', which no entity in the room is" % [source, placed.symbol, placed.cell, target])
		node.free()
	return result
