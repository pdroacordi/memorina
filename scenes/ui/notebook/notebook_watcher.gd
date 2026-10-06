class_name NotebookWatcher
extends Node
## Announces notebook entries that became present; pausable, and silent during a guardian fight or a lesson (design 02 §4, "pós-combate").

## New unread entry ids, oldest first.
signal announced(ids: Array[StringName])

@export var catalog: NotebookCatalog
## Ivo: where he stands decides whether a fight is on, and he knows whether a lesson is.
@export var subject: Player

## Ids announced or waiting this session, oldest first; the notebook opens on the newest still unread.
var recent: Array[StringName] = []

var _present: Array[StringName] = []
var _waiting: Array[StringName] = []


# Seeds silently: a world rebuilt after a death or a load announces nothing.
func _ready() -> void:
	_present = NotebookIndex.present(catalog, SaveSystem.player_data)
	SaveSystem.progress_changed.connect(_on_progress_changed)

func _process(_delta: float) -> void:
	if _waiting.is_empty() or is_holding():
		return
	var ids: Array[StringName] = []
	for id: StringName in _waiting:
		if not SaveSystem.is_notebook_read(id):
			ids.append(id)
	_waiting.clear()
	if not ids.is_empty():
		announced.emit(ids)

## A fight is on where Ivo stands, or a lesson is in its lead-in or playing; the queue waits for both to end.
## A lesson starts unpaused (the lead-in) and freezes later, so the pause alone would let the quill in.
func is_holding() -> bool:
	return subject != null and (subject.is_in_lesson() or Guardian.fight_at(get_tree(), subject.global_position))

func waiting() -> Array[StringName]:
	return _waiting

func _on_progress_changed() -> void:
	var now := NotebookIndex.present(catalog, SaveSystem.player_data)
	for id: StringName in NotebookIndex.added(_present, now):
		if SaveSystem.is_notebook_read(id):
			continue
		_waiting.append(id)
		recent.append(id)
	for id: StringName in _waiting.duplicate():
		if not now.has(id):
			_waiting.erase(id)
	_present = now
