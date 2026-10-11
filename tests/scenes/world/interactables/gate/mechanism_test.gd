class_name MechanismTest extends GdUnitTestSuite

## Verifies trigger movement and lock precedence.

const PLATE := preload("res://scenes/world/interactables/pressure_plate/pressure_plate.tscn")
const GATE := preload("res://scenes/world/interactables/gate/gate.tscn")

var _plate: PressurePlate
var _jam: PressurePlate
var _gate: Mechanism

func before_test() -> void:
	var holder := Node2D.new()
	add_child(holder)
	auto_free(holder)
	_plate = PLATE.instantiate() as PressurePlate
	_plate.name = "plate"
	_jam = PLATE.instantiate() as PressurePlate
	_jam.name = "jam"
	_gate = GATE.instantiate() as Mechanism
	_gate.trigger_path = ^"../plate"
	_gate.lock_path = ^"../jam"
	holder.add_child(_plate)
	holder.add_child(_jam)
	holder.add_child(_gate)

## Advances the gate beyond its configured move duration.
func _settle() -> void:
	_gate._physics_process(_gate.move_time + 0.1)

func test_it_follows_its_trigger() -> void:
	_plate.activated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_true()
	_plate.deactivated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_false()

func test_a_lock_holds_it_down_whatever_its_trigger() -> void:
	_jam.activated.emit()
	_plate.activated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_false()

func test_it_moves_once_the_lock_lets_go() -> void:
	_jam.activated.emit()
	_plate.activated.emit()
	_settle()
	_jam.deactivated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_true()

func _with_second() -> PressurePlate:
	var second := PLATE.instantiate() as PressurePlate
	second.name = "second"
	_gate.get_parent().add_child(second)
	var gate := GATE.instantiate() as Mechanism
	gate.trigger_path = ^"../plate"
	gate.second_trigger_path = ^"../second"
	_gate.get_parent().add_child(gate)
	_gate = gate
	return second

func test_with_a_second_trigger_one_alone_does_not_move_it() -> void:
	var second := _with_second()
	_plate.activated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_false()
	_plate.deactivated.emit()
	second.activated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_false()

func test_with_a_second_trigger_both_move_it() -> void:
	var second := _with_second()
	_plate.activated.emit()
	second.activated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_true()
	second.deactivated.emit()
	_settle()
	assert_bool(_gate.is_moved()).is_false()

func test_a_gate_is_no_floor_for_the_reach_audit() -> void:
	assert_array(auto_free(GATE.instantiate()).reach_cells(RoomMap.new(), Vector2(16, 32))).is_empty()

func test_a_lift_is_a_floor_all_along_its_travel() -> void:
	var lift := auto_free((load("res://scenes/world/interactables/lift/lift.tscn") as PackedScene).instantiate()) as Mechanism
	var cells := lift.reach_cells(RoomMap.new(), RoomMapNode.entity_position(Vector2i(0, 1), RoomLegendEntry.Anchor.FEET))
	assert_array(cells).contains([Vector2i(0, 2), Vector2i(0, -2)])
	assert_int(cells.size()).is_equal(15)

# The audit reads a placed scene: the live position, which _ready and travel move, never counts.
func test_a_lifts_reach_ignores_where_it_has_moved() -> void:
	var lift := auto_free((load("res://scenes/world/interactables/lift/lift.tscn") as PackedScene).instantiate()) as Mechanism
	var at := RoomMapNode.entity_position(Vector2i(0, 1), RoomLegendEntry.Anchor.FEET)
	var before := lift.reach_cells(RoomMap.new(), at)
	lift.position = Vector2(500, -500)
	assert_array(lift.reach_cells(RoomMap.new(), at)).is_equal(before)
