class_name FactBackdrop
extends Node
## The only writer of its Backdrop's set: the first FactBackdropSet that holds under the save, never recorded
## (architecture/story-05-playable-flashbacks, "Time of day"). The scene's authored set is the one shown when none holds.

@export var backdrop: Backdrop
## In priority order: the first that holds is shown.
@export var sets: Array[FactBackdropSet] = []

## The Backdrop's authored set, shown when no entry holds.
var _rest: BackdropSet


## The index of the first entry that holds under `data`; -1 when none does.
static func pick(from: Array[FactBackdropSet], data: PlayerData) -> int:
	for i: int in from.size():
		if from[i] != null and from[i].holds(data):
			return i
	return -1

## The set the entries give under `data`, else `rest`.
static func set_for(from: Array[FactBackdropSet], data: PlayerData, rest: BackdropSet) -> BackdropSet:
	var index := pick(from, data)
	return rest if index < 0 else from[index].backdrop_set

func _ready() -> void:
	assert(backdrop != null, "%s has no backdrop" % name)
	_rest = backdrop.backdrop_set
	SaveSystem.progress_changed.connect(_apply)
	_apply()

func _apply() -> void:
	var chosen := set_for(sets, SaveSystem.player_data, _rest)
	if backdrop.backdrop_set != chosen:
		backdrop.backdrop_set = chosen
