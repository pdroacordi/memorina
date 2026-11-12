class_name FactWell
extends Node
## The only writer of its source's strength: the first FactLevel that holds under the save, never recorded
## (architecture/story-05-playable-flashbacks).

@export var source: MemorySource
## In priority order: the first that holds sets the strength.
@export var levels: Array[FactLevel] = []
## Scaled seconds a save change takes to reach the new strength; 0 cuts.
@export var fade_seconds: float = 3.0

var _tween: Tween


## The index of the first level that holds under `data`; -1 when none does.
static func pick(from: Array[FactLevel], data: PlayerData) -> int:
	for i: int in from.size():
		if from[i] != null and from[i].holds(data):
			return i
	return -1

## The strength the levels give under `data`; 0 when none holds.
static func strength_for(from: Array[FactLevel], data: PlayerData) -> float:
	var index := pick(from, data)
	return 0.0 if index < 0 else from[index].strength

func _ready() -> void:
	assert(source != null, "%s has no source" % name)
	SaveSystem.progress_changed.connect(_on_progress_changed)
	_snap(strength_for(levels, SaveSystem.player_data))

## The strength the save asks for now.
func target() -> float:
	return strength_for(levels, SaveSystem.player_data)

func _on_progress_changed() -> void:
	var goal := target()
	if _tween != null:
		_tween.kill()
		_tween = null
	if is_equal_approx(goal, source.strength) and source.visible == not is_zero_approx(goal):
		return
	if fade_seconds <= 0.0:
		_snap(goal)
		return
	source.visible = true
	_tween = create_tween()
	_tween.tween_property(source, "strength", goal, fade_seconds)
	_tween.tween_callback(_snap.bind(goal))

func _snap(value: float) -> void:
	source.strength = value
	source.visible = not is_zero_approx(value)
