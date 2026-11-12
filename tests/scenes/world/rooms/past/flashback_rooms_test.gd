class_name FlashbackRoomsTest extends GdUnitTestSuite

## Nothing in the past can hurt Ivo or keep anything (architecture/story-05-playable-flashbacks): no creature, hazard,
## bench, door, pickup or reward slot, and no water in it or in the present garden can take Ivo in.

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

## Every body of water pours no hazard and none can take Ivo in: shallow water (WADE) lies one row deep over ground, and
## a lake lies under the bank, every one of its columns topped by solid ground (architecture/story-05-playable-flashbacks,
## "The garden rebuilt").
func _assert_no_drowning(room_name: String, map: RoomMap) -> void:
	for kind: Dictionary in [map.reach, map.shell_reach]:
		assert_dict(kind).override_failure_message("%s: water that rises" % room_name).is_empty()
	for symbol: String in map.water:
		var entry := map.legend.entry(symbol)
		var layer := entry.water_layer.instantiate() as WaterLayer
		var body := layer.body_scene.instantiate()
		assert_str(_hazard_in(body)).override_failure_message("%s: '%s' pours a hazard" % [room_name, symbol]).is_empty()
		body.free()
		layer.free()
		var cells := {}
		for point: Vector2 in map.water[symbol]:
			cells[Vector2i(point)] = true
		for cell: Vector2i in cells:
			if entry.reach_role == RoomLegendEntry.ReachRole.WADE:
				assert_bool(map.is_solid(cell + Vector2i.DOWN)).override_failure_message("%s: water at %s is deeper than a row" % [
						room_name, cell]).is_true()
			elif not cells.has(cell + Vector2i.UP):
				assert_bool(map.is_solid(cell + Vector2i.UP)).override_failure_message("%s: '%s' at %s lies open to Ivo" % [
						room_name, symbol, cell]).is_true()

func _hazard_in(root: Node) -> String:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is HazardZone:
			return str(node.name)
		stack.append_array(node.get_children())
	return ""

func test_nobody_drowns_in_the_past() -> void:
	for room: Room in _past_rooms():
		_assert_no_drowning(str(room.name), _map_of(room))
		room.free()

func test_ivo_never_drowns_in_the_present_garden() -> void:
	var garden := (load(PRESENT_GARDEN) as PackedScene).instantiate() as Room
	var map := _map_of(garden)
	assert_dict(map.water).is_not_empty()
	_assert_no_drowning("village_garden", map)
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
		var staging := contents.get_node("Flashbacks/Ribbon") as FactStaging
		var talk := contents.get_node("Flashbacks/RibbonTalk") as Talkable
		var beat := contents.get_node("Flashbacks/Crossing2") as CutsceneBeat
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
		var staging := contents.get_node("Flashbacks/Ribbon") as FactStaging
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
		states.append(_flashback_4_due_with(guardian))
		var seen_4 := _flashback_4_due_with(guardian)
		seen_4.scenes_seen.append(FlashbackSchedule.id(4))
		states.append(seen_4)
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

## Flashback 4 is due with three guardians restored, `guardian` among them.
func _flashback_4_due_with(guardian: int) -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	var count := 1
	data.restored_guardians[guardian] = true
	for other: int in Enums.Guardian.values():
		if count < 3 and other != guardian:
			data.restored_guardians[other] = true
			count += 1
	for n: int in range(1, 4):
		data.scenes_seen.append(FlashbackSchedule.id(n))
	return data

## The ribbon again (design drafts/camada_pessoal.md §2, "4."): while flashback 4 is due it hangs still in each restored
## guardian's exit room, its own talk offers the shared crossing, and flashback 2's talk stays shut.
func test_the_ribbon_hangs_still_for_flashback_4() -> void:
	var flashback := load("res://resources/story/flashbacks/flashback_4.tres") as Flashback
	for guardian: int in RIBBON_ROOMS:
		var file := String(RIBBON_ROOMS[guardian]).get_file()
		var contents := (load(RIBBON_ROOMS[guardian]) as PackedScene).instantiate()
		var staging := contents.get_node("Flashbacks/Ribbon") as FactStaging
		var talk := contents.get_node("Flashbacks/RibbonTalk4") as Talkable
		var talk_2 := contents.get_node("Flashbacks/RibbonTalk") as Talkable
		var beat := contents.get_node("Flashbacks/Crossing4") as CutsceneBeat
		assert_object(beat.cutscene).is_same(flashback.crossing)
		var due := _flashback_4_due_with(guardian)
		assert_int(FlashbackSchedule.due(due)).is_equal(4)
		assert_str(String(staging.stages[FactStaging.pick(staging.stages, due)].show)).override_failure_message(file) 				.is_equal("Still")
		assert_float((staging.get_node("Still") as AnimatedSprite2D).speed_scale).is_equal(0.0)
		assert_str(String(talk.current(due).lines[0].cue)).is_equal(String(beat.cue))
		assert_object(talk_2.current(due)).is_null()
		var other := _flashback_4_due_with(guardian)
		other.restored_guardians[guardian] = false
		for g: int in Enums.Guardian.values():
			if g != guardian and not other.restored_guardians[g]:
				other.restored_guardians[g] = true
				break
		assert_int(FactStaging.pick(staging.stages, other)).override_failure_message(file).is_equal(-1)
		assert_object(talk.current(other)).is_null()
		var seen := _flashback_4_due_with(guardian)
		seen.scenes_seen.append(FlashbackSchedule.id(4))
		assert_int(FactStaging.pick(staging.stages, seen)).is_equal(-1)
		assert_object(talk.current(seen)).is_null()
		contents.free()

## The past at night: moonlight, Alba at the pool's edge with her back turned until her turn is seen, the water until
## the first talk is heard, then the close talk, cut, whose beat is the leaving.
func test_the_night_by_the_pool_for_flashback_4() -> void:
	var flashback := load("res://resources/story/flashbacks/flashback_4.tres") as Flashback
	var contents := (load(PAST_GARDEN_CONTENTS) as PackedScene).instantiate()
	var due := _flashback_4_due_with(Enums.Guardian.FROST)
	var alba := contents.get_node("Stagings/Alba") as FactStaging
	assert_str(String(alba.stages[FactStaging.pick(alba.stages, due)].show)).is_equal("PoolBack")
	var light := contents.get_node("Stagings/Light") as FactStaging
	assert_str(String(light.stages[FactStaging.pick(light.stages, due)].show)).is_equal("Night")
	var water := contents.get_node("Water4") as FlashbackLure
	assert_bool(SaveFact.gates_pass(water.when, water.unless, due)).is_true()
	assert_object(water.zone).is_null()
	var cues := {}
	for beat: Node in contents.get_node("Beats").get_children():
		if beat is DialogueBeat:
			cues[(beat as DialogueBeat).cue] = beat
	var first := (contents.get_node("Talkables/Alba4") as Talkable).current(due)
	assert_str(String(first.id)).is_equal("flashback_4_alba")
	assert_float(first.zoom).is_equal(0.0)
	for line: DialogueLine in first.lines:
		if line.cue != &"":
			assert_bool(cues.has(line.cue)).override_failure_message(String(line.cue)).is_true()
	var close := contents.get_node("Talkables/ForYou4") as Talkable
	assert_object(close.current(due)).is_null()
	due.dialogues_heard.append(first.id)
	due.scenes_seen.append(&"flashback_4_turn")
	assert_str(String(alba.stages[FactStaging.pick(alba.stages, due)].show)).is_equal("Turned")
	assert_bool(SaveFact.gates_pass(water.when, water.unless, due)).is_false()
	var last := close.current(due)
	assert_str(String(last.id)).is_equal("flashback_4_for_you")
	assert_bool(last.cut).is_true()
	assert_bool(close.auto_start).is_true()
	# The pair frames the midpoint of Ivo (at behind_her) and the speaker point: that midpoint is her.
	var behind := contents.get_node("SceneMarks/BehindHer") as Node2D
	var her := alba.get_node("Turned") as Node2D
	assert_float((behind.position.x + close.speaker_position().x) / 2.0).is_equal_approx(her.position.x, 0.5)
	assert_object((cues[last.lines[0].cue] as CutsceneBeat).cutscene).is_same(flashback.leaving)
	contents.free()

## Her edge frays once in all the flashbacks: only flashback 4's leaving holds a CutsceneFray, and only one.
func test_only_flashback_4_frays_her_once() -> void:
	var catalog := load("res://resources/cutscene/cutscene_catalog.tres") as CutsceneCatalog
	var frays: Array[StringName] = []
	for scene: Cutscene in catalog.scenes:
		for leaf: CutsceneStep in CutsceneCatalog.leaves(scene.steps):
			if leaf is CutsceneFray and (leaf as CutsceneFray).actor == &"alba":
				frays.append(scene.id)
	assert_array(frays).is_equal([FlashbackSchedule.id(4)])

## Flashback 5 is due: all four guardians restored and flashbacks 1-4 seen.
func _flashback_5_due() -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = true
	for g: int in Enums.Guardian.values():
		data.restored_guardians[g] = true
	for n: int in range(1, 5):
		data.scenes_seen.append(FlashbackSchedule.id(n))
	return data

const LULLABY_LURES := [
	"res://scenes/world/rooms/home_village/contents/village_mill_contents.tscn",
	"res://scenes/world/rooms/frozen_lake/contents/lake_waterfall_path_contents.tscn",
]

## Her lullaby calls from outside the garden (design drafts/camada_pessoal.md §2, "5."): in the mill and up the waterfall
## path the water carries her voice, asked of Music, louder nearer the garden, until the crossing is seen.
func test_her_lullaby_calls_up_the_river_for_flashback_5() -> void:
	var due := _flashback_5_due()
	assert_int(FlashbackSchedule.due(due)).is_equal(5)
	var visit := load("res://resources/story/flashbacks/flashback_5.tres") as Flashback
	for path: String in LULLABY_LURES:
		var contents := (load(path) as PackedScene).instantiate()
		var lure := contents.get_node("Lure5") as FlashbackLure
		assert_bool(SaveFact.gates_pass(lure.when, lure.unless, due)).override_failure_message(path).is_true()
		assert_object(lure.voice).is_not_null()
		assert_object(lure.zone).is_not_null()
		assert_float(lure.duck_db_at(lure.position)).is_equal(lure.near_db)
		assert_float(lure.duck_db_at(lure.position + Vector2(lure.voice_reach, 0))).is_equal(lure.duck_db)
		var seen := _flashback_5_due()
		seen.scenes_seen.append(visit.crossing.id)
		assert_bool(SaveFact.gates_pass(lure.when, lure.unless, seen)).is_false()
		contents.free()

## In the garden the crossing is entering it while due; the colour follows the visit's song to full at its entry mark, and
## the swap covers the east half, from where the tree's figures in the past are off-frame.
func test_the_garden_crosses_with_the_song_for_flashback_5() -> void:
	var visit := load("res://resources/story/flashbacks/flashback_5.tres") as Flashback
	var contents := (load(PRESENT_GARDEN_CONTENTS) as PackedScene).instantiate()
	var due := _flashback_5_due()
	var crossing := contents.get_node("Flashbacks/Crossing5") as CutsceneTrigger
	assert_object(crossing.cutscene).is_same(visit.crossing)
	assert_bool(crossing.wants(due)).is_true()
	assert_bool(crossing.wants(_flashback_4_due_with(Enums.Guardian.FROST))).is_false()
	var bloom := contents.get_node("Flashbacks/SongBloom5") as SongBloom
	assert_object(bloom.song).is_same(visit.music)
	assert_float(bloom.to).is_less_equal(visit.entry_mark)
	var swap := contents.get_node("Flashbacks/Swap5") as FlashbackSwap
	assert_int(swap.number).is_equal(5)
	var shape := swap.get_node("CollisionShape2D") as CollisionShape2D
	var west := shape.position.x - (shape.shape as RectangleShape2D).size.x / 2.0
	var past := (load(PAST_GARDEN_CONTENTS) as PackedScene).instantiate()
	var her := past.get_node("Stagings/Alba/TreeWithDaughter") as Node2D
	# From the swap's west edge, walking west with the look-ahead, the view's left edge stays east of her 96 px frame.
	assert_float(west - 320.0 - 96.0).is_greater(her.position.x + 48.0)
	contents.free()
	past.free()

## The past at twilight: Alba under the old tree with the girl asleep, a dusk that deepens with the song, and the ground
## seat beside them whose sitting plays the leaving, which waits for the song before the lost ending.
func test_the_lullaby_under_the_old_tree_for_flashback_5() -> void:
	var visit := load("res://resources/story/flashbacks/flashback_5.tres") as Flashback
	var contents := (load(PAST_GARDEN_CONTENTS) as PackedScene).instantiate()
	var due := _flashback_5_due()
	var alba := contents.get_node("Stagings/Alba") as FactStaging
	assert_str(String(alba.stages[FactStaging.pick(alba.stages, due)].show)).is_equal("TreeWithDaughter")
	var light := contents.get_node("Stagings/Light") as FactStaging
	assert_str(String(light.stages[FactStaging.pick(light.stages, due)].show)).is_equal("Twilight")
	for tint: Node in [contents.get_node("Lullaby5/Dusk"), contents.get_node("Lullaby5/Afterglow")]:
		assert_object((tint as SongTint).song).is_same(visit.music)
		assert_float((tint as SongTint).from).is_equal(visit.entry_mark)
	var seat := contents.get_node("Lullaby5/Seat") as GroundSeat
	assert_object(seat.cutscene).is_same(visit.leaving)
	assert_bool(seat.wants(due)).is_true()
	assert_bool(seat.wants(_flashback_4_due_with(Enums.Guardian.FROST))).is_false()
	# One line, held so the player does nothing, and the cut lands inside the loop, before her A.
	var marks: Array[float] = []
	var talks := 0
	for leaf: CutsceneStep in CutsceneCatalog.leaves(visit.leaving.steps):
		if leaf is CutsceneMusicMark:
			marks.append((leaf as CutsceneMusicMark).seconds)
		elif leaf is CutsceneTalk:
			talks += 1
			var said := (leaf as CutsceneTalk).talk.current(due)
			assert_int(said.lines.size()).is_equal(1)
			assert_float(said.lines[0].hold).is_greater(0.0)
	assert_int(talks).is_equal(1)
	var ogg := visit.music.stream as AudioStreamOggVorbis
	assert_float(marks.max()).is_less(ogg.beat_count * 60.0 / ogg.bpm)
	assert_float(visit.bars_thin).is_equal(0.0)
	contents.free()

## Flashback `n` due (0: none): the Memorina owned, n - 1 guardians restored and the flashbacks before it seen.
func _due(n: int) -> PlayerData:
	var data := PlayerData.new()
	data.owned_items[Enums.PlayerItem.MEMORINA] = n > 0
	var guardians: Array = Enums.Guardian.values()
	for g: int in guardians.slice(0, maxi(n - 1, 0)):
		data.restored_guardians[g] = true
	for k: int in range(1, n):
		data.scenes_seen.append(FlashbackSchedule.id(k))
	return data

const TIMES := ["morning", "day", "afternoon", "night", "twilight"]

func _sky(contents: Node, data: PlayerData) -> String:
	var sky := contents.get_node("Sky") as FactBackdrop
	var rest := (contents.get_node("Backdrop") as Backdrop).backdrop_set
	return FactBackdrop.set_for(sky.sets, data, rest).resource_path.get_file().get_basename()

## Each flashback's past has its own time of day (user, 2026-11-12: 1 morning, 2 day, 3 late afternoon, 4 moonlit night,
## 5 darkening twilight); the present shows day, and the past's twilight while flashback 5 is due, so the hidden swap
## meets the same sky.
func test_the_sky_follows_the_flashback() -> void:
	var past := (load(PAST_GARDEN_CONTENTS) as PackedScene).instantiate()
	var present := (load(PRESENT_GARDEN_CONTENTS) as PackedScene).instantiate()
	for n: int in range(1, FlashbackSchedule.COUNT + 1):
		var data := _due(n)
		assert_int(FlashbackSchedule.due(data)).is_equal(n)
		assert_str(_sky(past, data)).is_equal("waterfall_garden_%s" % TIMES[n - 1])
		assert_str(_sky(present, data)).is_equal("waterfall_garden_%s" % ("twilight" if n == 5 else "day"))
	assert_str(_sky(present, _due(0))).is_equal("waterfall_garden_day")
	past.free()
	present.free()

func _lantern(contents: Node, data: PlayerData) -> String:
	var lantern := contents.get_node("Props/Lantern") as FactStaging
	return String(lantern.stages[FactStaging.pick(lantern.stages, data)].show)

## The lantern is lit from late afternoon in the past, faint while the day is still bright; in the present only while her
## lullaby brings the colour back (flashback 5), and its light follows the memory there.
func test_the_lantern_is_lit_from_late_afternoon() -> void:
	var past := (load(PAST_GARDEN_CONTENTS) as PackedScene).instantiate()
	var present := (load(PRESENT_GARDEN_CONTENTS) as PackedScene).instantiate()
	var expected := ["Unlit", "Unlit", "LitDusk", "Lit", "Lit"]
	for n: int in range(1, FlashbackSchedule.COUNT + 1):
		assert_str(_lantern(past, _due(n))).override_failure_message("past, flashback %d" % n).is_equal(expected[n - 1])
		assert_str(_lantern(present, _due(n))).override_failure_message("present, flashback %d" % n) \
				.is_equal("Lit" if n == 5 else "Unlit")
	for contents: Node in [past, present]:
		var lit := contents.get_node("Props/Lantern/Lit") as Sprite2D
		var light := lit.get_node("Light") as LanternLight
		assert_object(light.flame).is_same(lit)
		assert_float(light.strength).is_equal(1.0)
	assert_float((past.get_node("Props/Lantern/LitDusk/Light") as LanternLight).strength).is_less(0.5)
	past.free()
	present.free()
