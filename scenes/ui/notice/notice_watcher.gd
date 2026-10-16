class_name NoticeWatcher
extends Node
## Tells each item Ivo gains and each change of his intent, one notice at a time, derived from the save; pausable,
## and silent during a talk, a cutscene, a lesson or a guardian fight (systems/notices).

## A notice is due: the text key it shows and its icon (null for an intent).
signal shown(text_key: String, icon: Texture2D)
## A hold began while the notice was sliding in or holding: the view hides it at once.
signal withdrawn

## Item names and icons: the Items section's entries.
@export var notebook: NotebookCatalog
@export var intents: IntentCatalog
## Ivo: whether a talk, a scene, a lesson or a fight holds the notices (`NoticeHold`).
@export var subject: Player

var _queue: NoticeQueue
var _owned: Array[bool] = []
## The notice sliding in or holding; null once it starts to leave, when it counts as told.
var _showing: Notice
## The view is busy with a notice, from `shown` to its `finished`.
var _view_busy: bool = false


# Seeds silently: a world rebuilt after a death or a load tells nothing.
func _ready() -> void:
	_owned = SaveSystem.player_data.owned_items.duplicate()
	_queue = NoticeQueue.new(_intent_id(SaveSystem.player_data))
	SaveSystem.progress_changed.connect(_on_progress_changed)

func _process(_delta: float) -> void:
	if is_holding():
		if _showing != null:
			_queue.push_front(_showing)
			_showing = null
			_view_busy = false
			withdrawn.emit()
		return
	if _view_busy:
		return
	_showing = _queue.pop()
	if _showing != null:
		_view_busy = true
		shown.emit(text_key(_showing), icon(_showing))

## The view began to slide the notice out: it is told, and a hold from now on leaves it be.
func on_notice_leaving() -> void:
	_showing = null

## The view finished the notice it was shown; the next may follow.
func on_notice_finished() -> void:
	_showing = null
	_view_busy = false

func is_holding() -> bool:
	return NoticeHold.applies(subject)

## The text key of the intent last told (a notice showed it, or the world was built with it); empty for none. The
## pause menu shows it, so it never names an intent before its notice has.
func intent_key() -> String:
	return _key_of(_queue.told_intent())

func waiting() -> Array[Notice]:
	return _queue.waiting()

## A notice is sliding in or holding.
func is_showing() -> bool:
	return _showing != null

func text_key(notice: Notice) -> String:
	if notice.is_item():
		var entry := notebook.item_entry(notice.item)
		return entry.title_key if entry != null else ""
	return _key_of(notice.intent_id)

func icon(notice: Notice) -> Texture2D:
	if not notice.is_item():
		return null
	var entry := notebook.item_entry(notice.item)
	return entry.icon if entry != null else null

func _key_of(intent_id: StringName) -> String:
	if intent_id == &"" or intents == null:
		return ""
	for intent: Intent in intents.intents:
		if intent.id == intent_id:
			return intent.text_key
	return ""

func _intent_id(data: PlayerData) -> StringName:
	var intent := intents.current(data) if intents != null else null
	return intent.id if intent != null else &""

func _on_progress_changed() -> void:
	var data := SaveSystem.player_data
	for item: int in NoticeQueue.gained(_owned, data.owned_items):
		_queue.add_item(item)
	_queue.keep_owned(data.owned_items)
	_owned = data.owned_items.duplicate()
	_queue.set_intent(_intent_id(data))
