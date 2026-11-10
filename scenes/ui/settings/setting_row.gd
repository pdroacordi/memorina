class_name SettingRow
extends Button
## A row that holds a value: its name, the value (with a StepBar for a volume), and `< value >` while focused.

enum Kind { VOLUME, LANGUAGE, FULLSCREEN, WINDOW }

const HEIGHT := 11.0
## Px inside the row: the bar's left edge and the value's box.
const BAR_X := 136.0
const VALUE_LEFT := 132.0
const NUMBER_LEFT := 248.0
const INK := Color(0.32, 0.2, 0.25, 1)
const FOCUS_INK := Color(0.72, 0.24, 0.16, 1)

var kind: Kind = Kind.VOLUME
## The bus a volume row sets.
var bus: StringName = &""
var label_key: String = ""

## The InkButton look with 1 px above and below the text, so a row is HEIGHT tall: the theme's 1 + 2 px margins
## make it 12 (bugs/settings-rows-measure-12-px-so-reset-to-defaults-sits-on-the-status-line).
static var _compact_style: StyleBoxEmpty

var _value_text: String = ""
var _value: Label
var _bar: StepBar


static func make(row_kind: Kind, key: String, row_bus: StringName = &"") -> SettingRow:
	var row := SettingRow.new()
	row.kind = row_kind
	row.label_key = key
	row.bus = row_bus
	row.name = key.to_lower().to_pascal_case()
	return row

## Makes `button` an InkButton row HEIGHT px tall; shared by every Settings row.
static func compact(button: Button) -> void:
	if _compact_style == null:
		_compact_style = StyleBoxEmpty.new()
		_compact_style.content_margin_left = 4.0
		_compact_style.content_margin_right = 4.0
		_compact_style.content_margin_top = 1.0
		_compact_style.content_margin_bottom = 1.0
	button.theme_type_variation = &"InkButton"
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0.0, HEIGHT)
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, _compact_style)

func _ready() -> void:
	compact(self)
	_value = Label.new()
	_value.name = "Value"
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_value.offset_left = -(272.0 - (NUMBER_LEFT if kind == Kind.VOLUME else VALUE_LEFT))
	_value.offset_right = -4.0
	add_child(_value)
	if kind == Kind.VOLUME:
		_bar = StepBar.new()
		_bar.name = "Bar"
		_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar.position = Vector2(BAR_X, roundf((HEIGHT - StepBar.CELL.y) / 2.0))
		_bar.size = Vector2(StepBar.width(), StepBar.CELL.y)
		add_child(_bar)
	focus_entered.connect(_restyle)
	focus_exited.connect(_restyle)
	_retranslate()
	_restyle()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()

## `step` fills the bar of a volume row.
func show_value(value_text: String, step: int = -1) -> void:
	_value_text = value_text
	if _bar != null and step >= 0:
		_bar.set_value(step)
	_restyle()

## The value as written, without the focus marks.
func value_text() -> String:
	return _value_text

func _retranslate() -> void:
	text = tr(label_key)

func _restyle() -> void:
	var focused := has_focus()
	_value.text = "< %s >" % _value_text if focused and not disabled else _value_text
	var ink := FOCUS_INK if focused else INK
	_value.add_theme_color_override(&"font_color", Color(ink, 0.4) if disabled else ink)
	if _bar != null:
		_bar.color = ink
