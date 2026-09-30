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
	# Take-off is at the edge; the song was played PLAY_CELLS_BACK cells back,
	# facing the chasm, so the gale blows across it.
	var origin := Vector2(-(PLAY_CELLS_BACK * MapGuide.CELL - MapGuide.CELL * 0.5), 0.0)
	return GaleShape.wind(origin, point + SAMPLE_OFFSET, radius, eye, speed, 1.0)

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

# --- Soltar ------------------------------------------------------------------

const RELEASE_STATS := "res://resources/memory/release_pulse_stats.tres"
## HangingLoad's body height and half width (hanging_load.tscn).
const LOAD_HEIGHT := 44.0
const LOAD_HALF_WIDTH := 14.0
const FLOOR_ROW := 16

func _entity(id: String) -> Dictionary:
	for placed: Dictionary in _map.entities:
		if placed.params.get("id", "") == id:
			return placed
	return {}

## Grid column and row of an entity (its cell is a world cell).
func _cell(id: String) -> Vector2i:
	return (_entity(id).cell as Vector2i) - _map.origin

## Height above the floor of the top of the first solid cell in `col`.
func _top(col: int) -> float:
	for row: int in _map.size.y:
		if _map.is_solid(_map.origin + Vector2i(col, row)):
			return (FLOOR_ROW - row) * MapGuide.CELL
	return 0.0

## A hanging load's (bottom, top) above the floor, and its column centre x.
func _hanging(id: String) -> Vector3:
	var cell := _cell(id)
	var bottom := (FLOOR_ROW - 1 - cell.y) * MapGuide.CELL + float(_entity(id).params.hang_height)
	return Vector3(bottom, bottom + LOAD_HEIGHT, (cell.x + 0.5) * MapGuide.CELL)

## How near a pulse lit on the floor at column `col` comes to a load.
func _distance_to_load(col: int, id: String) -> float:
	var hanging := _hanging(id)
	var dx := absf((col + 0.5) * MapGuide.CELL - hanging.z)
	return Vector2(maxf(dx - LOAD_HALF_WIDTH, 0.0), hanging.x).length()

func _release_radius() -> float:
	return (load(RELEASE_STATS) as PulseStats).max_radius

func _peak() -> float:
	return MapGuide.ivo_reach().peak()

func test_the_leaf_curtain_closes_the_only_way_through() -> void:
	assert_float(_top(_cell("leaf_curtain").x)).is_greater(_peak() * 2.0)

func test_the_lift_shelf_is_out_of_reach_from_the_floor_and_the_counterweights() -> void:
	var shelf := _top(_cell("lift").x + 2)
	assert_float(shelf).is_greater(_peak())
	for id: String in ["weight_wrong", "weight_right"]:
		assert_float(shelf - _hanging(id).y).is_greater(_peak())

func test_the_cocoon_shelf_is_out_of_reach_from_the_floor() -> void:
	assert_float(_top(_cell("cocoon").x)).is_greater(_peak())

## Between the counterweights and the cocoon's shelf a stone wall hangs from
## the room's top to below a load's top: standing on a load gets him nowhere.
func test_a_wall_keeps_the_counterweights_from_the_cocoon_shelf() -> void:
	var col := _cell("weight_right").x + 2
	var lowest := -1
	for row: int in _map.size.y:
		if _map.is_solid(_map.origin + Vector2i(col, row)):
			if row != lowest + 1:
				break
			lowest = row
	assert_int(lowest).is_greater_equal(0)
	var bottom := (FLOOR_ROW - lowest - 1) * MapGuide.CELL
	assert_float(bottom).is_less(_hanging("weight_right").y)
	assert_float(bottom).is_greater(56.0)

func test_the_lift_rises_to_its_shelf() -> void:
	var travel: Array = _entity("lift").params.travel
	assert_float(-float(travel[1])).is_greater_equal(_top(_cell("lift").x + 2))

func test_by_one_counterweight_soltar_leaves_the_other() -> void:
	var right := _cell("weight_right").x
	assert_float(_distance_to_load(right, "weight_right")).is_less(_release_radius())
	assert_float(_distance_to_load(right, "weight_wrong")).is_greater(_release_radius())

func test_between_them_it_reaches_both() -> void:
	var middle := (_cell("weight_right").x + _cell("weight_wrong").x) / 2
	assert_float(_distance_to_load(middle, "weight_right")).is_less(_release_radius())
	assert_float(_distance_to_load(middle, "weight_wrong")).is_less(_release_radius())

## Carried out of Soltar's disc, the cocoon is back in the grey, which gives
## it back to its rope - so Soltar must be played where its disc covers the
## cocoon both where it hangs and on the plate.
func test_one_soltar_spot_covers_the_cocoon_from_its_rope_to_the_plate() -> void:
	var hanging := _hanging("cocoon")
	var plate_x := (_cell("plate_gate").x + 0.5) * MapGuide.CELL
	var covered := false
	for col: int in range(_cell("cocoon").x, _cell("plate_gate").x + 1):
		var x := (col + 0.5) * MapGuide.CELL
		var at_rope := Vector2(maxf(absf(x - hanging.z) - LOAD_HALF_WIDTH, 0.0), hanging.y).length()
		var at_plate := Vector2(maxf(absf(x - plate_x) - LOAD_HALF_WIDTH, 0.0), hanging.y).length()
		if maxf(at_rope, at_plate) < _release_radius() - MapGuide.CELL:
			covered = true
	assert_bool(covered).is_true()

## The gale would blow the cocoon on past the plate and off the shelf; a
## stone stop right after the plate holds it there.
func test_a_stop_holds_the_cocoon_on_the_plate() -> void:
	var plate := _cell("plate_gate")
	assert_bool(_map.is_solid(_map.origin + plate + Vector2i(1, 0))).is_true()

func test_the_gale_played_into_the_current_carries_across() -> void:
	var both := func(p: Vector2) -> Vector2: return _gale(p) + Vector2(_current_speed, 0)
	assert_float(_reach(both)).is_greater_equal(_width() + MARGIN)
