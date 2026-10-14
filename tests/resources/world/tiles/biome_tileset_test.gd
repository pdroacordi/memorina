class_name BiomeTilesetTest extends GdUnitTestSuite

## Every biome resource is named by its file, sound, and builds a defined tile per slot of each present look.

## Art px every fill variant must differ from the plain fill and from each other by (the village soil's pebble is 3).
const MIN_DISTINCT_ART_PX := 3
## Each region's biome; the trials borrow theirs (board_world, 2026-10-13).
const REGION_TILESETS := {
	"home_village": "village", "threshold": "threshold", "frost_edge": "frost_edge", "spring_woods": "spring_woods",
	"frozen_lake": "frozen_lake", "wind_orchards": "wind_orchards", "summer_caldera": "summer_caldera",
	"trials_winter": "frozen_lake", "trials_spring": "spring_woods", "trials_autumn": "wind_orchards",
	"trials_solstice": "threshold",
	# The summer trial's floor is earth, which the caldera biomes lack.
	"trials_summer": "threshold",
}
## Rooms that draw another biome than their region's (systems/rooms).
const ROOM_TILESETS := {
	"lighthouse_base": "lighthouse", "lighthouse_top": "lighthouse", "lighthouse_interior": "lighthouse",
	"caldera_cistern": "village", "caldera_dry_moat": "summer_caldera_ash", "caldera_open_crater": "summer_caldera_ash",
	"the_catch": "frozen_lake", "door_trial": "frozen_lake", "door_trial_inside": "frozen_lake",
}
## The trial rooms of ROOM_TILESETS: debug only, so the world generator does not know them.
const TRIAL_ROOMS := ["the_catch", "door_trial", "door_trial_inside"]


func _biomes() -> Array[BiomeTileset]:
	var found: Array[BiomeTileset] = []
	for file: String in DirAccess.get_files_at(BiomeTileset.DIRECTORY):
		if file.ends_with(".tres"):
			found.append(load(BiomeTileset.DIRECTORY + file) as BiomeTileset)
	return found

## The parser fixtures still name the pack sheets; no game room does.
func test_there_is_at_least_the_legacy_biome() -> void:
	assert_object(BiomeTileset.find("legacy")).is_not_null()

## "We should only our set of tiles from now on and not mix em." (user, 2026-10-13): no room, trial, scene or room
## generator default draws the pack's tiles.
func test_no_room_scene_or_generator_draws_the_pack_tiles() -> void:
	var offenders := PackedStringArray()
	for path: String in _files_under("res://scenes", ["room", "tscn", "tres"]) + _files_under("res://resources", ["tres"]):
		var text := FileAccess.get_file_as_string(path)
		if path.ends_with(".room") and text.contains("tileset = legacy"):
			offenders.append(path)
		elif text.contains("tiles/biomes/legacy.tres") or text.contains("tilesets/legacy/"):
			if path != BiomeTileset.DIRECTORY + "legacy.tres":
				offenders.append(path)
	if FileAccess.get_file_as_string("res://tools/maps/gen_world_shells.py").contains("tileset = legacy"):
		offenders.append("res://tools/maps/gen_world_shells.py")
	assert_array(Array(offenders)).is_empty()

## Every room names its region's biome, read the way the parser reads it, so a spelling like `tileset=legacy` cannot slip
## past (systems/rooms, Tilesets per region). The tables mirror gen_world_shells.py's REGION_TILESETS and ROOM_TILESETS.
func test_every_room_draws_its_regions_tileset() -> void:
	var legend := RoomLegend.load_default()
	var wrong := PackedStringArray()
	for path: String in _files_under("res://scenes", ["room"]):
		var region := path.get_base_dir().get_base_dir().get_file()
		var room := path.get_file().get_basename()
		var want: String = ROOM_TILESETS.get(room, REGION_TILESETS.get(region, ""))
		var parsed := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		var drawn := parsed.map.biome.id() if parsed.map != null and parsed.map.biome != null else "<none>"
		if drawn != want:
			wrong.append("%s: %s, want %s" % [path, drawn, want])
	assert_array(Array(wrong)).is_empty()

## The generator writes new rooms from the same tables.
func test_the_generator_tables_match() -> void:
	var source := FileAccess.get_file_as_string("res://tools/maps/gen_world_shells.py")
	var missing := PackedStringArray()
	for region: String in REGION_TILESETS:
		if not region.begins_with("trials_") and not source.contains('"%s": "%s"' % [region, REGION_TILESETS[region]]):
			missing.append(region)
	for room: String in ROOM_TILESETS:
		if not TRIAL_ROOMS.has(room) and not source.contains('"%s": "%s"' % [room, ROOM_TILESETS[room]]):
			missing.append(room)
	assert_array(Array(missing)).is_empty()

func _files_under(dir: String, extensions: Array) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_files_under(dir.path_join(sub), extensions))
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in extensions:
			found.append(dir.path_join(file))
	return found

## "No earth there" (user, 2026-10-08): roots must find nothing to join in these biomes; the ash scree is stone.
func test_the_biomes_without_earth_draw_none() -> void:
	for id: String in ["frost_edge", "lighthouse", "summer_caldera", "summer_caldera_ash"]:
		var biome := BiomeTileset.find(id)
		assert_object(biome).override_failure_message("%s is missing" % id).is_not_null()
		assert_bool(biome.has_look(BiomeTileset.Look.EARTH)).override_failure_message("%s draws earth" % id).is_false()

func test_an_unknown_id_is_null() -> void:
	assert_object(BiomeTileset.find("no_such_biome")).is_null()

func test_every_biome_is_sound_and_named_by_its_file() -> void:
	for biome: BiomeTileset in _biomes():
		assert_array(Array(biome.problems())).is_empty()
		assert_object(BiomeTileset.find(biome.id())).is_same(biome)

## A declared variant missing from a sheet would draw a hole in the street's top 4 cells in 5.
func test_every_declared_variant_is_drawn_in_every_band() -> void:
	for biome: BiomeTileset in _biomes():
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look) or biome.variants(look) == 0:
				continue
			var image := biome.sheet(look).get_image()
			var tile := image.get_width() / BiomeTileset.COLUMNS
			for band: int in 3:
				for variant: int in range(1, biome.variants(look) + 1):
					for mask: int in [GroundAutotile.FULL] + GroundAutotile.EDGE_MASKS:
						var at := GroundAutotile.varied_coords(mask, variant) + Vector2i(0, band * GroundAutotile.BAND_ROWS)
						var empty := image.get_region(Rect2i(at * tile, Vector2i(tile, tile))).is_invisible()
						assert_bool(empty).override_failure_message("%s %d: variant %d of mask %d is empty in band %d" % [biome.id(), look, variant, mask, band]).is_false()

## A fill variant that is almost the plain fill or another variant draws the same cell twice
## (bugs/painted-tile-variants-repeat-because-fixed-position-details-ignore-their-seed).
func test_every_fill_variant_is_distinct() -> void:
	var problems := PackedStringArray()
	for biome: BiomeTileset in _biomes():
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look) or biome.variants(look) == 0:
				continue
			var image := biome.sheet(look).get_image()
			var tile := image.get_width() / BiomeTileset.COLUMNS
			var fills: Array[Vector2i] = [GroundAutotile.wang_coords(GroundAutotile.FULL)]
			for variant: int in range(1, biome.variants(look) + 1):
				fills.append(GroundAutotile.varied_coords(GroundAutotile.FULL, variant))
			for i: int in fills.size():
				for j: int in range(i + 1, fills.size()):
					var differ := _differing_art_px(image, fills[i] * tile, fills[j] * tile, tile)
					if differ < MIN_DISTINCT_ART_PX:
						problems.append("%s %s: fills %d and %d differ by %d art px" % [biome.id(), BiomeTileset.Look.keys()[look], i, j, differ])
	assert_array(Array(problems)).is_empty()

## Art px (2x2 game px, sampled at even coordinates) that differ between two tiles of `size` game px.
func _differing_art_px(image: Image, a: Vector2i, b: Vector2i, size: int) -> int:
	var count := 0
	for y: int in range(0, size, 2):
		for x: int in range(0, size, 2):
			if image.get_pixel(a.x + x, a.y + y) != image.get_pixel(b.x + x, b.y + y):
				count += 1
	return count

func test_the_tile_set_defines_every_slot_of_each_present_look() -> void:
	for biome: BiomeTileset in _biomes():
		var tile_set := biome.tile_set()
		for look: int in BiomeTileset.Look.values():
			if not biome.has_look(look):
				assert_bool(tile_set.has_source(look)).is_false()
				continue
			var source := tile_set.get_source(look) as TileSetAtlasSource
			assert_int(source.get_tiles_count()).is_equal(BiomeTileset.COLUMNS * BiomeTileset.ROWS)

func test_a_crack_sheet_defines_every_variant_of_every_band() -> void:
	for biome: BiomeTileset in _biomes():
		if biome.crack == null:
			continue
		var source := biome.tile_set().get_source(BiomeTileset.CRACK_SOURCE) as TileSetAtlasSource
		assert_int(source.get_tiles_count()).is_equal(BiomeTileset.CRACK_VARIANTS * 3)
