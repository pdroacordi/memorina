class_name Airflow extends Node

## Combines registered air sources, scales velocity by memory, and applies shelters (docs/design/03_mundo.md sections 5.1, 5.3, and 6.1).

const GROUP := &"airflow"

var _sources: Array[AirflowSource] = []
var _shelters: Array[AirflowShelter] = []
var _memory: MemoryField

static func find_in(node: Node) -> Airflow:
	return node.get_tree().get_first_node_in_group(GROUP) as Airflow

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	_memory = MemoryField.find_in(self)

func register(source: AirflowSource) -> void:
	if not _sources.has(source):
		_sources.append(source)

func unregister(source: AirflowSource) -> void:
	_sources.erase(source)

func register_shelter(shelter: AirflowShelter) -> void:
	if not _shelters.has(shelter):
		_shelters.append(shelter)

func unregister_shelter(shelter: AirflowShelter) -> void:
	_shelters.erase(shelter)

## Whether a shelter covers `global_point`; wind and rain use this same check so shelter begins when the shell closes.
func is_sheltered(global_point: Vector2) -> bool:
	for shelter: AirflowShelter in _shelters:
		if shelter.is_visible_in_tree() and shelter.covers(global_point):
			return true
	return false

## Air velocity at `global_point`, in px/s; hidden sources in inactive rooms do not contribute.
func sample(global_point: Vector2) -> Vector2:
	if is_sheltered(global_point):
		return Vector2.ZERO
	var wind := Vector2.ZERO
	for source: AirflowSource in _sources:
		if source.is_visible_in_tree():
			wind += source.wind_at(global_point)
	if wind.is_zero_approx() or _memory == null:
		return wind
	return wind * _memory.sample(global_point)
