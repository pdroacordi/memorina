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
const REGION_SKY := "Over two wall tops at a region border, both rooms show their regions' open sets: the same art at two horizons, so a wall climb over the pillar shows a straight line in the sky. The user accepted this line until the region backdrops share one sky ('OK until skies match (Recommended)', 2026-10-13)."
const RINGS_MEET := "The rooms are two rings apart: their rings meet on this line and no frame of either room reaches it."
const TRIALS_APART := "The rooms are 256 px apart, so their rings overlap by 64 px and each draws its own ring there; they do not touch, so they are never resident together and a frame shows one room's ring only."
const WELL := "The fishing village's well mouth: WORLD-29 (Plan B, 'Well as a door') closes lake_well's row 0 and moves the well onto the shore."
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
	"lake_fishing_village|lake_well rooms: y -1536, x 1536..1664": WELL,
	"lake_fishing_village|lake_well ring: x 1120, y -1536..-1376": WELL,
	"lake_fishing_village|lake_well ring: x 2080, y -1536..-1376": WELL,
	"lake_high_wall|lake_shore ring: y -2080, x -1280..-1120": RING_LIMIT,
	"lake_high_wall|lake_shore ring: x -1280, y -1536..-1376": BELOW_FLOORS,
	"lake_chasm|orchard_well ring: y -1696, x -3360..-3200": RING_LIMIT,
	"lake_chasm|orchard_well ring: x -2400, y -1536..-1376": RING_LIMIT,
	"lake_chasm|orchard_chasm_bridge ring: x -3200, y -2464..-2304": REGION_SKY,
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
	"door_trial|the_catch ring: x 18336, y 5520..6224": TRIALS_APART,
	"lake_chasm|lake_high_wall ring: y -2464, x -2080..-1920": RING_LIMIT,
	"caldera_chimney_base|orchard_cliff_chimney ring: y 1376, x -10240..-10080": RING_LIMIT,
	"caldera_cistern_bottom|caldera_temple_gate ring: y 1376, x 1280..1440": RING_LIMIT,
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
