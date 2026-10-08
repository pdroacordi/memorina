class_name TheCatchTest extends GdUnitTestSuite

## Combinado 3 is closed without both songs in order, read from the real map, platform, pulses and Ivo's reach.

const ROOM := "res://scenes/world/rooms/trials_solstice/contents/the_catch.room"
const PLATFORM := "res://scenes/world/interactables/lowering_platform/lowering_platform.tscn"
const RELEASE_STATS := "res://resources/memory/release_pulse_stats.tres"
const ROOT_STATS := "res://resources/memory/root_pulse_stats.tres"
const ROOT_SCENE := "res://scenes/world/memory/song_effects/roots/root_grower.tscn"
const VOICE := "res://scenes/characters/ivo/abilities/memorina_voice.gd"
const CELL := 32.0
const FLOOR_ROW := 16
const MARGIN := 8.0
const WELL_LEFT_WALL := 9
const WELL_RIGHT_WALL := 15
## Seconds the last note rings before a performance starts (systems/songs-and-the-memorina).
const RING := 1.6

var _map: RoomMap

func before() -> void:
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM)
	assert(result.ok(), str(result.errors))
	_map = result.map

func _solid(col: int, row: int) -> bool:
	return _map.is_solid(_map.origin + Vector2i(col, row))

func _peak() -> float:
	return MapGuide.ivo_reach().peak()

func _placed() -> Dictionary:
	for placed: Dictionary in _map.entities:
		if placed.symbol == "V":
			return placed
	return {}

func _centre_col() -> int:
	return (_placed().cell as Vector2i).x - _map.origin.x

func _platform() -> LoweringPlatform:
	var platform := auto_free((load(PLATFORM) as PackedScene).instantiate()) as LoweringPlatform
	EntityParams.apply(platform, _placed().params)
	return platform

## Height above the floor of the exit's floor in the well's right wall.
func _exit_floor() -> float:
	var row := FLOOR_ROW - 1
	while _solid(WELL_RIGHT_WALL, row):
		row -= 1
	return (FLOOR_ROW - row - 1) * CELL

## Heights of the platform's top from which Ivo jumps onto it from the floor and from it into the exit.
func _window() -> Vector2:
	return Vector2(_exit_floor() - (_peak() - MARGIN), _peak() - MARGIN)

func test_the_exit_and_the_hanging_platform_are_out_of_reach() -> void:
	assert_float(_exit_floor()).is_greater(_peak())
	assert_float(_platform().hang_height).is_greater(_peak())

func test_a_platform_seized_at_the_right_height_reaches_the_exit() -> void:
	var window := _window()
	assert_float(window.y - window.x).is_greater_equal(64.0)

func test_lowered_all_the_way_it_leaves_the_exit_out_of_reach() -> void:
	var platform := _platform()
	assert_float(platform.hang_height - platform.drop).is_less(_window().x)

func test_soltar_from_under_it_reaches_the_brake() -> void:
	var radius := (load(RELEASE_STATS) as PulseStats).max_radius
	assert_float(_platform().hang_height).is_less(radius + LoweringPlatform.BRAKE_RADIUS)

## Enraizar from the floor under the platform covers both earth faces at the top of the window, and both are earth there.
func test_enraizar_from_the_floor_covers_the_walls_at_the_window() -> void:
	var radius := (load(ROOT_STATS) as PulseStats).max_radius
	var x := (_centre_col() + 0.5) * CELL
	var far := maxf(x - (WELL_LEFT_WALL + 1) * CELL, WELL_RIGHT_WALL * CELL - x)
	assert_float(Vector2(far, _window().y).length()).is_less(radius)
	var half := _platform().width_cells / 2
	for height: float in [_window().x, _window().y]:
		var row := FLOOR_ROW - ceili(height / CELL)
		var left := _map.origin + Vector2i(_centre_col() - half - 1, row)
		var right := _map.origin + Vector2i(_centre_col() + half + 1, row)
		assert_int(RootCatchFinder.earth_face(_map, left, -1, RootGrower.MAX_CATCH_CELLS)).is_equal(_map.origin.x + WELL_LEFT_WALL)
		assert_int(RootCatchFinder.earth_face(_map, right, 1, RootGrower.MAX_CATCH_CELLS)).is_equal(_map.origin.x + WELL_RIGHT_WALL)

func test_enraizar_alone_grows_nothing_to_climb() -> void:
	var grower := auto_free((load(ROOT_SCENE) as PackedScene).instantiate()) as RootGrower
	var spans := RootSpanFinder.find(_map, grower.wet_bridge_cells, grower.max_shaft_width, grower.min_shaft_rows, grower.max_pillar_cells)
	assert_int(spans.size()).is_equal(0)

## Six notes and the ring after Soltar: the platform is still above the window.
func test_enraizar_at_once_seizes_it_too_high() -> void:
	var gap: float = (load(VOICE) as Script).get_property_default_value("min_note_gap")
	var platform := _platform()
	var at_once := platform.hang_height - platform.lower_speed * (5.0 * gap + RING)
	assert_float(at_once).is_greater(_window().y)

func test_the_window_lasts_at_least_two_seconds() -> void:
	var window := _window()
	assert_float((window.y - window.x) / _platform().lower_speed).is_greater_equal(2.0)

## Enraizar first seizes it where it hangs, between earth faces, far above the window.
func test_enraizar_first_seizes_it_out_of_reach() -> void:
	var platform := _platform()
	var row := FLOOR_ROW + floori(-(platform.hang_height - 5.0) / CELL)
	var half := platform.width_cells / 2
	assert_int(RootCatchFinder.earth_face(_map, _map.origin + Vector2i(_centre_col() - half - 1, row), -1, RootGrower.MAX_CATCH_CELLS)).is_greater_equal(0)
	assert_int(RootCatchFinder.earth_face(_map, _map.origin + Vector2i(_centre_col() + half + 1, row), 1, RootGrower.MAX_CATCH_CELLS)).is_greater_equal(0)
	assert_float(platform.hang_height).is_greater(_window().y + 64.0)
