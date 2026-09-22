class_name KeyGlyph extends TextureRect

## A keyboard key on screen: the medallion-key art with the name of the first
## key bound to an action written on it. The one place that turns an action
## into a key the player can read - the recall prompt and the answer prompt
## both use it. Can blink between its normal and selected art, and read as
## pressed. The label is the key's own name from the InputMap, not prose, so
## it carries no translation key.

enum Look { NORMAL, SELECTED, PRESSED }

const BLINK_TIME := 0.14

@export var key_normal: Texture2D
@export var key_selected: Texture2D
@export var key_pressed: Texture2D

var _blinking: bool = false
var _blink: float = 0.0
var _blink_on: bool = false

@onready var _label: Label = $Label

func _ready() -> void:
	set_look(Look.NORMAL)
	set_process(false)

## Blinks in REAL time: the recall slows the world, and a prompt that blinked
## at a fifth of its pace would read as stuck.
func _process(delta: float) -> void:
	_blink += delta / maxf(Engine.time_scale, 0.001)
	if _blink >= BLINK_TIME:
		_blink = 0.0
		_blink_on = not _blink_on
		set_look(Look.SELECTED if _blink_on else Look.NORMAL)

func show_action(action: StringName) -> void:
	_label.text = key_name(action)

func set_look(look: Look) -> void:
	match look:
		Look.SELECTED:
			texture = key_selected
		Look.PRESSED:
			texture = key_pressed
		_:
			texture = key_normal

func start_blink() -> void:
	_blinking = true
	_blink = 0.0
	_blink_on = false
	set_look(Look.NORMAL)
	set_process(true)

func stop_blink(look: Look = Look.NORMAL) -> void:
	_blinking = false
	set_process(false)
	set_look(look)

## The first keyboard event bound to `action`, as the OS names it. Joypad
## bindings are skipped: the design's control table is keyboard-first and the
## notes are the only actions with pad bindings today.
static func key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).as_text_physical_keycode()
	# Nothing bound: better an empty key than an internal action id on screen.
	return ""
