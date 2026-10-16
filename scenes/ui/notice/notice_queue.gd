class_name NoticeQueue
extends RefCounted
## The notices waiting to show, oldest first: each item gained and the latest intent change (systems/notices).

var _waiting: Array[Notice] = []
## The intent last popped, or the one the world was built with: a change back to it tells nothing. The pause menu shows it.
var _told_intent: StringName = &""
## The intent that holds now, as `set_intent` last heard it.
var _current_intent: StringName = &""


func _init(seeded_intent: StringName = &"") -> void:
	_told_intent = seeded_intent
	_current_intent = seeded_intent

## The items `after` owns that `before` did not, in enum order.
static func gained(before: Array[bool], after: Array[bool]) -> Array[int]:
	var found: Array[int] = []
	for item: int in after.size():
		if after[item] and (item >= before.size() or not before[item]):
			found.append(item)
	return found

## Queues `item` once.
func add_item(item: int) -> void:
	for notice: Notice in _waiting:
		if notice.is_item() and notice.item == item:
			return
	_waiting.append(Notice.new(Notice.Kind.ITEM, item))

## The intent is now `id` (empty: none holds). Unchanged, nothing moves, so the queue stays oldest first; changed, a
## waiting intent notice is replaced, so only the newest change is told.
func set_intent(id: StringName) -> void:
	if id == _current_intent:
		return
	_current_intent = id
	_drop_waiting_intent()
	if id != &"" and id != _told_intent:
		_waiting.append(Notice.new(Notice.Kind.INTENT, -1, id))

## Drops the waiting item notices `owned` no longer holds (a rewind took them back).
func keep_owned(owned: Array[bool]) -> void:
	for notice: Notice in _waiting.duplicate():
		if notice.is_item() and (notice.item >= owned.size() or not owned[notice.item]):
			_waiting.erase(notice)

## The oldest notice, removed from the queue; null when none waits.
func pop() -> Notice:
	if _waiting.is_empty():
		return null
	var notice: Notice = _waiting.pop_front()
	if not notice.is_item():
		_told_intent = notice.intent_id
	return notice

## A notice withdrawn mid-show goes back first, to show whole once the way is clear. An intent that no longer holds is
## dropped instead; with no intent waiting, the told intent becomes the current one, so the pause menu never keeps it.
func push_front(notice: Notice) -> void:
	if not notice.is_item() and notice.intent_id != _current_intent:
		if not _waiting.any(func(waiting: Notice) -> bool: return not waiting.is_item()):
			_told_intent = _current_intent
		return
	_waiting.push_front(notice)

## The intent the player was last told, or the seeded one.
func told_intent() -> StringName:
	return _told_intent

func waiting() -> Array[Notice]:
	return _waiting

func is_empty() -> bool:
	return _waiting.is_empty()

func _drop_waiting_intent() -> void:
	for notice: Notice in _waiting.duplicate():
		if not notice.is_item():
			_waiting.erase(notice)
