extends Node

## Exports a room to `.room` and checks autotiled ground against the painted tiles; see docs/maps/README.md.
##
## Runs as a scene because entity scenes may reference autoloads such as SaveSystem:
##   "<godot>" --headless --path . res://tools/maps/export_room_map.tscn -- \
##       --contents=res://scenes/world/rooms/<region>/contents/<room>_contents.tscn \
##       --out=res://scenes/world/rooms/<region>/contents/<room>.room

var _ground := {}
var _water := {}
var _entities := {}

func _ready() -> void:
	var args := _args()
	var contents_path: String = args.get("contents", "")
	var out_path: String = args.get("out", "")
	assert(not contents_path.is_empty() and not out_path.is_empty(), "--contents= and --out= are required")
	var legend := RoomLegend.load_default()
	var root := (load(contents_path) as PackedScene).instantiate()
	var painted := root.get_node("TileMapLayer") as TileMapLayer
	assert(painted != null, "%s has no TileMapLayer to export" % contents_path)
	var cell_size := Vector2(painted.tile_set.tile_size)

	for cell: Vector2i in painted.get_used_cells():
		_ground[cell] = "#"
	for child: Node in root.get_children():
		if child is WaterLayer:
			_export_water(child as WaterLayer, legend, cell_size)
		else:
			_export_entity(child, legend, cell_size)

	var bounds := Rect2i(_ground.keys()[0], Vector2i.ONE)
	for layer: Dictionary in [_ground, _water]:
		for cell: Vector2i in layer:
			bounds = bounds.expand(cell).expand(cell + Vector2i.ONE)
	_extend_floors(bounds)
	var lines := PackedStringArray([
		"; %s" % out_path.get_file(),
		"; Exported from its painted TileMapLayer by tools/maps/export_room_map.gd.",
		"",
		"[room]",
		"origin = %d, %d" % [bounds.position.x, bounds.position.y],
		"",
		"[grid]",
	])
	lines.append_array(_rows(_ground, bounds))
	if not _water.is_empty():
		lines.append("")
		lines.append("[water]")
		lines.append_array(_rows(_water, bounds))
	lines.append("")
	lines.append("[entities]")
	for cell: Vector2i in _entities:
		lines.append("%d,%d = %s" % [cell.x - bounds.position.x, cell.y - bounds.position.y, JSON.stringify(_entities[cell])])
	var text := "\n".join(lines) + "\n"
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var kinds := {}
	for symbol: String in _water.values():
		kinds[symbol] = true
	print("Wrote %s: %dx%d cells, water %s, %d entit(ies)" % [out_path, bounds.size.x, bounds.size.y, kinds.keys(), _entities.size()])
	_compare(text, legend, painted, out_path)
	root.free()
	get_tree().quit()

## A painted floor was only as thick as the camera needed; in a map, ground
## below the bottom row is solid but ground INSIDE the map is what is written.
## So each column's lowest ground runs on down to the map's bottom, or a floor
## one cell thinner than its neighbours would show a rounded underside.
func _extend_floors(bounds: Rect2i) -> void:
	for x: int in range(bounds.position.x, bounds.end.x):
		var lowest := bounds.position.y - 1
		for y: int in range(bounds.position.y, bounds.end.y):
			if _ground.get(Vector2i(x, y), "") == "#":
				lowest = y
		if lowest < bounds.position.y:
			continue
		for y: int in range(lowest + 1, bounds.end.y):
			if not _ground.has(Vector2i(x, y)):
				_ground[Vector2i(x, y)] = "#"

func _rows(layer: Dictionary, bounds: Rect2i) -> PackedStringArray:
	var rows := PackedStringArray()
	for y: int in range(bounds.position.y, bounds.end.y):
		var row := ""
		for x: int in range(bounds.position.x, bounds.end.x):
			row += layer.get(Vector2i(x, y), RoomLegend.EMPTY)
		rows.append(row)
	return rows

func _export_water(layer: WaterLayer, legend: RoomLegend, cell_size: Vector2) -> void:
	var symbol := ""
	for entry: RoomLegendEntry in legend.entries:
		if entry.water_layer and entry.water_layer.resource_path == layer.scene_file_path:
			symbol = entry.symbol
	assert(not symbol.is_empty(), "no legend water for %s" % layer.scene_file_path)
	var fine := Vector2(layer.tile_set.tile_size)
	var per_cell := roundi((cell_size.x / fine.x) * (cell_size.y / fine.y))
	var counts := {}
	for cell: Vector2i in layer.get_used_cells():
		var world := layer.position + (Vector2(cell) + Vector2(0.5, 0.5)) * fine
		var coarse := Vector2i((world / cell_size).floor())
		counts[coarse] = counts.get(coarse, 0) + 1
	var partial: Array[Vector2i] = []
	for coarse: Vector2i in counts:
		if counts[coarse] < per_cell:
			partial.append(coarse)
		_water[coarse] = symbol
	if not partial.is_empty():
		print("  warning: %d cell(s) of '%s' were only partly painted and are now whole: %s" % [partial.size(), symbol, partial])

func _export_entity(node: Node, legend: RoomLegend, cell_size: Vector2) -> void:
	for entry: RoomLegendEntry in legend.entries:
		if entry.kind != RoomLegendEntry.Kind.ENTITY or entry.scene.resource_path != node.scene_file_path:
			continue
		var at := (node as Node2D).position
		var cell := Vector2i(floori(at.x / cell_size.x), roundi(at.y / cell_size.y) - 1)
		if entry.anchor == RoomLegendEntry.Anchor.CENTER:
			cell = Vector2i((at / cell_size).floor())
		_ground[cell] = entry.symbol
		_entities[cell] = {}
		print("  entity '%s' (%s) at %s -> cell %s" % [entry.symbol, node.name, at, cell])
		return

func _compare(text: String, legend: RoomLegend, painted: TileMapLayer, out_path: String) -> void:
	var result := RoomMapParser.parse(text, legend, out_path)
	for error: String in result.errors:
		print("  ERROR: %s" % error)
	var differ: Array[String] = []
	for cell: Vector2i in painted.get_used_cells():
		var was := painted.get_cell_atlas_coords(cell)
		var now := RoomMap.tile_coords(result.map.tile_at(cell))
		if was != now:
			differ.append("%s painted %s, autotile %s" % [cell, was, now])
	print("  %d of %d ground tiles differ from the paint" % [differ.size(), painted.get_used_cells().size()])
	for line: String in differ.slice(0, 40):
		print("    " + line)

func _args() -> Dictionary:
	var parsed := {}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var parts := arg.substr(2).split("=", true, 1)
			parsed[parts[0]] = parts[1]
	return parsed
