class_name WinterTrialTest extends GdUnitTestSuite

## The bottom of the well is only a puzzle if the water keeps Ivo from the
## passage, and Redoma played at the edge dries the way down to it. Read from
## the real map, Redoma's pulse and Ivo's reach.

const ROOM := "res://scenes/world/rooms/trials_winter/contents/winter_trial.room"
const SHELL_STATS := "res://resources/memory/bell_jar_pulse_stats.tres"
const CELL := 32.0
const FLOOR_ROW := 16

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
	assert_int(in_well).is_equal((well.y - well.x) * 6)

func test_a_low_passage_opens_at_the_foot_of_the_near_wall() -> void:
	var well := _well()
	var bottom := FLOOR_ROW
	while not _solid(well.x, bottom):
		bottom += 1
	assert_bool(_solid(well.x - 1, bottom - 1)).is_false()
	assert_bool(_solid(well.x - 1, bottom - 2)).is_false()
	assert_bool(_solid(well.x - 1, FLOOR_ROW)).is_true()

## Only the geometry: the shell's reach from the edge. That a shell holds the
## water out is water_hold_out_test; that the route plays is the
## song_bell_jar_well timeline.
func test_redoma_at_the_edge_dries_the_way_down_to_it() -> void:
	var well := _well()
	var edge := (well.x - 0.5) * CELL
	var column := (well.x + 0.5) * CELL
	assert_float(absf(column - edge)).is_less(_radius())
