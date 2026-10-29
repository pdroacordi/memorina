class_name RoomFilesTest extends GdUnitTestSuite

## Validates every `.room` file against the current legend read from disk.

const ROOMS_DIR := "res://scenes/world/rooms"
const TRANSLATIONS := "res://i18n/translations.csv"
## Corrupted creatures' legend symbols (systems/creatures).
const CREATURES: Array[String] = ["B", "J", "C", "N", "A", "Z"]
## Rooms no corrupted creature is placed in: teachers' rooms, the guardians' arenas, the lighthouse, and the fields Ivo crosses
## before he owns the sword (architecture/corrupted-creatures, "Placements").
const NO_CREATURE_ROOMS: Array[String] = ["woods_edge", "lake_fishing_village", "orchard_windy_gap", "caldera_open_crater",
	"threshold_fields", "bloom_hollow", "lake_frost_arena", "orchard_arena", "caldera_arena", "lighthouse_base",
	"lighthouse_interior", "lighthouse_top"]
## Open cells under a hanging creature: a bat needs room to swoop, a spider only to let itself down over Ivo.
const HANG_CLEARANCE := {"A": 5, "Z": 3}
## Teaching creatures' symbols and the one room each stands in (systems/teaching-creatures; user, 2026-10-29).
const TEACHERS := {"U": "lake_fishing_village", "Y": "woods_edge", "K": "orchard_windy_gap", "Q": "caldera_open_crater"}
## Symbols a song acts on: an open echo admits only the teacher's phrase, so none lies in its reach.
const SONG_PUZZLES: Array[String] = ["P", "G", "L", "T", "H", "F", "D", "V", "O"]
## A teacher's reach in cells from its feet cell (CreatureLesson.reach: 4 cells either side, 3 rows up and down).
const TEACHER_REACH := Vector2i(4, 3)
## In the world (trials excluded): 1 boar, 3 crabs, 2 bats, 3 spiders, 3 hornets, 4 scorpions (the bait among them).
const WORLD_CREATURES := {"B": 1, "C": 3, "A": 2, "Z": 3, "N": 3, "J": 4}

func _room_files(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_room_files(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "room":
			found.append(dir.path_join(file))
	return found

func test_there_are_room_files_to_check() -> void:
	assert_int(_room_files(ROOMS_DIR).size()).is_greater(0)

func test_every_room_file_is_valid() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapValidator.validate(FileAccess.get_file_as_string(path), legend, path)
		problems.append_array(result.errors)
	assert_array(Array(problems)).is_empty()

## Save, bench and reward slot ids must be unique across maps so each names one location.
func test_save_ids_bench_ids_and_slot_ids_are_unique_across_every_map() -> void:
	var legend := RoomLegend.load_default()
	var seen := {}
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			for key: String in ["bench_id", "save_id", "slot_id"]:
				if not placed.params.has(key):
					continue
				var id := "%s=%s" % [key, placed.params[key]]
				if seen.has(id):
					problems.append("%s in %s and %s" % [id, seen[id], path])
				seen[id] = path
	assert_array(Array(problems)).is_empty()

## A bat hangs under ground and a spider under ground or a one-way, over open cells (HANG_CLEARANCE); no creature lies
## in the village or a room of NO_CREATURE_ROOMS; the world holds the 16 placed by the plan.
func test_creatures_hang_clear_and_keep_out_of_the_rooms_they_must_not_enter() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	var counts := {}
	for path: String in _room_files(ROOMS_DIR):
		var room := path.get_file().get_basename()
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		for placed: Dictionary in map.entities:
			var symbol: String = placed.symbol
			if symbol not in CREATURES:
				continue
			if not path.contains("/trials_"):
				counts[symbol] = int(counts.get(symbol, 0)) + 1
			if path.contains("/home_village/") or room in NO_CREATURE_ROOMS:
				problems.append("%s: creature %s at %s in a room it must not enter" % [path, symbol, placed.cell - map.origin])
			if not HANG_CLEARANCE.has(symbol):
				continue
			var cell: Vector2i = placed.cell
			var above := cell + Vector2i.UP
			if not (map.is_solid(above) or (symbol == "Z" and map.is_platform(above))):
				problems.append("%s: %s at %s hangs from nothing" % [path, symbol, cell - map.origin])
			for down: int in range(1, int(HANG_CLEARANCE[symbol]) + 1):
				var below := cell + Vector2i(0, down)
				if map.is_solid(below) or map.is_platform(below):
					problems.append("%s: %s at %s has ground %d cell(s) below" % [path, symbol, cell - map.origin, down])
					break
	assert_array(Array(problems)).is_empty()
	assert_dict(counts).is_equal(WORLD_CREATURES)

## A slot's kind is a member of RewardSlot.Kind (architecture/reward-slots-reserve-their-place-in-the-room-text).
## Each teacher stands once in the world, in its room, on a floor, with no song puzzle in its reach.
func test_each_teacher_stands_once_on_a_floor_with_no_puzzle_in_reach() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	var found := {}
	for path: String in _room_files(ROOMS_DIR):
		var room := path.get_file().get_basename()
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		for placed: Dictionary in map.entities:
			var symbol: String = placed.symbol
			if not TEACHERS.has(symbol):
				continue
			found[symbol] = int(found.get(symbol, 0)) + 1
			var cell: Vector2i = placed.cell
			if room != TEACHERS[symbol]:
				problems.append("%s: teacher %s belongs in %s" % [path, symbol, TEACHERS[symbol]])
			if map.is_solid(cell) or not (map.is_solid(cell + Vector2i.DOWN) or map.is_platform(cell + Vector2i.DOWN)):
				problems.append("%s: teacher %s at %s stands on nothing" % [path, symbol, cell - map.origin])
			for at: Vector2i in _puzzle_cells(map):
				var offset := at - cell
				if absi(offset.x) <= TEACHER_REACH.x and absi(offset.y) <= TEACHER_REACH.y:
					problems.append("%s: teacher %s at %s has a song puzzle in reach at %s" % [path, symbol, cell - map.origin, at - map.origin])
	for symbol: String in TEACHERS:
		if int(found.get(symbol, 0)) != 1:
			problems.append("teacher %s placed %d times" % [symbol, int(found.get(symbol, 0))])
	assert_array(Array(problems)).is_empty()

## Cells a song acts on: puzzle pieces, freezable water and the reaches Chuva or a Redoma shell raise water to.
func _puzzle_cells(map: RoomMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for placed: Dictionary in map.entities:
		if placed.symbol in SONG_PUZZLES:
			cells.append(placed.cell)
	var grids: Array[PackedVector2Array] = [map.water.get("f", PackedVector2Array())]
	grids.append_array(map.reach.values())
	grids.append_array(map.shell_reach.values())
	for grid: PackedVector2Array in grids:
		for at: Vector2 in grid:
			cells.append(Vector2i(at))
	return cells

func test_every_reward_slot_has_a_known_kind() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if placed.symbol != "$":
				continue
			var kind: Variant = (placed.params as Dictionary).get("kind", RewardSlot.Kind.COLLECTIBLE)
			if typeof(kind) not in [TYPE_INT, TYPE_FLOAT] or not int(kind) in RewardSlot.Kind.values() or float(kind) != int(kind):
				problems.append("%s: slot %s has kind %s" % [path, placed.params.get("slot_id", "?"), kind])
	assert_array(Array(problems)).is_empty()

## Every COLLECTIBLE slot holds a found piece but the LIFE-05 life note's, and every piece names a COLLECTIBLE slot
## (architecture/found-pieces).
func test_found_pieces_and_collectible_slots_match() -> void:
	const RESERVED: Array[StringName] = [&"caldera_temple_sanctum"]
	var catalog := load(FoundCatalog.DEFAULT_PATH) as FoundCatalog
	var legend := RoomLegend.load_default()
	var slots: Dictionary[StringName, bool] = {}
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if placed.symbol != "$" or int(placed.params.get("kind", RewardSlot.Kind.COLLECTIBLE)) != RewardSlot.Kind.COLLECTIBLE:
				continue
			var slot_id := StringName(placed.params.get("slot_id", ""))
			slots[slot_id] = true
			if catalog.get_piece(slot_id) == null and slot_id not in RESERVED:
				problems.append("%s: slot %s holds no found piece" % [path, slot_id])
	for piece: FoundPiece in catalog.pieces:
		if not slots.has(piece.slot_id):
			problems.append("found piece %s names no COLLECTIBLE slot" % piece.slot_id)
	assert_array(Array(problems)).is_empty()

## Every found piece names the room whose `.room` holds its slot, so a rumour finds its region (systems/seeds-and-the-seller).
func test_every_found_piece_names_its_room() -> void:
	var catalog := load(FoundCatalog.DEFAULT_PATH) as FoundCatalog
	var legend := RoomLegend.load_default()
	var rooms: Dictionary[StringName, StringName] = {}
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if placed.symbol == "$":
				rooms[StringName(placed.params.get("slot_id", ""))] = StringName(path.get_file().get_basename())
	var problems := PackedStringArray()
	for piece: FoundPiece in catalog.pieces:
		if rooms.get(piece.slot_id, &"") != piece.room:
			problems.append("%s names room %s, its slot is in %s" % [piece.slot_id, piece.room, rooms.get(piece.slot_id, &"?")])
	assert_array(Array(problems)).is_empty()

## A slot stands on ground or a one-way, so it never floats; room_kit_test's ANCHOR_DROP lookup would not notice one that did.
func test_every_reward_slot_stands_on_a_floor() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		for placed: Dictionary in map.entities:
			if placed.symbol != "$":
				continue
			var below: Vector2i = placed.cell + Vector2i.DOWN
			if not (map.is_solid(below) or map.is_platform(below)):
				problems.append("%s: slot %s at %s stands on nothing" % [path, placed.params.get("slot_id", "?"), placed.cell - map.origin])
	assert_array(Array(problems)).is_empty()

## A soft-landing zone's top stands 2 cells or more over the first floor in every column of its span, so a fall enters
## it frames before it lands, while the count is still being raised in the physics flush (systems/rooms "Soft landing").
func test_every_soft_landing_rises_two_cells_over_its_floors() -> void:
	var legend := RoomLegend.load_default()
	var defaults := SoftLanding.new()
	var problems := PackedStringArray()
	var zones := 0
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		for placed: Dictionary in map.entities:
			if placed.symbol != "n":
				continue
			zones += 1
			var width := int((placed.params as Dictionary).get("width_cells", defaults.width_cells))
			var height := int((placed.params as Dictionary).get("height_cells", defaults.height_cells))
			var cell: Vector2i = placed.cell
			var top := cell.y + 1 - height
			var left := cell.x + 0.5 - width * 0.5
			var right := cell.x + 0.5 + width * 0.5
			for x: int in range(floori(left), ceili(right)):
				if x + 0.5 <= left or x + 0.5 >= right:
					continue
				for y: int in range(top, cell.y + 2):
					var under := Vector2i(x, y)
					if map.is_solid(under) or map.is_platform(under):
						if y - top < 2:
							problems.append("%s: zone at %s is %d cell(s) over the floor in column %d" % [path, cell - map.origin, y - top, x - map.origin.x])
						break
	defaults.free()
	assert_int(zones).is_greater(0)
	assert_array(Array(problems)).is_empty()

## "Not impossible to find" (user, 2026-10-10): every secret shows a crack cell or has a draft within a cell of it;
## and a secret's id is unique across every map, because the save remembers it (architecture/secret-false-walls).
func test_every_secret_has_a_hint_and_a_unique_id() -> void:
	var legend := RoomLegend.load_default()
	var seen := {}
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		for group: int in range(1, map.secret_ids.size() + 1):
			var id := map.secret_ids[group - 1]
			if seen.has(id):
				problems.append("secret %s in %s and %s" % [id, seen[id], path])
			seen[id] = path
			if not _hinted(map, group):
				problems.append("secret %s in %s has no crack and no draft beside it" % [id, path])
	assert_array(Array(problems)).is_empty()

func _hinted(map: RoomMap, group: int) -> bool:
	var drafts: Array[Vector2i] = []
	for placed: Dictionary in map.entities:
		if placed.symbol == "d":
			drafts.append(placed.cell)
	for index: int in map.secret_groups.size():
		if map.secret_groups[index] != group:
			continue
		if map.secret_cracks[index] == 1:
			return true
		var cell := map.origin + Vector2i(index % map.size.x, index / map.size.x)
		for draft: Vector2i in drafts:
			if absi(draft.x - cell.x) <= 1 and absi(draft.y - cell.y) <= 1:
				return true
	return false

## Every helix stair's ends stand on floor tops, its head has a landing and its swept body is air (systems/helix-stair).
func test_every_helix_stair_rides_clear() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		for placed: Dictionary in map.entities:
			if placed.symbol != "@":
				continue
			for problem: String in HelixStair.check(placed.cell, placed.params, map):
				problems.append("%s: helix stair at %s: %s" % [path, placed.cell, problem])
	assert_array(Array(problems)).is_empty()

## Void lies only in interiors: a surface room would reveal void cells on the map (architecture/room-void-outside-the-shell).
func test_void_lies_only_in_interiors() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		if map.void_cells.is_empty():
			continue
		var trigger := path.get_base_dir().get_base_dir().path_join(path.get_file().get_basename() + ".tscn")
		var interior := false
		if ResourceLoader.exists(trigger):
			var room := (load(trigger) as PackedScene).instantiate()
			interior = room.get("interior")
			room.free()
		if not interior:
			problems.append("%s has void but is no interior" % path)
	assert_array(Array(problems)).is_empty()

## A door's art, sunk steps included, never lies on void.
func test_every_doors_art_is_clear_of_void() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path).map
		if map.void_cells.is_empty():
			continue
		for placed: Dictionary in map.entities:
			if placed.symbol != "E":
				continue
			var look := str((placed.params as Dictionary).get("look", "door"))
			var texture: Texture2D = Door.LOOKS[look]
			var size := Vector2(texture.get_width() * 0.5, texture.get_height())
			var cell: Vector2i = placed.cell
			var feet := Vector2((cell.x + 0.5) * RoomMap.CELL_PX, (cell.y + 1) * RoomMap.CELL_PX + Door.SINKS.get(look, 0.0))
			var art := Rect2(feet - Vector2(size.x * 0.5, size.y), size)
			for y: int in range(floori(art.position.y / RoomMap.CELL_PX), ceili(art.end.y / RoomMap.CELL_PX)):
				for x: int in range(floori(art.position.x / RoomMap.CELL_PX), ceili(art.end.x / RoomMap.CELL_PX)):
					if map.is_void(Vector2i(x, y)):
						problems.append("%s: the door at %s draws over void at %d,%d" % [path, cell, x, y])
	assert_array(Array(problems)).is_empty()

## A door pair joins two rooms of one region, each naming the other's room, and every `to_room` is a Room scene of that region.
func test_every_door_has_its_partner() -> void:
	var legend := RoomLegend.load_default()
	var records: Array[DoorLinks.Record] = []
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		# <rooms>/<region>/contents/<room>.room
		var region_dir := path.get_base_dir().get_base_dir()
		for placed: Dictionary in result.map.entities:
			if not placed.params.has("link"):
				continue
			var to_room := str(placed.params.get("to_room", ""))
			records.append(DoorLinks.Record.new(StringName(path.get_file().get_basename()), StringName(region_dir.get_file()),
					StringName(placed.params["link"]), StringName(to_room), path))
			if not ResourceLoader.exists(region_dir.path_join(to_room + ".tscn")):
				problems.append("%s: to_room %s is not a room of %s" % [path, to_room, region_dir])
	problems.append_array(DoorLinks.problems(records))
	assert_array(Array(problems)).is_empty()

## The title names a slot's bench by `SaveSlots.bench_name_key`, so every bench needs that key in both languages.
func test_every_bench_has_a_name_in_the_translations() -> void:
	var legend := RoomLegend.load_default()
	var keys := _translation_keys()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if not placed.params.has("bench_id"):
				continue
			var key := SaveSlots.bench_name_key(StringName(placed.params["bench_id"]))
			if not keys.has(key):
				problems.append("%s (%s) has no translated name" % [key, path])
	assert_array(Array(problems)).is_empty()

## A Talkable's set is in the dialogue catalog, so the catalog's validation covers every talk a room can start (systems/dialogue).
func test_every_talkable_set_is_in_the_dialogue_catalog() -> void:
	var legend := RoomLegend.load_default()
	var catalog := load("res://resources/dialogue/dialogue_catalog.tres") as DialogueCatalog
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if placed.symbol != "t":
				continue
			var talk: String = placed.params.get("talk", "")
			var dialogue_set := load(talk) as DialogueSet if ResourceLoader.exists(talk) else null
			if not catalog.has_set(dialogue_set):
				problems.append("%s: talk %s is not in the dialogue catalog" % [path, talk])
	assert_array(Array(problems)).is_empty()

## An item pickup names a real `Enums.PlayerItem` and a texture that exists (systems/pickups).
func test_every_item_pickup_names_a_known_item_and_its_art() -> void:
	var legend := RoomLegend.load_default()
	var problems := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if placed.symbol != "i":
				continue
			var item: Variant = (placed.params as Dictionary).get("item", -1)
			if typeof(item) not in [TYPE_INT, TYPE_FLOAT] or float(item) != int(item) or not int(item) in Enums.PlayerItem.values():
				problems.append("%s: pickup at %s has item %s" % [path, placed.cell, item])
			var texture := str((placed.params as Dictionary).get("texture", ""))
			if not ResourceLoader.exists(texture):
				problems.append("%s: pickup at %s has no texture %s" % [path, placed.cell, texture])
	assert_array(Array(problems)).is_empty()

## STORY-02: the sword lies once in the world, on the farmhouse table.
func test_the_sword_lies_on_the_farmhouse_table() -> void:
	var legend := RoomLegend.load_default()
	var found := PackedStringArray()
	for path: String in _room_files(ROOMS_DIR):
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		for placed: Dictionary in result.map.entities:
			if placed.symbol == "i" and int((placed.params as Dictionary).get("item", -1)) == Enums.PlayerItem.SWORD:
				found.append(path.get_file())
	assert_array(Array(found)).is_equal(["threshold_farmhouse.room"])

func test_a_placement_missing_a_required_param_is_refused() -> void:
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n..R..\n#####\n"
	var result := RoomMapValidator.validate(text, RoomLegend.load_default(), "inline.room")
	assert_bool(result.ok()).is_false()
	assert_str("\n".join(result.errors)).contains("needs a 'bench_id' param")

func test_an_empty_required_param_is_refused() -> void:
	var text := "[room]\norigin = 0, 0\ntileset = legacy\n\n[grid]\n..R..\n#####\n\n[entities]\n2,0 = {\"bench_id\": \"\"}\n"
	var result := RoomMapValidator.validate(text, RoomLegend.load_default(), "inline.room")
	assert_str("\n".join(result.errors)).contains("needs a 'bench_id' param")

func test_the_legend_is_sound() -> void:
	assert_array(Array(RoomLegend.load_default().problems())).is_empty()

## Keys whose every language column is filled, read from the source CSV.
func _translation_keys() -> Dictionary[String, bool]:
	var keys: Dictionary[String, bool] = {}
	var file := FileAccess.open(TRANSLATIONS, FileAccess.READ)
	var header := file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == header.size() and not row.has(""):
			keys[row[0]] = true
	return keys
