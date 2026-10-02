class_name KeyGlyph extends TextureRect

## Displays an action using the active device's glyph, or a labeled blank key when no glyph exists.

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

## Blink timing uses real seconds so recall slow motion does not slow the prompt.
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

## OS display name of the first keyboard event bound to `action`.
static func key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).as_text_physical_keycode()
	# Nothing bound: better an empty key than an internal action id on screen.
	return ""
