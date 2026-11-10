class_name SeedShopPanel
extends Control
## The seller's trade: the seeds held, one row per offer on sale and a Leave row. A view that never reads the save; the
## seed shop beat tells it what to show (systems/seeds-and-the-seller).

## A row the player can afford was pressed.
signal chosen(offer_id: StringName)
## The Leave row was pressed.
signal left

## Pack px of one row.
const ROW_HEIGHT := 12.0
## Pack px of the price and its seed icon at a row's right end.
const PRICE_WIDTH := 20.0
## A disabled row's ink: the theme's InkButton has no disabled colour of its own.
const DISABLED_INK := Color(0.32, 0.2, 0.25, 0.4)

## Shown beside the count and each price.
@export var seed_icon: Texture2D

## The offer id of each row, in row order.
var _row_ids: Array[StringName] = []
## What the panel shows, so a language change can show it again.
var _offers: Array[SeedOffer] = []
var _held_count: int = 0
var _said_keys: PackedStringArray = PackedStringArray()

@onready var _held: Label = %Held
@onready var _icon: TextureRect = %Icon
@onready var _rows: VBoxContainer = %Rows
@onready var _leave: Button = %Leave
@onready var _said: Label = %Said


func _ready() -> void:
	_icon.texture = seed_icon
	_leave.pressed.connect(left.emit)
	hide()

# Closing the pause or the notebook releases GUI focus; the panel takes it back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED and visible:
		_focus_first()
	elif what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and visible:
		_retranslate()

## Opens on `offers` with `held` seeds, the said line empty and the first row the player can afford focused.
func open(offers: Array[SeedOffer], held: int) -> void:
	show()
	_said.text = ""
	_said_keys = PackedStringArray()
	show_offers(offers, held)
	_focus_first()

## Rebuilds the rows for `offers` and `held`, keeping focus near the row it was on; the said line stays.
func show_offers(offers: Array[SeedOffer], held: int) -> void:
	var focused := _focused_index()
	_offers = offers
	_held_count = held
	_held.text = tr("SHOP_SEEDS_HELD") % held
	for row: Node in _rows.get_children():
		if row != _leave:
			_rows.remove_child(row)
			row.queue_free()
	_row_ids.clear()
	for offer: SeedOffer in offers:
		var row := _make_row(offer, held >= offer.price)
		_rows.add_child(row)
		_rows.move_child(row, _row_ids.size())
		_row_ids.append(offer.id)
	_link_rows()
	if visible and focused >= 0:
		_focus_near(focused)

## Shows `text_key` under the rows; a text with a `%s` takes tr(`arg_key`).
func say(text_key: String, arg_key: String = "") -> void:
	_said_keys = PackedStringArray([text_key, arg_key])
	var text := tr(text_key)
	_said.text = text % tr(arg_key) if text.contains("%s") else text

func close() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	# A hidden focused Button would still take the next ui_accept.
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()
	hide()

## The row for `offer_id`; null when it is not on sale.
func row(offer_id: StringName) -> Button:
	var index := _row_ids.find(offer_id)
	return _rows.get_child(index) as Button if index >= 0 else null

func leave_button() -> Button:
	return _leave

func held_label() -> Label:
	return _held

func said_label() -> Label:
	return _said

## The row texts' widest room in pack px: the row less its margins and the price (seed_shop_text_fit_test).
func text_room() -> float:
	return _rows.size.x - PRICE_WIDTH - 8.0

## The text a row shows for `offer`.
func row_text(offer: SeedOffer) -> String:
	match offer.kind:
		SeedOffer.Kind.MAP:
			return tr("SHOP_MAP") % tr(offer.region_key)
		SeedOffer.Kind.RUMOUR:
			return tr("SHOP_RUMOUR")
	return tr("SHOP_REPLANT")

func _make_row(offer: SeedOffer, affordable: bool) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"InkButton"
	button.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = row_text(offer)
	button.disabled = not affordable
	button.focus_mode = Control.FOCUS_ALL if affordable else Control.FOCUS_NONE
	button.add_theme_color_override(&"font_disabled_color", DISABLED_INK)
	var price := Label.new()
	price.text = str(offer.price)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	price.offset_left = -PRICE_WIDTH
	price.offset_right = -9.0
	if not affordable:
		price.add_theme_color_override(&"font_color", DISABLED_INK)
	button.add_child(price)
	var icon := TextureRect.new()
	icon.texture = seed_icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	icon.offset_left = -8.0
	icon.offset_right = 0.0
	icon.offset_top = -4.0
	icon.offset_bottom = 4.0
	if not affordable:
		icon.modulate = DISABLED_INK.lerp(Color.WHITE, 0.6)
	button.add_child(icon)
	button.pressed.connect(_on_row_pressed.bind(offer.id))
	return button

## The focusable rows, Leave last.
func _focusable() -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in _rows.get_children():
		var button := child as Button
		if button != null and button.focus_mode != Control.FOCUS_NONE and not button.is_queued_for_deletion():
			buttons.append(button)
	return buttons

## Explicit neighbours, wrapping at both ends, so focus never leaves the panel and skips the rows out of reach.
func _link_rows() -> void:
	var buttons := _focusable()
	for i: int in buttons.size():
		var button := buttons[i]
		var above := buttons[(i - 1 + buttons.size()) % buttons.size()]
		var below := buttons[(i + 1) % buttons.size()]
		var own := button.get_path_to(button)
		button.focus_neighbor_left = own
		button.focus_neighbor_right = own
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(below)
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom

func _focus_first() -> void:
	_focusable()[0].grab_focus()

## The row index focus is on; -1 when it is outside the rows.
func _focused_index() -> int:
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focused == null or focused.get_parent() != _rows:
		return -1
	return focused.get_index()

## The first focusable row at or after `index`, else the last one before it.
func _focus_near(index: int) -> void:
	var buttons := _focusable()
	for button: Button in buttons:
		if button.get_index() >= index:
			button.grab_focus()
			return
	buttons[-1].grab_focus()

func _on_row_pressed(offer_id: StringName) -> void:
	chosen.emit(offer_id)

## Rewrites the shown texts in place, so focus and the rows stay.
func _retranslate() -> void:
	_held.text = tr("SHOP_SEEDS_HELD") % _held_count
	for i: int in _row_ids.size():
		(_rows.get_child(i) as Button).text = row_text(_offers[i])
	if not _said_keys.is_empty():
		say(_said_keys[0], _said_keys[1])
