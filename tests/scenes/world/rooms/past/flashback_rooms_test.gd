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

## The arena exit rooms that hold flashback 2's ribbon, by the guardian whose region it is in (user, 2026-11-11:
## "Em toda região restaurada").
const RIBBON_ROOMS := {
	Enums.Guardian.FROST: "res://scenes/world/rooms/frozen_lake/contents/lake_glacier_contents.tscn",
	Enums.Guardian.BLOOM: "res://scenes/world/rooms/spring_woods/contents/woods_hollow_tree_contents.tscn",
	Enums.Guardian.AUTUMN: "res://scenes/world/rooms/wind_orchards/contents/orchard_cliff_chimney_contents.tscn",
	Enums.Guardian.SUMMER: "res://scenes/world/rooms/summer_caldera/contents/caldera_sun_stair_contents.tscn",
}

func _first(root: Node, script_class: Variant) -> Node:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if is_instance_of(node, script_class):
			return node
		stack.append_array(node.get_children())
	return null

func _flashback_2_due_with(restored: int) -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	data.restored_guardians[restored] = true
	data.scenes_seen.append(FlashbackSchedule.id(1))
	return data

## Each exit room shows its ribbon and offers its talk only while flashback 2 is due and its own guardian is restored,
## and its talk's beat plays the one shared crossing.
func test_a_ribbon_waits_in_each_restored_guardians_exit_room() -> void:
	var flashback := load("res://resources/story/flashbacks/flashback_2.tres") as Flashback
	for guardian: int in RIBBON_ROOMS:
		var contents := (load(RIBBON_ROOMS[guardian]) as PackedScene).instantiate()
		var staging := _first(contents, FactStaging) as FactStaging
		var talk := _first(contents, Talkable) as Talkable
		var beat := _first(contents, CutsceneBeat) as CutsceneBeat
		assert_str(String(staging.staging_id)).is_equal("ribbon_staging")
		assert_object(beat.cutscene).is_same(flashback.crossing)
		for restored: int in Enums.Guardian.values():
			var data := _flashback_2_due_with(restored)
			assert_int(FlashbackSchedule.due(data)).is_equal(2)
			var mine := restored == guardian
			assert_bool(FactStaging.pick(staging.stages, data) >= 0).override_failure_message(
					"%s with guardian %d restored" % [RIBBON_ROOMS[guardian].get_file(), restored]).is_equal(mine)
			assert_bool(talk.current(data) != null).is_equal(mine)
		var seen := _flashback_2_due_with(guardian)
		seen.scenes_seen.append(FlashbackSchedule.id(2))
		assert_int(FactStaging.pick(staging.stages, seen)).is_equal(-1)
		assert_object(talk.current(seen)).is_null()
		contents.free()

## A grey pocket keeps the ribbon the one colour in its restored region ("Um bolsão cinza em volta (Recommended)", user,
## 2026-11-12): a FactWell takes the memory around it to 0 exactly while the ribbon shows.
func test_a_grey_pocket_surrounds_the_ribbon_exactly_while_it_shows() -> void:
	for guardian: int in RIBBON_ROOMS:
		var contents := (load(RIBBON_ROOMS[guardian]) as PackedScene).instantiate()
		var staging := _first(contents, FactStaging) as FactStaging
		var well := _first(contents, FactWell) as FactWell
		var mark := contents.get_node("Flashbacks/RibbonMark") as Node2D
		var file := String(RIBBON_ROOMS[guardian]).get_file()
		assert_object(well).override_failure_message("%s has no grey pocket" % file).is_not_null()
		var source := well.source
		assert_int(source.shape).is_equal(MemoryFieldMath.Shape.CIRCLE)
		assert_bool(source.position.distance_to(mark.position) < source.radius).override_failure_message(file).is_true()
		var states: Array[PlayerData] = []
		for restored: int in Enums.Guardian.values():
			states.append(_flashback_2_due_with(restored))
		var seen := _flashback_2_due_with(guardian)
		seen.scenes_seen.append(FlashbackSchedule.id(2))
		states.append(seen)
		states.append(PlayerData.new())
		for data: PlayerData in states:
			var shown := FactStaging.pick(staging.stages, data) >= 0
			var strength := FactWell.strength_for(well.levels, data)
			assert_bool(strength < 0.0).override_failure_message("%s: pocket %f, ribbon shown %s" % [file, strength,
					shown]).is_equal(shown)
			if shown:
				# A restored region rests at 1: the pocket's core takes it to 0.
				assert_float(strength).is_equal(-1.0)
		contents.free()

const PRESENT_GARDEN_CONTENTS := "res://scenes/world/rooms/home_village/contents/village_garden_contents.tscn"
const PAST_GARDEN_CONTENTS := "res://scenes/world/rooms/past/contents/garden_past_contents.tscn"

func _flashback_3_due() -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	data.restored_guardians[Enums.Guardian.FROST] = true
	data.restored_guardians[Enums.Guardian.BLOOM] = true
	data.scenes_seen.append(FlashbackSchedule.id(1))
	data.scenes_seen.append(FlashbackSchedule.id(2))
	return data

## The fallen swing calls while flashback 3 is due: its talk holds Up to raise it, then plays the crossing; it lies
## fallen until the flashback is seen, then hangs.
func test_the_fallen_swing_raises_into_flashback_3() -> void:
	var flashback := load("res://resources/story/flashbacks/flashback_3.tres") as Flashback
	var contents := (load(PRESENT_GARDEN_CONTENTS) as PackedScene).instantiate()
	var due := _flashback_3_due()
	assert_int(FlashbackSchedule.due(due)).is_equal(3)
	var talk := contents.get_node("Flashbacks/Swing3") as Talkable
	assert_str(String(talk.current(due).id)).is_equal("flashback_3_swing")
	var raise := contents.get_node("Flashbacks/Raise3") as SwingRaiseBeat
	assert_int(raise.hold).is_equal(DialogueBeat.Hold.HELD_UP)
	assert_object(raise.swing).is_same(contents.get_node("Props/Swing"))
	for child: StringName in raise.rising + [raise.raised]:
		assert_object(raise.swing.get_node_or_null(NodePath(child))).override_failure_message(child).is_not_null()
	var crossing := contents.get_node("Flashbacks/Crossing3") as CutsceneBeat
	assert_object(crossing.cutscene).is_same(flashback.crossing)
	var lines := talk.current(due).lines
	assert_str(String(lines[0].cue)).is_equal(String(raise.cue))
	assert_str(String(lines[lines.size() - 1].cue)).is_equal(String(crossing.cue))
	var swing := raise.swing
	assert_str(String(swing.stages[FactStaging.pick(swing.stages, due)].show)).is_equal("Fallen")
	var seen := _flashback_3_due()
	seen.scenes_seen.append(FlashbackSchedule.id(3))
	assert_str(String(swing.stages[FactStaging.pick(swing.stages, seen)].show)).is_equal("Hanging")
	assert_object(talk.current(seen)).is_null()
	contents.free()

## The past at late afternoon: Alba on the swing in its place, the warm light, and four pushes, each heard only after
## the one before; the last lets go and leaves.
func test_the_past_swing_holds_her_and_four_pushes() -> void:
	var flashback := load("res://resources/story/flashbacks/flashback_3.tres") as Flashback
	var contents := (load(PAST_GARDEN_CONTENTS) as PackedScene).instantiate()
	var due := _flashback_3_due()
	var alba := contents.get_node("Stagings/Alba") as FactStaging
	assert_str(String(alba.stages[FactStaging.pick(alba.stages, due)].show)).is_equal("Swing")
	var prop := contents.get_node("Props/Swing") as FactStaging
	assert_str(String(prop.stages[FactStaging.pick(prop.stages, due)].show)).is_empty()
	var light := contents.get_node("Stagings/Light") as FactStaging
	assert_str(String(light.stages[FactStaging.pick(light.stages, due)].show)).is_equal("LateAfternoon")
	var before := _flashback_3_due()
	before.scenes_seen.erase(FlashbackSchedule.id(2))
	assert_str(String(prop.stages[FactStaging.pick(prop.stages, before)].show)).is_equal("Hanging")
	assert_int(FactStaging.pick(light.stages, before)).is_equal(-1)
	var talk := contents.get_node("Talkables/Swing3") as Talkable
	var cues := {}
	for beat: Node in contents.get_node("Beats").get_children():
		if beat is DialogueBeat:
			cues[(beat as DialogueBeat).cue] = beat
	for n: int in range(1, 5):
		var dialogue := talk.current(due)
		assert_str(String(dialogue.id)).is_equal("flashback_3_push_%d" % n)
		assert_str(String(dialogue.lines[0].cue)).is_equal("flashback_3_push")
		for line: DialogueLine in dialogue.lines:
			if line.cue != &"":
				assert_bool(cues.has(line.cue)).override_failure_message(String(line.cue)).is_true()
		due.dialogues_heard.append(dialogue.id)
	assert_object(talk.current(due)).is_null()
	assert_object((cues[&"flashback_3_leaving"] as CutsceneBeat).cutscene).is_same(flashback.leaving)
	assert_int((cues[&"flashback_3_let_go"] as SwingPushBeat).kind).is_equal(SwingPushBeat.Kind.LET_GO)
	assert_int((cues[&"flashback_3_push"] as SwingPushBeat).pose).is_equal(DialogueBeat.Pose.PUSH_SWING)
	assert_object((cues[&"flashback_3_push"] as SwingPushBeat).sway).is_same(alba.get_node("Swing"))
	contents.free()
