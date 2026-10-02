class_name MenuEntry
extends Button
## A menu button that wears the Selected look while focused; the theme's focus box would draw over Pressed.

const FOCUSED_VARIATION := &"MenuEntryFocused"


func _ready() -> void:
	focus_entered.connect(func() -> void: theme_type_variation = FOCUSED_VARIATION)
	focus_exited.connect(func() -> void: theme_type_variation = &"")
