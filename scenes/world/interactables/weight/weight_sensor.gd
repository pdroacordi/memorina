class_name WeightSensor extends Area2D

## Sums overlapping nodes with a Weight child, including bodies and areas, and signals when the total changes.

signal load_changed(total: float)

var _pressing: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)

func total() -> float:
	var sum := 0.0
	for node: Node2D in _pressing:
		sum += Weight.of(node).mass
	return sum

## Overlapping weighted nodes and their positions, used by seesaws to calculate torque.
func pressing() -> Array[Node2D]:
	return _pressing.duplicate()

func _on_entered(node: Node2D) -> void:
	if Weight.of(node) == null or _pressing.has(node):
		return
	_pressing.append(node)
	load_changed.emit(total())

func _on_exited(node: Node2D) -> void:
	if _pressing.has(node):
		_pressing.erase(node)
		load_changed.emit(total())
