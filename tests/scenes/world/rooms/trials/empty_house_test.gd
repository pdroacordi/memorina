class_name EmptyHouseTest extends GdUnitTestSuite

## Combinado 4 is closed without Solstice and open with it, read from the real map, pulses, gate, region memory and Ivo's speeds.

const ROOM := "res://scenes/world/rooms/trials_solstice/contents/empty_house.room"
const SHADOW_STATS := "res://resources/memory/shadow_pulse_stats.tres"
const RELEASE_STATS := "res://resources/memory/release_pulse_stats.tres"
const AURA := "res://scenes/world/memory/song_effects/solstice/solstice_aura.tscn"
const LOCOMOTION := "res://resources/characters/ivo/ivo_locomotion_stats.tres"
const ROLL := "res://resources/characters/ivo/ivo_roll_stats.tres"
const REGION := "res://scenes/world/rooms/trials_solstice.tscn"
const GATE := "res://scenes/world/interactables/gate/gate.tscn"
const CELL := 32.0
## Fraction of gate rise that must remain open for Ivo to pass (see summer trial).
const PASSABLE := 0.6
## Seconds to draw the Memorina and play six notes at an unhurried pace.
const PLAY_TIME := 3.0

var _map: RoomMap

func before() -> void:
	var result := RoomMapParser.parse(FileAccess.get_file_as_string(ROOM), RoomLegend.load_default(), ROOM)
	assert(result.ok(), str(result.errors))
	_map = result.map

func _col(id: String) -> int:
	for placed: Dictionary in _map.entities:
		if placed.params.get("id", "") == id:
			return (placed.cell as Vector2i).x - _map.origin.x
	return -1

func _run_speed() -> float:
	return (load(LOCOMOTION) as LocomotionStats).move_speed

## Upper bound of a roll chain's speed, px/s: each roll, then running through its recovery and cooldown.
func _roll_speed() -> float:
	var roll := load(ROLL) as RollStats
	var after := roll.roll_recovery_time + roll.roll_cooldown
	return (roll.roll_distance + _run_speed() * after) / (roll.roll_time + after)

## Seconds to cover the cells from column `from` to just past column `to` at `speed` px/s.
func _travel(from: int, to: int, speed: float) -> float:
	return (absi(to - from) + 1) * CELL / speed

func _walk(from: int, to: int) -> float:
	return _travel(from, to, _run_speed())

## The trials' memory, which sets how fast a pulse played there contracts.
func _region_memory() -> float:
	var region := auto_free((load(REGION) as PackedScene).instantiate()) as Node
	return (region.get_node("Memory") as RegionMemory).authored

## Seconds a pulse with `path` stats lives, plus the gate's remaining fall once it lets go.
func _holds_for(path: String, stretched: bool) -> float:
	var timeline := PulseTimeline.new(load(path) as PulseStats, _region_memory())
	if stretched:
		var aura := auto_free((load(AURA) as PackedScene).instantiate()) as SolsticeAura
		timeline.advance(0.1)
		timeline.stretch(aura.reach, aura.duration)
	var gate := auto_free((load(GATE) as PackedScene).instantiate()) as Mechanism
	return timeline.total_time() + gate.move_time * (1.0 - PASSABLE)

func test_the_door_needs_both_plates() -> void:
	var door: Dictionary
	for placed: Dictionary in _map.entities:
		if placed.params.get("id", "") == "house_door":
			door = placed.params
	assert_str(str(door.get("trigger_path"))).is_equal("plate_shadow")
	assert_str(str(door.get("second_trigger_path"))).is_equal("plate_load")

func test_the_door_cannot_be_jumped() -> void:
	var door := _col("house_door")
	for row: int in range(0, 13):
		assert_bool(_map.is_solid(_map.origin + Vector2i(door, row))).is_true()

func test_the_load_hangs_over_its_plate() -> void:
	assert_int(_col("house_load")).is_equal(_col("plate_load"))

## In any order, the shadow alone ends before Ivo gets from its plate to the door, even rolling.
func test_alone_the_shadow_is_gone_before_he_reaches_the_door() -> void:
	var rolled := _travel(_col("plate_shadow"), _col("house_door"), _roll_speed())
	assert_float(_holds_for(SHADOW_STATS, false) + 0.5).is_less(rolled)

## Solstice and Sombra on the far plate, then Soltar at the load on the way out.
func test_under_solstice_the_shadow_lasts_the_route() -> void:
	var route := _walk(_col("plate_shadow"), _col("house_door")) + PLAY_TIME
	assert_float(_holds_for(SHADOW_STATS, true)).is_greater(route + 0.5)

func test_the_released_load_lasts_the_walk_to_the_door() -> void:
	assert_float(_holds_for(RELEASE_STATS, false)).is_greater(_walk(_col("plate_load"), _col("house_door")) + 1.0)
