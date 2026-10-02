class_name SolsticeTrialTest extends GdUnitTestSuite

## Checks the real trial map against shadow pulse, Solstice stretch, and Ivo's speed.

const ROOM := "res://scenes/world/rooms/trials_solstice/contents/solstice_trial.room"
const SHADOW_STATS := "res://resources/memory/shadow_pulse_stats.tres"
const AURA := "res://scenes/world/memory/song_effects/solstice/solstice_aura.tscn"
const LOCOMOTION := "res://resources/characters/ivo/ivo_locomotion_stats.tres"
const GATE := "res://scenes/world/interactables/gate/gate.tscn"
const CELL := 32.0
## Fraction of gate rise that must remain open for Ivo to pass (see summer trial).
const PASSABLE := 0.6

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

func _walk_time() -> float:
	var run := (load(LOCOMOTION) as LocomotionStats).move_speed
	return (_col("far_door") - _col("plate_far")) * CELL / run

## Time the shadow holds the plate, including the gate's remaining fall.
func _holds_for(stretched: bool) -> float:
	var timeline := PulseTimeline.new(load(SHADOW_STATS) as PulseStats, 1.0)
	if stretched:
		var aura := auto_free((load(AURA) as PackedScene).instantiate()) as SolsticeAura
		timeline.advance(0.1)
		timeline.stretch(aura.reach, aura.duration)
	var gate := auto_free((load(GATE) as PackedScene).instantiate()) as Mechanism
	return timeline.total_time() + gate.move_time * (1.0 - PASSABLE)

func test_alone_the_shadow_is_gone_before_he_reaches_the_door() -> void:
	assert_float(_holds_for(false)).is_less(_walk_time())

func test_under_solstice_it_lasts_the_corridor() -> void:
	assert_float(_holds_for(true)).is_greater(_walk_time() + 1.0)
