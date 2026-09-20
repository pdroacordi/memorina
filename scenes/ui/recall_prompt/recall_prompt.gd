class_name RecallPrompt extends Control

## The button prompt of the emergency QTE (docs/design/02_mecanicas.md
## section 4): "prompt de botao claro, ensinado na hora". Shows the key bound
## to the action the body must remember, at a fixed spot on screen, for as
## long as the recall is open. An observer of Player's signals, wired in
## game.tscn, that decides nothing.
##
## The label is the key's own name from the InputMap (`as_text()`), not prose,
## so it carries no translation key. Glyph textures for the jump and roll
## keys do not exist yet; when they do, this is the one place to map them.

@onready var _key: Label = $Key

func _ready() -> void:
	hide()

func show_for(action: StringName) -> void:
	_key.text = _key_name(action)
	show()

func dismiss() -> void:
	hide()

## The first keyboard event bound to `action`, as the OS names it. Joypad
## bindings are skipped: the design's control table is keyboard-first and the
## notes are the only actions with pad bindings today.
func _key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).as_text_physical_keycode()
	return String(action)
