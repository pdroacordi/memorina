class_name RecallPrompt extends Control

## The button prompt of the emergency QTE (docs/design/02_mecanicas.md
## section 4): "prompt de botao claro, ensinado na hora". A medallion with the
## key the body must remember blinking inside it, a ring draining with the
## real-time window, and a banner saying what this is. Pressed and green on
## success, red on a miss, then gone. An observer of Player's signals, wired
## in game.tscn, that decides nothing.
##
## The key's label is its own name from the InputMap (`as_text()`), not
## prose, so it carries no translation key; the banner does.

const PROMPT_KEY := "RECALL_PROMPT"
const RING_COLOR := Color(0.98, 0.78, 0.35)
const RING_LOW_COLOR := Color(0.95, 0.4, 0.3)
const SUCCESS_COLOR := Color(0.6, 1.0, 0.65)
const FAIL_COLOR := Color(1.0, 0.4, 0.35)
const LINGER_TIME := 0.35
const BLINK_TIME := 0.14

@export var key_normal: Texture2D
@export var key_selected: Texture2D
@export var key_pressed: Texture2D
## Ring geometry, in this Control's pixels: centred on the medallion.
@export var ring_radius: float = 42.0
@export var ring_width: float = 4.0

var _window_total: float = 0.0
var _window_left: float = 0.0
var _counting: bool = false
var _blink: float = 0.0
var _blink_on: bool = false
var _linger_tween: Tween

@onready var _banner_label: Label = $Banner/Label
@onready var _medallion: Control = $Medallion
@onready var _key: TextureRect = $Medallion/Key
@onready var _key_label: Label = $Medallion/Key/Label

func _ready() -> void:
	_banner_label.text = PROMPT_KEY
	_medallion.draw.connect(_draw_ring)
	hide()

func _process(delta: float) -> void:
	if not _counting:
		return
	# The window is real time: the world is slowed while it is open.
	var real := delta / maxf(Engine.time_scale, 0.001)
	_window_left = maxf(_window_left - real, 0.0)
	_blink += real
	if _blink >= BLINK_TIME:
		_blink = 0.0
		_blink_on = not _blink_on
		_key.texture = key_selected if _blink_on else key_normal
	_medallion.queue_redraw()

func show_for(action: StringName, seconds: float) -> void:
	_stop_linger()
	_key_label.text = _key_name(action)
	_key.texture = key_normal
	_key.modulate = Color.WHITE
	_window_total = maxf(seconds, 0.001)
	_window_left = seconds
	_blink = 0.0
	_blink_on = false
	_counting = true
	modulate = Color.WHITE
	show()
	_medallion.queue_redraw()

## The body remembered: the key reads as pressed and glows.
func on_recalled(_skill: Enums.PlayerSkill) -> void:
	_counting = false
	_key.texture = key_pressed
	_key.modulate = SUCCESS_COLOR
	_medallion.queue_redraw()
	_linger_then_hide()

func on_missed(_skill: Enums.PlayerSkill) -> void:
	_counting = false
	_key.modulate = FAIL_COLOR
	_medallion.queue_redraw()
	_linger_then_hide()

## The recall ended with no verdict (Ivo died): nothing to linger on.
func on_recall_ended() -> void:
	if _counting:
		_counting = false
		call_deferred("_hide_unless_lingering")

func _hide_unless_lingering() -> void:
	if _linger_tween == null:
		hide()

func _draw_ring() -> void:
	var fraction := _window_left / _window_total if _window_total > 0.0 else 0.0
	if not _counting and fraction <= 0.0:
		return
	var centre := _medallion.size / 2.0
	var color := RING_COLOR.lerp(RING_LOW_COLOR, 1.0 - fraction)
	if not _counting:
		color = _key.modulate
	_medallion.draw_arc(centre, ring_radius, -PI / 2.0, -PI / 2.0 + TAU * maxf(fraction, 0.02), 64, color, ring_width, false)

## The first keyboard event bound to `action`, as the OS names it. Joypad
## bindings are skipped: the design's control table is keyboard-first and the
## notes are the only actions with pad bindings today.
func _key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return (event as InputEventKey).as_text_physical_keycode()
	# Nothing bound: better an empty key than an internal action id on screen.
	return ""

func _linger_then_hide() -> void:
	_stop_linger()
	_linger_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_linger_tween.tween_interval(LINGER_TIME)
	_linger_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_linger_tween.tween_callback(_on_linger_done)

func _on_linger_done() -> void:
	_linger_tween = null
	hide()

func _stop_linger() -> void:
	if _linger_tween != null:
		_linger_tween.kill()
		_linger_tween = null
