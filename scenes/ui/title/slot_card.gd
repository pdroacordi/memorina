class_name SlotCard
extends Control
## One save slot: a card that picks it and, when the slot is used, an Erase entry beside it.

signal picked
signal erase_pressed

const TEXT_VARIATION := &"SlotText"
const DISABLED_TEXT_VARIATION := &"SlotTextDisabled"

var _used: bool = false

@onready var _card: Button = %Card
@onready var _erase: Button = %Erase
@onready var _region: Label = %Region
@onready var _bench: Label = %Bench
@onready var _time: Label = %Time
@onready var _empty: Label = %Empty


func _ready() -> void:
	_erase.text = tr("TITLE_ERASE")
	_empty.text = tr("TITLE_EMPTY_SLOT")
	_card.pressed.connect(picked.emit)
	_erase.pressed.connect(erase_pressed.emit)

## Shows the slot's save; null shows an empty slot.
func show_save(data: PlayerData) -> void:
	_used = data != null
	_empty.visible = not _used
	for detail: Control in [_region, _bench, _time, _erase]:
		detail.visible = _used
	if not _used:
		return
	_region.text = tr(data.region_name_key) if not data.region_name_key.is_empty() else ""
	_bench.text = tr(SaveSlots.bench_name_key(data.bench_id)) if data.bench_id != &"" else ""
	var parts := SaveSlots.play_time_parts(data.play_time)
	_time.text = tr("TITLE_PLAY_TIME") % [parts.x, parts.y]

## A card that cannot be picked is greyed and skipped by focus.
func set_selectable(selectable: bool) -> void:
	_card.disabled = not selectable
	_card.focus_mode = Control.FOCUS_ALL if selectable else Control.FOCUS_NONE
	_empty.theme_type_variation = TEXT_VARIATION if selectable else DISABLED_TEXT_VARIATION

func is_used() -> bool:
	return _used

func is_selectable() -> bool:
	return not _card.disabled

func focus_card() -> void:
	_card.grab_focus()

func focus_erase() -> void:
	_erase.grab_focus()
