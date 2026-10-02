class_name KeyGlyph extends TextureRect

## An action's button on screen, as the player's own device draws it: the
## arrow key, the D-pad, the Xbox A or the PlayStation cross (InputGlyphs, from
## the binding InputDevice says the hand is on), and it follows the player
## from keyboard to pad while it is shown. A key with no symbol of its own (Z,
## Shift) is the blank medallion key with its name written on it. The one place
## that turns an action into a button the player can read - the recall prompt,
## the answer prompt and a bench all use it. Can blink between its normal and
## selected art, and read as pressed. The label is the key's own name from the
## InputMap, not prose, so it carries no translation key.

enum Look { NORMAL, SELECTED, PRESSED }

const BLINK_TIME := 0.14

## The blank key, for a key the glyph art has no symbol for.
@export var key_normal: Texture2D
@export var key_selected: Texture2D
@export var key_pressed: Texture2D
@export var glyphs: InputGlyphs = preload("res://resources/ui/input/input_glyphs.tres")

var _blinking: bool = false
var _blink: float = 0.0
var _blink_on: bool = false
var _action: StringName = &""
var _look: Look = Look.NORMAL
## The device's own glyph for the action, or null for the blank key and label.
var _glyph: ButtonGlyph

@onready var _label: Label = $Label

func _ready() -> void:
	InputDevice.device_changed.connect(_on_device_changed)
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
	_action = action
	_refresh()

func set_look(look: Look) -> void:
	_look = look
	match look:
		Look.SELECTED:
			texture = _glyph.selected if _glyph else key_selected
		Look.PRESSED:
			texture = _glyph.pressed if _glyph else key_pressed
		_:
			texture = _glyph.normal if _glyph else key_normal

func _on_device_changed(_glyph_set: Enums.GlyphSet) -> void:
	if _action != &"":
		_refresh()

func _refresh() -> void:
	var event := InputDevice.event_for(_action)
	_glyph = glyphs.glyph_for(event, InputDevice.glyph_set) if event != null and glyphs != null else null
	_label.visible = _glyph == null
	_label.text = "" if _glyph else key_name(_action)
	set_look(_look)

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

## The first keyboard event bound to `action`, as the OS names it - written on
## the blank key when the glyph art has no symbol for it. Pad bindings never
## need it: every one of them has its own glyph in InputGlyphs.
static func key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).as_text_physical_keycode()
	# Nothing bound: better an empty key than an internal action id on screen.
	return ""
