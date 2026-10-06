class_name NotebookRow
extends PanelContainer
## One line of a section's list: an entry's title, or "? ? ?" for one not yet found (unfocusable).

const INK := Color(0.32, 0.2, 0.25)
const INK_FOCUSED := Color(0.72, 0.24, 0.16)
const INK_UNKNOWN := Color(0.32, 0.2, 0.25, 0.35)

## Null for an unknown entry.
var entry: NotebookEntry

@onready var _label: Label = %Label
@onready var _mark: Control = %Mark


func _ready() -> void:
	focus_entered.connect(_paint)
	focus_exited.connect(_paint)

## `entry` null shows the unknown placeholder `text`; `unread` shows the red mark.
func setup(shown: NotebookEntry, text: String, unread: bool) -> void:
	entry = shown
	_label.text = text
	focus_mode = Control.FOCUS_ALL if entry != null else Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP if entry != null else Control.MOUSE_FILTER_IGNORE
	set_unread(unread)
	_paint()

func set_unread(unread: bool) -> void:
	_mark.modulate.a = 1.0 if unread else 0.0

func is_unread() -> bool:
	return _mark.modulate.a > 0.0

func label() -> Label:
	return _label

func _paint() -> void:
	var color := INK_UNKNOWN if entry == null else (INK_FOCUSED if has_focus() else INK)
	_label.add_theme_color_override(&"font_color", color)
