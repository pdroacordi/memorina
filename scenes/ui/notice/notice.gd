class_name Notice
extends RefCounted
## One notice waiting to show: an item gained, or the intent it changed to (systems/notices).

enum Kind { ITEM, INTENT }

var kind: Kind
## An Enums.PlayerItem; -1 for an intent.
var item: int = -1
## An `Intent.id`; empty for an item.
var intent_id: StringName = &""


func _init(notice_kind: Kind, notice_item: int = -1, notice_intent: StringName = &"") -> void:
	kind = notice_kind
	item = notice_item
	intent_id = notice_intent

func is_item() -> bool:
	return kind == Kind.ITEM
