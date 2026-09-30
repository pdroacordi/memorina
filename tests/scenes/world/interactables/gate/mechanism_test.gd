class_name MechanismTest extends GdUnitTestSuite

## A mechanism follows its trigger, and its lock holds it down whatever the
## trigger says - the counterweight dropped on the wrong plate.

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

## Runs the gate past its whole move.
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
