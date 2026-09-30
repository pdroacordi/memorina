class_name Airflow extends Node

## The one channel every moving air in the world goes through - weather, a
## current, a natural gust, a song's gale (design 03 sections 5.3 and 6.1:
## "o mesmo canal fisico"). Sources register; anything that wants to know how
## the air moves at a point asks sample(). Because the channel is shared, a
## gale played into a natural current simply adds to it, with no rule for the
## pair (design: "tocar Vendaval numa corrente existente soma-se a ela").
##
## The answer is a VELOCITY (px/s), scaled by the memory at the point: moving
## air in the grey is air that has stopped (design 03 section 5.1), and inside
## a pulse it blows again. A shelter (the bell jar's shell) stills the air
## inside it whatever blows outside.
##
## Mirrors MemoryField's CPU side: it never learns what reads it.

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

## Whether a shelter covers `global_point`: no air moves there, and no weather
## reaches it - the rain asks this too, so the wind and the rain agree on
## when a Redoma's shell starts to shelter (when it closes).
func is_sheltered(global_point: Vector2) -> bool:
	for shelter: AirflowShelter in _shelters:
		if shelter.is_visible_in_tree() and shelter.covers(global_point):
			return true
	return false

## How the air moves at `global_point`, in px/s. Sources hidden with an
## inactive room do not blow.
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
