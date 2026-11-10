class_name BindingRow
extends Button
## A rebindable action on one device: its name and the name of its binding, or the capture prompt.

const HEIGHT := SettingRow.HEIGHT
## Px inside the row where the binding's name box starts.
const VALUE_LEFT := 180.0
const INK := Color(0.32, 0.2, 0.25, 1)
const FOCUS_INK := Color(0.72, 0.24, 0.16, 1)

var device: KeyBindings.Device = KeyBindings.Device.KEYBOARD
var action: StringName = &""

var _value: Label


static func make(row_device: KeyBindings.Device, row_action: StringName) -> BindingRow:
	var row := BindingRow.new()
	row.device = row_device
	row.action = row_action
	row.name = String(row_action).to_pascal_case()
	return row

## The translation key of an action's name.
static func action_key(of_action: StringName) -> String:
	return "ACTION_" + String(of_action).to_upper()

func _ready() -> void:
	SettingRow.compact(self)
	_value = Label.new()
	_value.name = "Value"
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_value.offset_left = -(272.0 - VALUE_LEFT)
	_value.offset_right = -4.0
	add_child(_value)
	focus_entered.connect(_restyle)
	focus_exited.connect(_restyle)
	_retranslate()
	_restyle()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_retranslate()

func show_binding(value_text: String) -> void:
	_value.text = value_text

func value_text() -> String:
	return _value.text

func _retranslate() -> void:
	text = tr(action_key(action))

func _restyle() -> void:
	_value.add_theme_color_override(&"font_color", FOCUS_INK if has_focus() else INK)
