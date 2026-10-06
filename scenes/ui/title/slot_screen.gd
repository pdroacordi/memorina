class_name SlotScreen
extends Control
## The title's second screen: three slot cards with their confirmations. It shows saves and asks; Title owns the saves and acts.

## A slot was picked to continue (used) or to start in (empty).
signal chosen(slot: int)
signal erase_confirmed(slot: int)
signal overwrite_confirmed(slot: int)

## LOAD continues a used slot; NEW starts a game in an empty slot or overwrites a used one after asking.
enum Purpose { LOAD, NEW }

var _purpose: Purpose = Purpose.LOAD
var _cards: Array[SlotCard] = []
## The slot a confirmation asks about, from 1; 0 when none is open.
var _asking: int = 0

@onready var _list: Control = %List
@onready var _confirm_erase: ConfirmPanel = %ConfirmErase
@onready var _confirm_overwrite: ConfirmPanel = %ConfirmOverwrite


func _ready() -> void:
	for card: SlotCard in _list.get_children():
		_cards.append(card)
	assert(_cards.size() == SaveSlots.COUNT, "One card per slot")
	for i: int in _cards.size():
		_cards[i].picked.connect(_on_picked.bind(i + 1))
		_cards[i].erase_pressed.connect(_ask.bind(_confirm_erase, i + 1))
	_confirm_erase.confirmed.connect(_answer.bind(erase_confirmed))
	_confirm_overwrite.confirmed.connect(_answer.bind(overwrite_confirmed))
	for confirm: ConfirmPanel in [_confirm_erase, _confirm_overwrite]:
		confirm.cancelled.connect(step_back)

## Continuing focuses the latest save; a new game over full slots focuses the oldest (user decision 2026-10-06).
func open(purpose: Purpose, saves: Array[PlayerData]) -> void:
	_purpose = purpose
	show()
	var focus := SaveSlots.latest(saves) if purpose == Purpose.LOAD else SaveSlots.oldest(saves)
	show_saves(saves, focus)

func close() -> void:
	_close_confirmation()
	hide()

## Fills the cards in slot order (null is empty) and focuses `focus_slot`'s card, or the first pickable one.
func show_saves(saves: Array[PlayerData], focus_slot: int) -> void:
	_close_confirmation()
	for i: int in _cards.size():
		_cards[i].show_save(saves[i])
		_cards[i].set_selectable(saves[i] != null or _purpose == Purpose.NEW)
	if focus_slot > 0 and _cards[focus_slot - 1].is_selectable():
		_cards[focus_slot - 1].focus_card()
		return
	for card: SlotCard in _cards:
		if card.is_selectable():
			card.focus_card()
			return

## Closes an open confirmation, focusing what asked; false when none was open.
func step_back() -> bool:
	if not is_confirming():
		return false
	var slot := _asking
	var was_erase := _confirm_erase.visible
	_close_confirmation()
	if was_erase:
		_cards[slot - 1].focus_erase()
	else:
		_cards[slot - 1].focus_card()
	return true

func is_confirming() -> bool:
	return _confirm_erase.visible or _confirm_overwrite.visible

func purpose() -> Purpose:
	return _purpose

func _on_picked(slot: int) -> void:
	if _purpose == Purpose.NEW and _cards[slot - 1].is_used():
		_ask(_confirm_overwrite, slot)
	else:
		chosen.emit(slot)

func _ask(confirm: ConfirmPanel, slot: int) -> void:
	_asking = slot
	_list.hide()
	confirm.open()

func _answer(answered: Signal) -> void:
	answered.emit(_asking)

func _close_confirmation() -> void:
	_asking = 0
	_confirm_erase.close()
	_confirm_overwrite.close()
	_list.show()
