class_name FlashbackRoomsTest extends GdUnitTestSuite

## Nothing in the past can hurt Ivo or keep anything (architecture/story-05-playable-flashbacks): no creature, hazard,
## bench, door, pickup or reward slot, and its water and the present garden's are shallow, so nobody drowns there.

const PAST_REGION := "res://scenes/world/rooms/past.tscn"
const PRESENT_GARDEN := "res://scenes/world/rooms/home_village/village_garden.tscn"
const GAME := "res://scenes/world/game.tscn"


func _past_rooms() -> Array[Room]:
	var region := (load(PAST_REGION) as PackedScene).instantiate() as Region
	var rooms: Array[Room] = []
	for child: Node in region.get_children():
		if child is Room:
			rooms.append(child as Room)
	for room: Room in rooms:
		region.remove_child(room)
	region.free()
	return rooms

func _map_of(room: Room) -> RoomMap:
	var contents := room.contents_scene.instantiate() as Node2D
	var path := ((contents.get_node("RoomMap") as RoomMapNode).map as RoomMap).resource_path
	contents.free()
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), RoomLegend.load_default(), path)
	assert_array(Array(result.errors)).override_failure_message("%s: %s" % [path, result.errors]).is_empty()
	return result.map

## The first harmful or keeping node under `root`, by path; empty when none.
func _harmful(root: Node) -> String:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if (node is Enemy or node is HazardZone or node is Bench or node is Door or node is ItemPickup
				or node is FoundPickup or node is CachePickup or node is RewardSlot):
			return str(node.name)
		stack.append_array(node.get_children())
	return ""

func test_the_game_places_the_past_and_it_holds_rooms() -> void:
	var state := (load(GAME) as PackedScene).get_state()
	var placed := false
	for i: int in state.get_node_count():
		var scene := state.get_node_instance(i)
		if scene != null and scene.resource_path == PAST_REGION:
			placed = true
	assert_bool(placed).is_true()
	var rooms := _past_rooms()
	assert_int(rooms.size()).is_greater(0)
	for room: Room in rooms:
		room.free()

func test_no_past_room_holds_anything_harmful() -> void:
	var legend := RoomLegend.load_default()
	for room: Room in _past_rooms():
		var contents := room.contents_scene.instantiate()
		assert_str(_harmful(contents)).override_failure_message("%s: %s" % [room.name, _harmful(contents)]).is_empty()
		contents.free()
		for placed: Dictionary in _map_of(room).entities:
			var entry := legend.entry(placed.symbol)
			var instance := entry.scene.instantiate()
			assert_str(_harmful(instance)).override_failure_message("%s: '%s' at %s" % [room.name, placed.symbol, placed.cell]) \
					.is_empty()
			instance.free()
		room.free()

## Every water cell is a WADE kind (a body with no hazard) one row deep over ground.
func _assert_shallow(room_name: String, map: RoomMap) -> void:
	for kind: Dictionary in [map.reach, map.shell_reach]:
		assert_dict(kind).override_failure_message("%s: water that rises" % room_name).is_empty()
	for symbol: String in map.water:
		var entry := map.legend.entry(symbol)
		assert_int(entry.reach_role).override_failure_message("%s: '%s' is not shallow" % [room_name, symbol]) \
				.is_equal(RoomLegendEntry.ReachRole.WADE)
		var layer := entry.water_layer.instantiate() as WaterLayer
		var body := layer.body_scene.instantiate()
		assert_str(_hazard_in(body)).override_failure_message("%s: '%s' pours a hazard" % [room_name, symbol]).is_empty()
		body.free()
		layer.free()
		for point: Vector2 in map.water[symbol]:
			var below := Vector2i(point) + Vector2i.DOWN
			assert_bool(map.is_solid(below)).override_failure_message("%s: water at %s is deeper than a row" % [room_name, point]) \
					.is_true()

func _hazard_in(root: Node) -> String:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is HazardZone:
			return str(node.name)
		stack.append_array(node.get_children())
	return ""

func test_the_pasts_water_is_shallow() -> void:
	for room: Room in _past_rooms():
		_assert_shallow(str(room.name), _map_of(room))
		room.free()

func test_ivo_never_drowns_in_the_present_garden() -> void:
	var garden := (load(PRESENT_GARDEN) as PackedScene).instantiate() as Room
	var map := _map_of(garden)
	assert_dict(map.water).is_not_empty()
	_assert_shallow("village_garden", map)
	garden.free()

## The ids a contents scene gives its cutscenes: actors, marks, visuals, blooms and named stagings, and Ivo.
func _cutscene_ids(root: Node) -> Array[StringName]:
	var ids: Array[StringName] = [CutsceneStep.IVO]
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is StoryActor:
			ids.append((node as StoryActor).actor_id)
		elif node is CutsceneMark:
			ids.append((node as CutsceneMark).mark_id)
		elif node is CutsceneVisual:
			ids.append((node as CutsceneVisual).visual_id)
		elif node is MemoryBloom:
			ids.append((node as MemoryBloom).bloom_id)
		elif node is FactStaging and (node as FactStaging).staging_id != &"":
			ids.append((node as FactStaging).staging_id)
		stack.append_array(node.get_children())
	return ids

## FlashbackDirector plays each opening on its past room's contents: every id it names resolves there
## (cutscene_rooms_test sees only the scenes a room starts itself).
func test_every_opening_names_ids_of_its_past_room() -> void:
	var catalog := load("res://resources/story/flashbacks/flashback_catalog.tres") as FlashbackCatalog
	assert_int(catalog.flashbacks.size()).is_greater(0)
	var rooms := _past_rooms()
	for flashback: Flashback in catalog.flashbacks:
		var past: Room = null
		for room: Room in rooms:
			if room.id() == flashback.past_room:
				past = room
		assert_object(past).override_failure_message("flashback %d: no past room '%s'" % [flashback.number,
				flashback.past_room]).is_not_null()
		if past == null:
			continue
		var contents := past.contents_scene.instantiate()
		var ids := _cutscene_ids(contents)
		for leaf: CutsceneStep in CutsceneCatalog.leaves(flashback.opening.steps):
			for id: StringName in leaf.names():
				assert_bool(ids.has(id)).override_failure_message("flashback %d: its opening names '%s'" % [flashback.number,
						id]).is_true()
		contents.free()
	for room: Room in rooms:
		room.free()
