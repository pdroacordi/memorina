class_name SummerTrialTest extends GdUnitTestSuite

## Sombra's puzzles are only puzzles if Ivo alone cannot do them. Read from the
## real map, the real seesaw and the real stats, so retuning any of them
## re-checks the room.

const ROOM := "res://scenes/world/rooms/trials_summer/contents/summer_trial.room"
const SEESAW_SCENE := "res://scenes/world/interactables/seesaw/seesaw.tscn"
const GATE_SCENE := "res://scenes/world/interactables/gate/gate.tscn"
const LOCOMOTION := "res://resources/characters/ivo/ivo_locomotion_stats.tres"
const CELL := 32.0
const FLOOR_ROW := 16
## The seesaw's pivot above what it stands on (seesaw.tscn's Plank).
const PIVOT_HEIGHT := 24.0
## A landing must clear the ledge by this much, not scrape it.
const MARGIN := 8.0
## How much of the gate's travel has to be open for Ivo to pass under it
## (his body is about 56 px tall; the gate rises 96).
const PASSABLE := 0.6

var _map: RoomMap
var _params := {}

func before() -> void:
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM)
	assert(result.ok(), str(result.errors))
	_map = result.map
	for placed: Dictionary in _map.entities:
		_params[placed.params.get("id", placed.symbol)] = placed

## The entity's grid column and row (an entity's cell is a world cell).
func _cell(id: String) -> Vector2i:
	return (_params[id].cell as Vector2i) - _map.origin

## Height of the top of the first solid cell in `col`, px above the floor.
func _top(col: int) -> float:
	for row: int in _map.size.y:
		if _map.is_solid(_map.origin + Vector2i(col, row)):
			return (FLOOR_ROW - row) * CELL
	return 0.0

func _seesaw() -> Seesaw:
	var seesaw := (load(SEESAW_SCENE) as PackedScene).instantiate() as Seesaw
	var params: Dictionary = _params["seesaw"].params
	EntityParams.apply(seesaw, params)
	return auto_free(seesaw)

## The seesaw's pivot above the floor: what it stands on plus its own height.
func _pivot() -> float:
	return (FLOOR_ROW - 1 - _cell("seesaw").y) * CELL + PIVOT_HEIGHT

func _peak() -> float:
	return MapGuide.ivo_reach().peak()

func _cliff_col() -> int:
	return _cell("seesaw").x + 5

func _cliff() -> float:
	return _top(_cliff_col())

## Where he stands at the short arm's end with `loads` on the plank: its
## height above the floor and its gap to the cliff's face.
func _short_end(seesaw: Seesaw, loads: Array[Vector2]) -> Vector2:
	var angle := SeesawBalance.settle_angle(loads, seesaw.degrees_per_torque, seesaw.max_degrees)
	var pivot_x := (_cell("seesaw").x + 0.5) * CELL
	var gap := _cliff_col() * CELL - (pivot_x + seesaw.end_reach(angle).y)
	return Vector2(_pivot() + seesaw.end_rise(angle).y, gap)

func _short_arm(seesaw: Seesaw) -> float:
	return (1.0 - seesaw.pivot_at) * seesaw.length

func _long_arm(seesaw: Seesaw) -> float:
	return seesaw.pivot_at * seesaw.length

func test_the_plate_is_too_far_from_the_door_to_run() -> void:
	var run := (load(LOCOMOTION) as LocomotionStats).move_speed
	var gate := auto_free((load(GATE_SCENE) as PackedScene).instantiate()) as Mechanism
	var distance := (_cell("door").x - _cell("plate_door").x - 1) * CELL
	# Stepping off the plate starts the gate down; it is shut to him once less
	# than PASSABLE of it is open.
	var shut_after := gate.move_time * (1.0 - PASSABLE)
	assert_float(distance / run).is_greater(shut_after)

func test_the_door_wall_cannot_be_jumped() -> void:
	assert_float(_top(_cell("door").x)).is_greater(_peak() + MARGIN)

func test_the_cliff_is_out_of_reach_from_the_floor_the_pedestal_and_a_level_plank() -> void:
	assert_float(_cliff()).is_greater(_peak())
	assert_float(_cliff() - _top(_cell("seesaw").x)).is_greater(_peak())
	assert_float(_cliff() - _pivot()).is_greater(_peak())

func test_alone_on_the_short_arm_it_sinks_under_him() -> void:
	var seesaw := _seesaw()
	var loads: Array[Vector2] = [Vector2(_short_arm(seesaw), 1.0)]
	assert_float(_cliff() - _short_end(seesaw, loads).x).is_greater(_peak())

func test_the_shadow_on_the_long_arm_holds_him_up_to_the_cliff() -> void:
	var seesaw := _seesaw()
	var loads: Array[Vector2] = [Vector2(-_long_arm(seesaw), 1.0), Vector2(_short_arm(seesaw), 1.0)]
	var standing := _short_end(seesaw, loads)
	var rise := _cliff() - standing.x
	assert_float(_peak()).is_greater_equal(rise + MARGIN)
	assert_float(MapGuide.ivo_reach().reach_at(rise)).is_greater_equal(standing.y + MARGIN)

func test_the_long_arm_comes_down_to_the_floor() -> void:
	var seesaw := _seesaw()
	var angle := deg_to_rad(-seesaw.max_degrees)
	assert_float(_pivot() + seesaw.end_rise(angle).x).is_less_equal(4.0)

func test_the_tunnel_roof_can_be_climbed() -> void:
	var roof := _top(_cell("lure_brute").x)
	assert_float(_peak()).is_greater_equal(roof + MARGIN)

# --- The lure --------------------------------------------------------------

const BRUTE_SCENE := "res://scenes/characters/enemies/brute_shadow/brute_shadow.tscn"
## Where the room's comment says to cast the shadow.
const LURE_COL := 45

func _radius(node_path: String) -> float:
	var brute := auto_free((load(BRUTE_SCENE) as PackedScene).instantiate()) as Node
	return ((brute.get_node(node_path) as CollisionShape2D).shape as CircleShape2D).radius

func _brute_x() -> float:
	return (_cell("lure_brute").x + 0.5) * CELL

func test_the_shadow_is_cast_where_the_brute_sees_it_but_does_not_wake() -> void:
	var distance := absf(_brute_x() - (LURE_COL + 0.5) * CELL)
	assert_float(distance).is_less(_radius("EnemySight/CollisionShape2D"))
	assert_float(distance).is_greater(_radius("SpawnTrigger/CollisionShape2D"))

func test_nothing_stands_between_the_brute_and_the_shadow() -> void:
	# The sight ray runs at chest height, inside the bottom floor-level row.
	for col: int in range(LURE_COL, _cell("lure_brute").x + 1):
		assert_bool(_map.is_solid(_map.origin + Vector2i(col, FLOOR_ROW - 1))).is_false()

func test_on_the_roof_he_wakes_it_and_the_roof_hides_him() -> void:
	var roof := _top(_cell("lure_brute").x)
	# Standing on the roof right above it: within its wake-up radius...
	assert_float(roof).is_less(_radius("SpawnTrigger/CollisionShape2D"))
	# ...and the roof itself is between them.
	assert_bool(_map.is_solid(_map.origin + Vector2i(_cell("lure_brute").x, FLOOR_ROW - int(roof / CELL)))).is_true()

func test_a_shaft_behind_it_drops_into_the_chamber() -> void:
	var shaft := _cell("lure_brute").x + 3
	for row: int in range(0, FLOOR_ROW):
		assert_bool(_map.is_solid(_map.origin + Vector2i(shaft, row))).is_false()
