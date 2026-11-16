class_name CreditsRoll
extends Control
## Rolls the credits up a centred column over the world and holds the logo at the end, on the pausable, scaled clock; a
## director service beside Letterbox, Fade and EngravingView (architecture/story-07-epilogue, "The credits").

const GROUP := &"credits_rolls"
## Art px of the view the column rolls through.
const VIEW_HEIGHT := 180.0
## Art px over which a row fades in at the bottom edge and out at the top.
const EDGE_BAND := 24.0
## Art px between two sections, and between an entry and the next.
const SECTION_GAP := 16.0
const ENTRY_GAP := 4.0
const HEADING_SIZE := 20
const TEXT_SIZE := 8
const NAME_COLOUR := Color(0.96, 0.9, 0.72)
const ROLE_COLOUR := Color(0.85, 0.75, 0.66)
const OUTLINE_COLOUR := Color(0.13, 0.08, 0.05)

@export var heading_font: Font
@export var text_font: Font
@export var logo: Texture2D

var _sheet: CreditsSheet
## Scaled seconds since the roll began.
var _t: float = 0.0
## Each translated row and its key; name rows are not here.
var _keys: Dictionary[Label, StringName] = {}

@onready var _column: VBoxContainer = $Art/Column


## The roll of the world `tree` runs; null when none is loaded.
static func find(tree: SceneTree) -> CreditsRoll:
	return tree.get_first_node_in_group(GROUP) as CreditsRoll

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	hide_now()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()

func _process(delta: float) -> void:
	if _sheet == null:
		return
	_t += delta
	_apply()

## Builds `sheet`'s rows below the view and starts rolling them up.
func roll(sheet: CreditsSheet) -> void:
	hide_now()
	if sheet == null:
		return
	_sheet = sheet
	_build()
	visible = true
	_apply()

## Puts the roll at its end at once: the logo centred, its hold over.
func land() -> void:
	if _sheet == null:
		return
	_t = maxf(_t, duration())
	_apply()

## Hides the roll and frees its rows.
func hide_now() -> void:
	for row: Node in _column.get_children():
		_column.remove_child(row)
		row.queue_free()
	_keys.clear()
	_sheet = null
	_t = 0.0
	_column.position.y = VIEW_HEIGHT
	visible = false

## Whether the logo has held for the sheet's `hold_end`; true with no sheet.
func is_done() -> bool:
	return _sheet == null or _t >= duration()

## Scaled seconds from the roll's start to the end of the logo's hold.
func duration() -> float:
	if _sheet == null:
		return 0.0
	return CreditsMath.duration(_content_height(), VIEW_HEIGHT, _last_height(), _sheet.scroll_speed, _sheet.hold_end)

## Scaled seconds since the roll began.
func elapsed() -> float:
	return _t

## The column's rows, top to bottom (the logo last).
func rows() -> Array[Control]:
	var found: Array[Control] = []
	for row: Node in _column.get_children():
		found.append(row as Control)
	return found

func _build() -> void:
	var first := true
	for section: CreditsSection in _sheet.sections:
		if not first:
			_gap(SECTION_GAP)
		first = false
		_label(section.heading_key, heading_font, HEADING_SIZE, NAME_COLOUR)
		for entry: CreditsEntry in section.entries:
			_gap(ENTRY_GAP)
			if not entry.role_key.is_empty():
				_label(entry.role_key, text_font, TEXT_SIZE, ROLE_COLOUR)
			for credited: String in entry.names:
				_label(&"", text_font, TEXT_SIZE, NAME_COLOUR).text = credited
	_gap(SECTION_GAP * 2.0)
	var mark := TextureRect.new()
	mark.texture = logo
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(mark)
	_retranslate()

func _label(key: StringName, font: Font, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", colour)
	label.add_theme_color_override(&"font_outline_color", OUTLINE_COLOUR)
	label.add_theme_constant_override(&"outline_size", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(label)
	if not key.is_empty():
		_keys[label] = key
	return label

func _gap(height: float) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(gap)

func _apply() -> void:
	var rolled := CreditsMath.travel(_content_height(), VIEW_HEIGHT, _last_height())
	_column.position.y = VIEW_HEIGHT - CreditsMath.offset(_t, _sheet.scroll_speed, rolled)
	for row: Control in rows():
		var centre := _column.position.y + row.position.y + row.size.y * 0.5
		row.modulate.a = CreditsMath.edge_alpha(centre, VIEW_HEIGHT, EDGE_BAND)

## Art px of the whole column; autowrapped rows settle over a sort or two (gotchas/autowrapped-rows-settle-over-several-sorts).
func _content_height() -> float:
	return _column.get_combined_minimum_size().y

func _last_height() -> float:
	var count := _column.get_child_count()
	return (_column.get_child(count - 1) as Control).get_combined_minimum_size().y if count > 0 else 0.0

func _retranslate() -> void:
	for label: Label in _keys:
		label.text = tr(_keys[label])
