class_name WinterTrialTest extends GdUnitTestSuite

## Checks the well route against the real map, Redoma pulse, and Ivo reach.

const ROOM := "res://scenes/world/rooms/trials_winter/contents/winter_trial.room"
const SHELL_STATS := "res://resources/memory/bell_jar_pulse_stats.tres"
const CELL := 32.0
const FLOOR_ROW := 16
const REGION := "res://scenes/world/rooms/trials_winter.tscn"
const RELEASE_STATS := "res://resources/memory/release_pulse_stats.tres"
const WIND_ZONE := "res://scenes/world/environment/wind/wind_zone.tscn"
const DRAWBRIDGE := "res://scenes/world/interactables/drawbridge/drawbridge.tscn"
const VOICE := "res://scenes/characters/ivo/abilities/memorina_voice.gd"
const PLAYER := "res://scenes/characters/ivo/player.gd"
const LOCOMOTION_STATS := "res://resources/characters/locomotion_stats.gd"
const NOTES := 6

var _map: RoomMap

func before() -> void:
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM)
	assert(result.ok(), str(result.errors))
	_map = result.map

func _solid(col: int, row: int) -> bool:
	return _map.is_solid(_map.origin + Vector2i(col, row))

func _well() -> Vector2i:
	var start := -1
	for col: int in _map.size.x:
		var open := not _solid(col, FLOOR_ROW)
		if open and start < 0:
			start = col
		elif not open and start >= 0:
			return Vector2i(start, col)
	return Vector2i.ZERO

## Cells from the brim to the well's floor.
func _depth() -> int:
	var bottom := FLOOR_ROW
	while not _solid(_well().x, bottom):
		bottom += 1
	return bottom - FLOOR_ROW

func _radius() -> float:
	return (load(SHELL_STATS) as PulseStats).max_radius

func test_the_well_is_too_wide_to_jump() -> void:
	var well := _well()
	assert_float((well.y - well.x) * CELL).is_greater(MapGuide.ivo_reach().gap())

func test_it_is_full_of_water() -> void:
	var well := _well()
	var cells: PackedVector2Array = _map.water.get("~", PackedVector2Array())
	var in_well := 0
	for cell: Vector2 in cells:
		var col := int(cell.x) - _map.origin.x
		if col >= well.x and col < well.y:
			in_well += 1
	assert_int(in_well).is_equal((well.y - well.x) * _depth())

func test_a_low_passage_opens_at_the_foot_of_the_near_wall() -> void:
	var well := _well()
	var bottom := FLOOR_ROW
	while not _solid(well.x, bottom):
		bottom += 1
	assert_bool(_solid(well.x - 1, bottom - 1)).is_false()
	assert_bool(_solid(well.x - 1, bottom - 2)).is_false()
	assert_bool(_solid(well.x - 1, FLOOR_ROW)).is_true()

## Checks shell coverage geometry; water exclusion and route play are covered by water_hold_out_test and song_bell_jar_well.
func test_redoma_at_the_edge_dries_the_way_down_to_it() -> void:
	var well := _well()
	var edge := Vector2((well.x - 0.5) * CELL, FLOOR_ROW * CELL)
	var floor_y := (FLOOR_ROW + _depth()) * CELL
	var far_side := well.x * CELL + CELL * 1.5
	assert_float(Vector2(far_side, floor_y).distance_to(edge)).is_less(_radius())

# --- Playing inside the gale --------------------------------------------------

func _placed(symbol: String) -> Dictionary:
	for placed: Dictionary in _map.entities:
		if placed.symbol == symbol:
			return placed
	return {}

func _cell_x(placed: Dictionary) -> float:
	return ((placed.cell as Vector2i).x - _map.origin.x + 0.5) * CELL

func _zone() -> WindZone:
	var zone := auto_free((load(WIND_ZONE) as PackedScene).instantiate()) as WindZone
	EntityParams.apply(zone, _placed("W").params)
	return zone

## The squall's box in room coordinates.
func _zone_rect() -> Rect2:
	var box := _zone().rect()
	return Rect2(box.position + Vector2(_cell_x(_placed("W")), 0.0), box.size)

func _hinge_x() -> float:
	return _cell_x(_placed("D"))

## The memory over the squall: the region's, lifted by the source authored over it.
func _squall_memory() -> float:
	var region := auto_free((load(REGION) as PackedScene).instantiate()) as Node
	var memory := (region.get_node("Memory") as RegionMemory).authored
	var source := region.get_node("SquallMemory") as MemorySource
	var covered := Rect2(source.position - source.rect_size * 0.5, source.rect_size)
	if covered.encloses(_zone_rect()):
		memory += source.strength
	return clampf(memory, 0.0, 1.0)

func _gale_chasm() -> Vector2i:
	var start := -1
	for col: int in range(_well().y, _map.size.x):
		var open := not _solid(col, FLOOR_ROW)
		if open and start < 0:
			start = col
		elif not open and start >= 0:
			return Vector2i(start, col)
	return Vector2i.ZERO

func _deadzone() -> float:
	return (load(LOCOMOTION_STATS) as Script).get_property_default_value("wind_deadzone")

func _shelter() -> float:
	return (load(PLAYER) as Script).get_property_default_value("memorina_shelter")

## Longest stretch, in real seconds, of wind a drawn Memorina's grip ignores; the squall's clock runs at its memory.
func _longest_calm() -> float:
	var zone := _zone()
	var memory := _squall_memory()
	var step := 0.01
	var longest := 0.0
	var run := 0.0
	# Two periods, so a calm spanning the cycle's end is measured whole.
	for i: int in int(zone.profile.period() * 2.0 / step):
		if zone.speed * zone.profile.strength(i * step) * memory * _shelter() <= _deadzone():
			run += step / memory
			longest = maxf(longest, run)
		else:
			run = 0.0
	return longest

func test_the_squall_is_remembered() -> void:
	assert_float(_squall_memory()).is_equal(1.0)

func test_a_gust_breaks_a_drawn_memorina() -> void:
	assert_float(_zone().speed * _squall_memory() * _shelter()).is_greater(_deadzone())

## The six notes alone take five note gaps; every calm is shorter.
func test_no_calm_is_long_enough_for_a_song() -> void:
	var gap: float = (load(VOICE) as Script).get_property_default_value("min_note_gap")
	assert_float(_longest_calm()).is_less((NOTES - 1) * gap)

func test_he_can_walk_into_a_gust() -> void:
	var locomotion := load("res://resources/characters/ivo/ivo_locomotion_stats.tres") as LocomotionStats
	var drift := (_zone().speed * _squall_memory() - locomotion.wind_deadzone) * locomotion.wind_grip
	assert_float(locomotion.move_speed).is_greater(drift)

func test_the_gale_chasm_is_too_wide_to_jump() -> void:
	var chasm := _gale_chasm()
	assert_float((chasm.y - chasm.x) * CELL).is_greater(MapGuide.ivo_reach().gap())

func test_the_raised_bridge_is_a_wall_no_jump_clears() -> void:
	var bridge := auto_free((load(DRAWBRIDGE) as PackedScene).instantiate()) as Drawbridge
	EntityParams.apply(bridge, _placed("D").params)
	assert_float(bridge.length_cells * CELL).is_greater(MapGuide.ivo_reach().peak(true))

func test_the_bridge_spans_the_chasm() -> void:
	var bridge := auto_free((load(DRAWBRIDGE) as PackedScene).instantiate()) as Drawbridge
	EntityParams.apply(bridge, _placed("D").params)
	assert_float(_hinge_x()).is_less_equal(_gale_chasm().x * CELL)
	assert_float(_hinge_x() + bridge.length_cells * CELL).is_greater(_gale_chasm().y * CELL)

func test_from_the_calm_soltar_misses_the_hinge() -> void:
	var radius := (load(RELEASE_STATS) as PulseStats).max_radius
	assert_float(_hinge_x() - _zone_rect().position.x).is_greater(radius + Drawbridge.RECEIVER_RADIUS)

## Redoma at the edge of the squall: halfway out to its shell, Soltar reaches the hinge.
func test_inside_the_shell_soltar_reaches_the_hinge() -> void:
	var radius := (load(RELEASE_STATS) as PulseStats).max_radius
	var inside := _zone_rect().position.x + _radius() * 0.5
	assert_float(_hinge_x() - inside).is_less(radius)
