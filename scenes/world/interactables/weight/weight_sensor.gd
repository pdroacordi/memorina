class_name WeightSensor extends Area2D

## Sums the Weight of everything overlapping it: bodies (Ivo, a released load,
## a crate) and areas (the burned shadow, which is no body at all). Anything
## without a Weight child is ignored - a hurtbox, an enemy, a pulse.
## Emits load_changed whenever the sum moves, so a plate or a seesaw never
## polls.

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

## Everything pressing, with where it presses, for a seesaw weighing torque.
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
