class_name BackdropSeamsTest extends GdUnitTestSuite

## Where two rooms draw different backdrops the hard cut between them touches an opaque cell, in every room the game and
## DebugTrials place (systems/backdrops, architecture/backdrop-seams).

const VALLEY := preload("res://resources/world/backdrops/village_valley.tres")
const CAVES := preload("res://resources/world/backdrops/ice_caves.tres")
const GAME := "res://scenes/world/game.tscn"
const REGION_SCRIPT := preload("res://scenes/world/rooms/region.gd")
const DEBUG_TRIALS := preload("res://scenes/world/debug/debug_trials.gd")
## Reasons for a listed cut. A ring cut lies in the void outside both rooms; the cell walk cannot tell whether a frame
## reaches it, so each class was checked against the rooms' maps and in windowed stills (systems/backdrops).
const RING_LIMIT := "On one room's ring limit, which none of its frames crosses; the other room's edge facing it is solid ground, so none of its frames yields there, and no glide between them reaches it."
const BELOW_FLOORS := "The seam continued straight down under both rooms' solid floors: no frame yields below them."
const UNDER_FLOOR := "Under one room's solid floor, on the ring limit of the deeper room beside it, whose wall goes on down there: no resting frame reaches it; a glide between the two rooms shows the strip for about 0.15 s (about 9 frames, measured by the WORLD-28 re-review)."
const PAST_WALLS := "The seam continued straight out past both rooms' solid end walls, with no room beyond: no frame yields there."
const REGION_TOPS := "Over two wall tops at a region border: even at the highest frame (a wall climb onto the seam pillar and a jump, the frame capped at the ring, 160 px over the tops), no layer of either set but the shared sky shows above the tops at the seam, or above the cover prop standing on them, and the shared sky is one texture with no vertical scroll, so it stands at eye level on any horizon, in the current region's season, and the line shows nothing (test_a_region_tops_cut_shows_only_the_shared_sky; WORLD-33)."
const GATE_TOWER := "Over the village's border gate pillar: the gate tower (gate_tower.tscn, a prop on the pillar; 'Cover with a tall gate tower (Recommended)', user, 2026-10-13) covers the seam column from 178 px over the tops down into the pillar, past the highest frame Ivo reaches there (a wall climb onto the pillar and a jump, the frame capped at the ring, 160 px over the tops) (test_a_gate_tower_covers_its_cut)."
const TRIAL_TOPS := "Over the wall tops between two debug trials (DebugTrials, F10) in two regions: a double jump from the seam pillar raises the frame about 50 px over the tops, where the two borrowed sets' far layers may stop on one line; the trials are test beds, not the game."
const UNDER_FLOOR_REGION := "Under one room's solid floor, on the ring limit of the deeper room beside it in another region, whose wall goes on down there: no frame of either room reaches it, and a region border cuts instead of gliding."
const TRIALS_CLOSE := "The rooms are 32 px apart, so one room's ring reaches 128 px into the other; they do not touch, so they are never resident together and a frame shows one room's drawing only."
const RINGS_MEET := "The rooms are two rings apart: their rings meet on this line and no frame of either room reaches it."
const TRIALS_APART := "The rooms are 256 px apart, so their rings overlap by 64 px and each draws its own ring there; they do not touch, so they are never resident together and a frame shows one room's ring only."
const DOOR_PAIR := "Under the fishing village's deck and lake, on lake_well's ring limit: the two rooms join only by the stairwell and its hatch (WORLD-29), so no walk or glide crosses this seam; Ivo never goes below the deck, and a lake_well frame is the room's own width."
## `BackdropCut.key()` (room pair, kind and segment) -> why an open cut there is accepted. A new cut between two listed
## rooms is a new key and fails.
const ALLOWED := {
	"caldera_cistern|village_square ring: x 480, y 384..544": RING_LIMIT,
	"caldera_cistern|village_square ring: x 1440, y 384..544": RING_LIMIT,
	"village_tavern|village_tavern_cellar ring: x 3040, y 12000..12544": RINGS_MEET,
	"village_bell_tower|village_empty_house ring: x 9440, y 12000..12544": RINGS_MEET,
	"frost_cliffs|frost_shore ring: x 9600, y 384..544": BELOW_FLOORS,
	"frost_cliffs|frost_shore ring: y -160, x 9440..9600": RING_LIMIT,
	"frost_cliffs|lighthouse_base ring: x 11040, y -768..-608": UNDER_FLOOR,
	"frost_cliffs|lighthouse_top ring: y -1312, x 10720..10880": RING_LIMIT,
	"lighthouse_base|lighthouse_top ring: y -1152, x 12160..12320": PAST_WALLS,
	"woods_edge|woods_root_caves ring: x -2400, y 384..544": RING_LIMIT,
	"woods_pond|woods_root_caves ring: x -4640, y 384..544": RING_LIMIT,
	"lake_waterfall_path|village_mill ring: y -160, x 2400..2560": RING_LIMIT,
	"lake_waterfall_path|village_gate_east ring: y -160, x 3200..3360": RING_LIMIT,
	"lake_fishing_village|lake_waterfall_path ring: x 2400, y -1536..-1376": UNDER_FLOOR,
	"lake_fishing_village|lake_well ring: x 1120, y -1536..-1376": DOOR_PAIR,
	"lake_fishing_village|lake_well ring: x 2080, y -1536..-1376": DOOR_PAIR,
	"lake_high_wall|lake_shore ring: y -2080, x -1280..-1120": RING_LIMIT,
	"lake_high_wall|lake_shore ring: x -1280, y -1536..-1376": BELOW_FLOORS,
	"lake_chasm|orchard_well ring: y -1696, x -3360..-3200": RING_LIMIT,
	"lake_chasm|orchard_well ring: x -2400, y -1536..-1376": RING_LIMIT,
	"lake_chasm|orchard_chasm_bridge ring: x -3200, y -2464..-2304": REGION_TOPS,
	"lake_chasm|orchard_chasm_bridge ring: x -3360, y -1920..-1760": RING_LIMIT,
	"orchard_terraces|woods_canopy ring: x -4640, y -1152..-992": RING_LIMIT,
	"orchard_well|woods_canopy ring: y -1152, x -2560..-2400": PAST_WALLS,
	"orchard_counterweights|orchard_windy_gap ring: y -2080, x -6560..-6400": RING_LIMIT,
	"orchard_counterweights|orchard_terraces ring: y -2080, x -5760..-5600": RING_LIMIT,
	"orchard_arena|orchard_cliff_chimney ring: x -10080, y -1152..-992": UNDER_FLOOR,
	"caldera_open_crater|caldera_seesaw ring: x -2080, y 1920..2080": UNDER_FLOOR,
	"caldera_cistern_bottom|caldera_open_crater ring: x -480, y 1920..2080": UNDER_FLOOR,
	"caldera_cistern|caldera_cistern_bottom ring: y 992, x 480..640": RING_LIMIT,
	"caldera_cistern|caldera_cistern_bottom ring: y 1152, x 1280..1440": PAST_WALLS,
	"the_catch|water_trial ring: x 17632, y 6128..6256": UNDER_FLOOR,
	"the_catch|water_trial ring: y 6256, x 17472..17632": UNDER_FLOOR,
	"the_catch|water_trial ring: x 17472, y 6256..6288": BELOW_FLOORS,
	"the_catch|water_trial ring: y 6288, x 17472..17632": RING_LIMIT,
	"door_trial|the_catch ring: x 18336, y 5520..5680": TRIALS_APART,
	"lake_chasm|lake_high_wall ring: y -2464, x -2080..-1920": RING_LIMIT,
	"caldera_chimney_base|orchard_cliff_chimney ring: y 1376, x -10240..-10080": RING_LIMIT,
	"caldera_cistern_bottom|caldera_temple_gate ring: y 1376, x 1280..1440": RING_LIMIT,
	# Region borders since each region shows its own set (WORLD-30); the passages are hidden by [back] walls.
	"village_lane_west|woods_edge ring: x -1280, y -160..0": GATE_TOWER,
	"village_lane_west|woods_edge ring: x -1280, y 384..544": BELOW_FLOORS,
	"threshold_fields|village_gate_east ring: x 4480, y -160..0": GATE_TOWER,
	"threshold_fields|village_gate_east ring: x 4480, y 384..544": BELOW_FLOORS,
	"frost_shore|threshold_wayshrine ring: x 8320, y -160..0": REGION_TOPS,
	"frost_shore|threshold_wayshrine ring: x 8320, y 384..544": BELOW_FLOORS,
	"lake_ice_caves|lake_waterfall_path ring: x 3360, y -1536..-1376": UNDER_FLOOR,
	"caldera_chimney_base|orchard_cliff_chimney ring: x -10240, y 1920..2080": BELOW_FLOORS,
	# woods_hollow_tree's ring beside its closed walls (WORLD-35); its mouth and the mill town's well have [back] walls.
	"orchard_mill_town|woods_hollow_tree ring: x -6880, y -1152..-992": UNDER_FLOOR_REGION,
	"orchard_leaf_path|woods_hollow_tree ring: x -7840, y -1152..-992": UNDER_FLOOR_REGION,
	"bloom_hollow|woods_hollow_tree ring: y -160, x -7040..-6880": RING_LIMIT,
	"bloom_hollow|woods_hollow_tree ring: x -7040, y 384..544": BELOW_FLOORS,
	"summer_trial|winter_trial ring: x 2400, y 5328..5488": TRIAL_TOPS,
	"summer_trial|winter_trial ring: x 2400, y 6256..6288": BELOW_FLOORS,
	"summer_trial|winter_trial ring: x 2560, y 6128..6256": UNDER_FLOOR_REGION,
	"summer_trial|winter_trial ring: y 6256, x 2400..2560": UNDER_FLOOR_REGION,
	"summer_trial|winter_trial ring: y 6288, x 2400..2560": RING_LIMIT,
	"solstice_trial|spring_trial ring: x 9600, y 5328..5488": TRIAL_TOPS,
	"solstice_trial|spring_trial ring: x 9600, y 6256..6288": BELOW_FLOORS,
	"solstice_trial|spring_trial ring: x 9760, y 6128..6256": UNDER_FLOOR_REGION,
	"solstice_trial|spring_trial ring: y 6256, x 9600..9760": UNDER_FLOOR_REGION,
	"solstice_trial|spring_trial ring: y 6288, x 9600..9760": RING_LIMIT,
	"autumn_trial|spring_trial ring: x 7328, y 5328..6000": TRIALS_CLOSE,
	"autumn_trial|spring_trial ring: x 7328, y 6256..6288": TRIALS_CLOSE,
	"autumn_trial|spring_trial ring: y 6288, x 7040..7328": TRIALS_CLOSE,
}

## Ring cuts over the tops a gate tower covers: key -> the region scene, the room and the tower node in its contents.
const TOWERS := {
	"village_lane_west|woods_edge ring: x -1280, y -160..0": ["res://scenes/world/rooms/home_village.tscn", "VillageLaneWest", "Props/GateTower"],
	"threshold_fields|village_gate_east ring: x 4480, y -160..0": ["res://scenes/world/rooms/home_village.tscn", "VillageGateEast", "Props/GateTower"],
}
## REGION_TOPS cuts: key -> the two region scenes whose sets meet there, and the prop that covers the far layers, if
## any reach over the tops ([region scene, room, node in its contents], as TOWERS).
const TOPS := {
	"frost_shore|threshold_wayshrine ring: x 8320, y -160..0": {
		"regions": ["res://scenes/world/rooms/frost_edge.tscn", "res://scenes/world/rooms/threshold.tscn"],
	},
	"lake_chasm|orchard_chasm_bridge ring: x -3200, y -2464..-2304": {
		"regions": ["res://scenes/world/rooms/frozen_lake.tscn", "res://scenes/world/rooms/wind_orchards.tscn"],
		"cover": ["res://scenes/world/rooms/frozen_lake.tscn", "LakeChasm", "Props/BorderCairn"],
	},
}

var _seats: Array[BackdropSeamRoom] = []
var _problems := PackedStringArray()


func test_an_open_seam_between_two_pictures_is_a_cut() -> void:
	var seats: Array[BackdropSeamRoom] = [_seat("a", Rect2(0, 0, 640, 384), VALLEY), _seat("b", Rect2(640, 0, 640, 384), CAVES)]
	var found := _in_rooms(BackdropSeams.cuts(seats, Vector2.ZERO))
	assert_int(found.size()).is_equal(1)
	assert_bool(found[0].vertical).is_true()
	assert_float(found[0].line).is_equal(640.0)
	assert_float(found[0].from).is_equal(0.0)
	assert_float(found[0].to).is_equal(384.0)
	assert_str(found[0].key()).is_equal("a|b rooms: x 640, y 0..384")

func test_an_opaque_cell_on_either_side_hides_the_cut() -> void:
	var a := _seat("a", Rect2(0, 0, 640, 384), VALLEY)
	var b := _seat("b", Rect2(640, 0, 640, 384), CAVES)
	# A's last column is a wall in rows 0..3, B's first column in rows 4..11.
	for row: int in 4:
		a.opaque[Vector2i(19, row)] = true
	for row: int in range(4, 12):
		b.opaque[Vector2i(20, row)] = true
	var seats: Array[BackdropSeamRoom] = [a, b]
	assert_array(_in_rooms(BackdropSeams.cuts(seats, Vector2.ZERO))).is_empty()
	b.opaque.erase(Vector2i(20, 7))
	var found := _in_rooms(BackdropSeams.cuts(seats, Vector2.ZERO))
	assert_int(found.size()).is_equal(1)
	assert_float(found[0].from).is_equal(224.0)
	assert_float(found[0].to).is_equal(256.0)

func test_one_picture_has_no_cut() -> void:
	var seats: Array[BackdropSeamRoom] = [_seat("a", Rect2(0, 0, 640, 384), VALLEY), _seat("b", Rect2(640, 0, 640, 384), VALLEY)]
	assert_array(BackdropSeams.cuts(seats, Vector2.ZERO)).is_empty()
	var stacked: Array[BackdropSeamRoom] = [_seat("a", Rect2(0, 0, 640, 384), VALLEY, 235.0), _seat("b", Rect2(0, -384, 640, 384), VALLEY, -149.0)]
	assert_int(BackdropSeams.cuts(stacked, Vector2.ZERO).size()).is_greater(0)

## The void above and below two rooms is never opaque: the seam continued straight into the ring is a cut there.
func test_the_seam_continued_into_the_void_is_a_ring_cut() -> void:
	var a := _seat("a", Rect2(0, 0, 640, 384), VALLEY)
	var b := _seat("b", Rect2(640, 0, 640, 384), CAVES)
	for row: int in 12:
		a.opaque[Vector2i(19, row)] = true
	var seats: Array[BackdropSeamRoom] = [a, b]
	var found := BackdropSeams.cuts(seats, Vector2.ZERO)
	assert_int(found.size()).is_equal(2)
	var spans: Array[Vector2] = []
	for cut: BackdropCut in found:
		assert_bool(cut.in_ring and cut.vertical and cut.line == 640.0).is_true()
		spans.append(Vector2(cut.from, cut.to))
	spans.sort()
	assert_array(spans).is_equal([Vector2(-RoomRing.WIDTH, 0.0), Vector2(384.0, 384.0 + RoomRing.WIDTH)])

## bugs/a-wall-climb-over-the-seam-pillar-shows-the-wall-up-cut-in-the-sky: a rock room draws its region's sky over its top,
## so over two wall tops the seam continued up is no cut.
func test_over_a_rock_rooms_top_its_regions_sky_meets_the_open_room() -> void:
	var a := _seat("a", Rect2(0, 0, 640, 384), VALLEY)
	var b := BackdropSeamRoom.new("b", Rect2(640, 0, 640, 384), CAVES, Vector2(640, 235), VALLEY)
	for row: int in 12:
		a.opaque[Vector2i(19, row)] = true
	var seats: Array[BackdropSeamRoom] = [a, b]
	var found := BackdropSeams.cuts(seats, Vector2.ZERO)
	assert_int(found.size()).is_equal(1)
	assert_float(found[0].from).is_equal(384.0)

func test_a_lattice_off_the_world_grid_is_walked_on_its_own_cells() -> void:
	var seats: Array[BackdropSeamRoom] = [_seat("a", Rect2(0, 16, 640, 384), VALLEY), _seat("b", Rect2(640, 16, 640, 384), CAVES)]
	var found := _in_rooms(BackdropSeams.cuts(seats, Vector2(0, 16)))
	assert_int(found.size()).is_equal(1)
	assert_float(found[0].from).is_equal(16.0)
	assert_float(found[0].to).is_equal(400.0)

## Every open cut in the world and the trials is listed with its reason, and every listed key still matches a cut.
func test_every_open_cut_between_two_backdrops_is_listed() -> void:
	_load()
	assert_array(Array(_problems)).is_empty()
	var keys := {}
	var unlisted: Array[String] = []
	for cut: BackdropCut in _world_cuts():
		keys[cut.key()] = true
		if not ALLOWED.has(cut.key()):
			unlisted.append(cut.key())
	assert_array(unlisted) \
		.override_failure_message("Open cuts between two backdrops; hide each behind ground or a [back] wall, or list why:\n%s" \
			% "\n".join(unlisted)) \
		.is_empty()
	var stale: Array[String] = []
	for key: String in ALLOWED:
		if not keys.has(key):
			stale.append(key)
	assert_array(stale).is_empty()

## Every GATE_TOWER cut is a key in TOWERS, and its tower is opaque on one side of the seam at every height of the cut.
func test_a_gate_tower_covers_its_cut() -> void:
	for key: String in ALLOWED:
		if ALLOWED[key] == GATE_TOWER:
			assert_bool(TOWERS.has(key)).override_failure_message("%s: no tower listed" % key).is_true()
	for key: String in TOWERS:
		var cut := _parse_ring_key(key)
		var uncovered := _uncovered(cut, int(cut.y), TOWERS[key])
		assert_array(Array(uncovered)).override_failure_message("%s: the tower leaves y %s open" % [key, ",".join(uncovered)]).is_empty()

## At the highest frame over a REGION_TOPS cut no layer but the sky, in either set, draws above the rooms' tops at the
## seam, or above the cut's cover prop.
func test_a_region_tops_cut_shows_only_the_shared_sky() -> void:
	for key: String in ALLOWED:
		if ALLOWED[key] == REGION_TOPS:
			assert_bool(TOPS.has(key)).override_failure_message("%s: no region pair listed" % key).is_true()
	for key: String in TOPS:
		var cut := _parse_ring_key(key)
		# The frame's top at the ring limit, over the tops.
		var centre_y := cut.y + Backdrop.HALF_VIEW.y
		var reach := cut.z
		for path: String in TOPS[key]["regions"]:
			var region := (load(path) as PackedScene).instantiate() as Region
			assert_object(region.backdrop_set.layers[0].texture).is_equal(VALLEY.layers[0].texture)
			# No vertical scroll: the sky stands at eye level whatever the region's horizon.
			assert_float(region.backdrop_set.layers[0].scroll_scale.y).is_equal(0.0)
			for camera_x: int in range(int(cut.x - Backdrop.HALF_VIEW.x), int(cut.x + Backdrop.HALF_VIEW.x) + 1):
				for column: float in [cut.x - 0.5, cut.x + 0.5]:
					reach = minf(reach, _art_top(region.backdrop_set, Vector2(cut.x, region.horizon_y), Vector2(camera_x, centre_y), column))
			region.free()
		if not is_finite(reach):
			assert_bool(false).override_failure_message("%s: a layer fills above its strip, so art reaches every row" % key).is_true()
		elif TOPS[key].has("cover"):
			var uncovered := _uncovered(cut, floori(reach), TOPS[key]["cover"])
			assert_array(Array(uncovered)).override_failure_message("%s: the cover leaves y %s open" % [key, ",".join(uncovered)]).is_empty()
		else:
			assert_float(reach).override_failure_message("%s: art reaches y %.0f over the tops" % [key, reach]).is_greater_equal(cut.z)

# The rows from `top` down to the cut's bottom where neither pixel column beside the seam is opaque in the prop
# `spec` ([region scene, room, node in its contents]).
func _uncovered(cut: Vector3, top: int, spec: Array) -> PackedStringArray:
	var region := (load(spec[0]) as PackedScene).instantiate() as Region
	var room := region.get_node(spec[1]) as Room
	var contents := room.contents_scene.instantiate()
	var prop := contents.get_node(spec[2]) as Sprite2D
	var image := prop.texture.get_image()
	# The sprite's top-left in world px: region at (0, 0), contents at the room's origin.
	var origin := room.position + (prop.get_parent() as Node2D).position + prop.position + prop.offset
	var uncovered := PackedStringArray()
	for y: int in range(top, int(cut.z)):
		var covered := false
		for column: int in [int(cut.x) - 1, int(cut.x)]:
			var local := Vector2i(column - int(origin.x), y - int(origin.y))
			if Rect2i(Vector2i.ZERO, image.get_size()).has_point(local) and image.get_pixelv(local).a > 0.0:
				covered = true
		if not covered:
			uncovered.append(str(y))
	contents.free()
	region.free()
	return uncovered

# A ring key's vertical line: (x, from, to).
func _parse_ring_key(key: String) -> Vector3:
	var found := RegEx.create_from_string("x (-?\\d+), y (-?\\d+)\\.\\.(-?\\d+)").search(key)
	return Vector3(float(found.get_string(1)), float(found.get_string(2)), float(found.get_string(3)))

# The highest world y at which any layer after the sky draws art in world column `x`, for a camera centred at `centre`.
func _art_top(drawn: BackdropSet, anchor: Vector2, centre: Vector2, x: float) -> float:
	var top := INF
	for i: int in range(1, drawn.layers.size()):
		var layer := drawn.layers[i]
		if layer.fill_above != BackdropLayer.Fill.NONE:
			return -INF
		var at := BackdropMath.layer_anchor(anchor, layer.repeat_x, layer.repeats_y())
		var ref := BackdropMath.reference_centre(at, drawn.horizon_screen_y, Backdrop.HALF_VIEW)
		var placed := BackdropMath.anchor_position(at, ref, centre, layer.scroll_scale)
		var strip := layer.strip_size()
		var column := BackdropMath.art_col(floori(x - placed.x), strip.x, layer.repeat_x)
		if column < 0:
			continue
		var image := layer.texture.get_image()
		for row: int in strip.y:
			if image.get_pixel(column, row).a > 0.0:
				top = minf(top, placed.y + row - layer.horizon_row)
				break
	return top

func _in_rooms(found: Array[BackdropCut]) -> Array[BackdropCut]:
	var rooms: Array[BackdropCut] = []
	for cut: BackdropCut in found:
		if not cut.in_ring:
			rooms.append(cut)
	return rooms

func _seat(id: String, rect: Rect2, shown: BackdropSet, horizon: float = 235.0) -> BackdropSeamRoom:
	return BackdropSeamRoom.new(id, rect, shown, Vector2(rect.position.x, horizon))

# Seats on one lattice are checked together: the world's on the 32 px grid, the trials' half a cell lower.
func _world_cuts() -> Array[BackdropCut]:
	var groups := {}
	for seat: BackdropSeamRoom in _seats:
		var lattice := Vector2(fposmod(seat.rect.position.x, BackdropSeams.CELL), fposmod(seat.rect.position.y, BackdropSeams.CELL))
		if not groups.has(lattice):
			var fresh: Array[BackdropSeamRoom] = []
			groups[lattice] = fresh
		var group: Array[BackdropSeamRoom] = groups[lattice]
		group.append(seat)
	var found: Array[BackdropCut] = []
	for lattice: Vector2 in groups:
		found.append_array(BackdropSeams.cuts(groups[lattice], lattice))
	return found

func _load() -> void:
	var legend := RoomLegend.load_default()
	var state := (load(GAME) as PackedScene).get_state()
	for i: int in state.get_node_count():
		if _property(state, i, &"script") == DEBUG_TRIALS:
			var trials := DEBUG_TRIALS.new() as DebugTrials
			var regions: Array = _property(state, i, &"regions", trials.regions)
			var origin: Vector2 = _property(state, i, &"origin", trials.origin)
			var spacing: Vector2 = _property(state, i, &"spacing", trials.spacing)
			trials.free()
			for k: int in regions.size():
				_add_region(regions[k] as PackedScene, origin + spacing * k, legend)
		var scene := state.get_node_instance(i)
		if scene == null or scene.get_state().get_node_count() == 0 or _property(scene.get_state(), 0, &"script") != REGION_SCRIPT:
			continue
		_add_region(scene, _property(state, i, &"position", Vector2.ZERO), legend)

func _add_region(scene: PackedScene, at: Vector2, legend: RoomLegend) -> void:
	var region := scene.instantiate() as Region
	for child: Node in region.get_children():
		if child is Room:
			_add_room(child as Room, region, at, legend)
	region.free()

# A seat as Backdrop.refresh sees it: the override or the region's set, anchored at the room's x and the region's horizon.
func _add_room(room: Room, region: Region, at: Vector2, legend: RoomLegend) -> void:
	var shape := room.get_node("CollisionShape2D") as CollisionShape2D
	var size := (shape.shape as RectangleShape2D).size
	var bounds := Rect2(at + room.position + shape.position - size * 0.5, size)
	var contents := room.contents_scene.get_state()
	var own: BackdropSet = null
	var backdrop_at := Vector2.ZERO
	var map: RoomMap = null
	var map_at := Vector2.ZERO
	for i: int in contents.get_node_count():
		if contents.get_node_name(i) == &"Backdrop":
			own = _property(contents, i, &"backdrop_set")
			backdrop_at = _property(contents, i, &"position", Vector2.ZERO)
		var resource: Variant = _property(contents, i, &"map")
		if resource is RoomMap:
			var path := (resource as RoomMap).resource_path
			var parsed := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
			_problems.append_array(parsed.errors)
			map = parsed.map
			map_at = _property(contents, i, &"position", Vector2.ZERO)
	var anchor := Vector2(at.x + room.position.x + backdrop_at.x, at.y + region.horizon_y)
	var seat := BackdropSeamRoom.new(room.id(), bounds, Backdrop.shown_set(own, region), anchor, region.backdrop_set)
	if map == null:
		_problems.append("%s: no RoomMap" % room.id())
	else:
		_add_opaque(seat, map, at + room.position + map_at)
	_seats.append(seat)

func _add_opaque(seat: BackdropSeamRoom, map: RoomMap, map_at: Vector2) -> void:
	var lattice := Vector2(fposmod(seat.rect.position.x, BackdropSeams.CELL), fposmod(seat.rect.position.y, BackdropSeams.CELL))
	var first := Vector2i(((map_at + Vector2(map.origin) * RoomMap.CELL_PX - lattice) / BackdropSeams.CELL).round())
	var lakes: PackedVector2Array = map.water.get("w", PackedVector2Array())
	for y: int in map.size.y:
		for x: int in map.size.x:
			var cell := map.origin + Vector2i(x, y)
			var index := y * map.size.x + x
			var back := not map.back.is_empty() and map.back[index] != RoomMap.NO_LOOK
			if map.is_solid(cell) or back or lakes.has(Vector2(cell)):
				seat.opaque[first + Vector2i(x, y)] = true

func _property(state: SceneState, node: int, property: StringName, fallback: Variant = null) -> Variant:
	for j: int in state.get_node_property_count(node):
		if state.get_node_property_name(node, j) == property:
			return state.get_node_property_value(node, j)
	return fallback
