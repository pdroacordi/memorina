class_name ReachWorldLoader extends RefCounted

## Stitches every room the game places into one ReachGrid, songs assumed all at once
## (architecture/room-reachability-audit). Not pure: it instances region, mover and current scenes out of the tree.

const GAME := "res://scenes/world/game.tscn"
const REGION_SCRIPT := preload("res://scenes/world/rooms/region.gd")
## Read for Enraizar's reach at the wet length.
const ROOT_GROWER := "res://scenes/world/memory/song_effects/roots/root_grower.tscn"
const PLAYER := &"Player"

## Every region `game.tscn` places, its rooms parsed from their `.room` text (never a stale import); each mover and song
## gate keyed in ReachPuzzles for the kit check.
static func load_world() -> Loaded:
	var loaded := Loaded.new()
	var legend := RoomLegend.load_default()
	var roots := _root_reach()
	var puzzles := ReachPuzzles.load_default()
	var state := (load(GAME) as PackedScene).get_state()
	for i: int in state.get_node_count():
		if state.get_node_name(i) == PLAYER:
			var feet: Vector2 = _property(state, i, &"position", Vector2.ZERO)
			loaded.grid.set_start(Vector2i(floori(feet.x / RoomMap.CELL_PX), ceili(feet.y / RoomMap.CELL_PX) - 1))
		var scene := state.get_node_instance(i)
		if scene == null or scene.get_state().get_node_count() == 0 or _property(scene.get_state(), 0, &"script", null) != REGION_SCRIPT:
			continue
		var region := scene.instantiate() as Region
		# The state holds only what game.tscn overrides (gotchas/scene-state-lists-only-the-properties-a-scene-file-sets).
		region.position = _property(state, i, &"position", region.position)
		for child: Node in region.get_children():
			if child is Room:
				_add_room(loaded, child as Room, region, legend, roots, puzzles)
		region.free()
	for entry: ReachPuzzle in puzzles.entries:
		if not loaded.puzzles_met.has(entry):
			loaded.problems.append("%s: no mover or gate '%s' for its entry in %s" % [entry.room, entry.id, ReachPuzzles.DEFAULT_PATH])
		elif entry.reason.strip_edges().is_empty():
			loaded.problems.append("%s: the entry for '%s' in %s has no reason" % [entry.room, entry.id, ReachPuzzles.DEFAULT_PATH])
	var maps: Array[RoomMap] = []
	for i: int in loaded.grid.room_count():
		maps.append(loaded.maps[loaded.grid.room_id(i)])
	add_sky(loaded.grid, maps)
	return loaded

## Adds the sky bands over `grid`'s open tops; `maps[i]` is room i's map, in the order the rooms were added.
static func add_sky(grid: ReachGrid, maps: Array[RoomMap]) -> void:
	var rects: Array[Rect2] = []
	var closed: Array[PackedByteArray] = []
	for i: int in grid.room_count():
		var cells := grid.room_rect(i)
		rects.append(Rect2(cells.position * RoomMap.CELL_PX, cells.size * RoomMap.CELL_PX))
		closed.append(RoomEdges.closed_top(maps[i]))
	grid.add_bands(RoomEdges.band_cells(RoomEdges.bands(rects, closed)))

## Ivo's lattice: his jump from his real tuning, his footprint from his capsule.
static func ivo_lattice() -> ReachLattice:
	return ReachLattice.new(MapGuide.ivo_reach(), MapGuide.ivo_body())

static func _add_room(loaded: Loaded, room: Room, region: Region, legend: RoomLegend, roots: Dictionary, puzzles: ReachPuzzles) -> void:
	var offset := region.position
	var shape_node := room.get_node("CollisionShape2D") as CollisionShape2D
	var size := (shape_node.shape as RectangleShape2D).size
	var bounds := Rect2(offset + room.position + shape_node.position - size * 0.5, size)
	var contents := room.contents_scene.get_state()
	_add_guardians(loaded.grid, contents, room.id())
	var i := Room.map_node(contents)
	if i < 0:
		loaded.problems.append("%s: its contents have no RoomMap" % room.id())
		return
	var path := (_property(contents, i, &"map", null) as RoomMap).resource_path
	var parsed := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
	var map := parsed.map
	for error: String in parsed.errors:
		loaded.problems.append(error)
	var corner := offset + room.position + (_property(contents, i, &"position", Vector2.ZERO) as Vector2) + Vector2(map.origin * RoomMap.CELL_PX)
	if Rect2(corner, Vector2(map.size * RoomMap.CELL_PX)) != bounds:
		loaded.problems.append("%s: its map covers %s, its room %s" % [room.id(), Rect2(corner, Vector2(map.size * RoomMap.CELL_PX)), bounds])
		return
	var cell_origin := Vector2i(corner / RoomMap.CELL_PX)
	loaded.grid.add_room(room.id(), map, cell_origin, StringName(region.scene_file_path.get_file().get_basename()))
	loaded.maps[room.id()] = map
	loaded.grid.add_roots(RootSpanFinder.find(map, roots.bridge, roots.shaft_width, roots.shaft_rows, roots.pillar), map, cell_origin, roots.dry_bridge)
	var problems := add_movers(loaded.grid, map, cell_origin, room.id(), puzzles, loaded.puzzles_met)
	loaded.problems.append_array(problems)

# Each guardian a room's contents place (an instanced scene whose `stats` is a GuardianStats), keyed by its id.
static func _add_guardians(grid: ReachGrid, contents: SceneState, room: StringName) -> void:
	for j: int in contents.get_node_count():
		var scene := contents.get_node_instance(j)
		if scene == null:
			continue
		var stats: Variant = _property(contents, j, &"stats", _property(scene.get_state(), 0, &"stats", null))
		if stats is GuardianStats:
			grid.guardians[(stats as GuardianStats).id] = room

## Adds the floors `map`'s movers sweep, its currents' boxes and downwind edges, its stairs' ends and its gates' closed
## bodies, from each entity's own authored values; `map.origin` sits at world cell `cell_origin`. With `puzzles`, a mover
## or a gate with no save fact of its own takes its need from the entry for `room` and its id, and each entry used is
## added to `met`; returns the placements with none.
static func add_movers(grid: ReachGrid, map: RoomMap, cell_origin: Vector2i, room: StringName = &"", puzzles: ReachPuzzles = null, met: Dictionary[ReachPuzzle, bool] = {}) -> PackedStringArray:
	var problems := PackedStringArray()
	for placed: Dictionary in map.entities:
		var entry := map.legend.entry(placed.symbol)
		if not entry.reach_role in [RoomLegendEntry.ReachRole.MOVER, RoomLegendEntry.ReachRole.CURRENT, RoomLegendEntry.ReachRole.STAIR, RoomLegendEntry.ReachRole.GATE]:
			continue
		var node := entry.scene.instantiate() as Node2D
		EntityParams.apply(node, placed.params)
		var at := RoomMapNode.entity_position(placed.cell, entry.anchor)
		match entry.reach_role:
			RoomLegendEntry.ReachRole.STAIR:
				var ends := _world(node.call(&"reach_ends", placed.cell), map, cell_origin)
				grid.add_stair(ends[0], ends[1])
			RoomLegendEntry.ReachRole.MOVER:
				var need := _need(node, placed, room, puzzles, met, problems)
				grid.add_cells(_world(node.call(&"reach_cells", map, at), map, cell_origin), ReachGrid.SONG_FLOOR, need)
			RoomLegendEntry.ReachRole.GATE:
				var need := _need(node, placed, room, puzzles, met, problems)
				grid.add_walls(_world(node.call(&"reach_wall_cells", map, at), map, cell_origin), need)
			_:
				grid.add_cells(_world(node.call(&"reach_cells", map, at), map, cell_origin), ReachGrid.CURRENT)
				grid.add_cells(_world(node.call(&"reach_exit_cells", map, at), map, cell_origin), ReachGrid.CURRENT_EXIT)
		node.free()
	return problems

# The facts a mover or gate needs: its own (`reach_needs`), else its ReachPuzzles entry's songs.
static func _need(node: Node, placed: Dictionary, room: StringName, puzzles: ReachPuzzles, met: Dictionary[ReachPuzzle, bool], problems: PackedStringArray) -> PackedInt32Array:
	if node.has_method(&"reach_needs"):
		var facts: Array[SaveFact] = []
		facts.assign(node.call(&"reach_needs"))
		return ReachKit.opened_by(facts)
	var need := PackedInt32Array()
	if puzzles == null:
		return need
	var id := StringName(str(placed.params.get(EntityParams.ID, "")))
	var entry := puzzles.find(room, id)
	if entry == null:
		problems.append("%s: '%s' at %s needs an entry in %s (the songs its puzzle needs)" % [room, id, placed.cell, ReachPuzzles.DEFAULT_PATH])
		return need
	met[entry] = true
	return entry.need()

static func _world(cells: Array, map: RoomMap, cell_origin: Vector2i) -> Array[Vector2i]:
	var world: Array[Vector2i] = []
	for cell: Vector2i in cells:
		world.append(cell_origin - map.origin + cell)
	return world

static func _root_reach() -> Dictionary:
	var grower := (load(ROOT_GROWER) as PackedScene).instantiate() as RootGrower
	var reach := {
		"bridge": grower.wet_bridge_cells,
		"dry_bridge": grower.max_bridge_cells,
		"shaft_width": grower.max_shaft_width,
		"shaft_rows": grower.min_shaft_rows,
		"pillar": grower.max_pillar_cells,
	}
	grower.free()
	return reach

static func _property(state: SceneState, node: int, property: StringName, fallback: Variant) -> Variant:
	for j: int in state.get_node_property_count(node):
		if state.get_node_property_name(node, j) == property:
			return state.get_node_property_value(node, j)
	return fallback

## The stitched grid, every room's map by room id, and what failed to load.
class Loaded:
	var grid := ReachGrid.new()
	var maps: Dictionary[StringName, RoomMap] = {}
	var problems := PackedStringArray()
	## Each ReachPuzzles entry a placement used.
	var puzzles_met: Dictionary[ReachPuzzle, bool] = {}
