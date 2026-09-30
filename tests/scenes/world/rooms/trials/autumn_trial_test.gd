class_name AutumnTrialTest extends GdUnitTestSuite

## "Empurrado pelo Vendaval" (design 02 section 8, Outono Espacial 2) is only
## a puzzle if the chasm beats Ivo alone, beats the natural current alone and
## beats the gale alone - and yields to the gale played into the current. The
## map, the current's params, the gale's tuning and Ivo's jump are all read
## from the real files, so retuning any of them re-checks the puzzle.

const ROOM := "res://scenes/world/rooms/trials_autumn/contents/autumn_trial.room"
const GALE_SCENE := "res://scenes/world/memory/song_effects/gale/gale_field.tscn"
const PULSE_STATS := "res://resources/memory/default_pulse_stats.tres"
## Where the song is played: this many cells back from the edge, for a run-up.
const PLAY_CELLS_BACK := 3
## Ivo's AirflowBody samples the air this far above his feet.
const SAMPLE_OFFSET := Vector2(0, -28)
## The crossing must clear by at least this much, not scrape it.
const MARGIN := 16.0

var _map: RoomMap
var _chasm := Vector2i()
var _current_speed := 0.0

func before() -> void:
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM)
	assert(result.ok(), str(result.errors))
	_map = result.map
	# The first run of empty floor cells on the floor row is the chasm.
	var floor_row := 16
	var start := -1
	for x: int in _map.size.x:
		var solid := _map.is_solid(_map.origin + Vector2i(x, floor_row))
		if not solid and start < 0:
			start = x
		elif solid and start >= 0:
			_chasm = Vector2i(start, x)
			break
	for placed: Dictionary in _map.entities:
		if placed.symbol == "W":
			_current_speed = float(placed.params.speed)

func _width() -> float:
	return (_chasm.y - _chasm.x) * MapGuide.CELL

func _gale(point: Vector2) -> Vector2:
	var gale := (load(GALE_SCENE) as PackedScene).instantiate() as GaleField
	var speed := gale.speed
	var eye := gale.eye
	gale.free()
	var radius := (load(PULSE_STATS) as PulseStats).max_radius
	# Take-off is at the edge; the song was played PLAY_CELLS_BACK cells back.
	var origin := Vector2(-(PLAY_CELLS_BACK * MapGuide.CELL - MapGuide.CELL * 0.5), 0.0)
	return GaleShape.wind(origin, point + SAMPLE_OFFSET, radius, eye, speed)

func _reach(wind: Callable) -> float:
	var reach := MapGuide.ivo_reach()
	reach.wind = wind
	return reach.gap()

func test_the_room_has_a_chasm_and_a_current() -> void:
	assert_int(_chasm.y - _chasm.x).is_greater(0)
	assert_float(_current_speed).is_greater(0.0)

func test_a_running_jump_falls_short() -> void:
	assert_float(_reach(Callable())).is_less(_width())

func test_the_current_alone_falls_short() -> void:
	assert_float(_reach(func(_p: Vector2) -> Vector2: return Vector2(_current_speed, 0))).is_less(_width())

func test_the_gale_alone_falls_short() -> void:
	assert_float(_reach(_gale)).is_less(_width())

func test_the_gale_played_into_the_current_carries_across() -> void:
	var both := func(p: Vector2) -> Vector2: return _gale(p) + Vector2(_current_speed, 0)
	assert_float(_reach(both)).is_greater_equal(_width() + MARGIN)
