class_name RecallPrompt extends Control

## Shows the recall key and its real-time deadline above the player (docs/design/02_mecanicas.md section 4).

const RING_COLOR := Color(0.98, 0.78, 0.35)
const RING_LOW_COLOR := Color(0.95, 0.4, 0.3)
const SUCCESS_COLOR := Color(0.6, 1.0, 0.65)
const FAIL_COLOR := Color(1.0, 0.4, 0.35)
const LINGER_TIME := 0.35
## Hold time between chained keys, in real seconds; game time is slowed during recall.
const STEP_HOLD := 0.18
const KEY_SIZE := 32.0
const RING_MARGIN := 12.0

## Ring radius and stroke width in Control pixels.
@export var ring_radius: float = 22.0
@export var ring_width: float = 3.0
## Prompt offset from the player's origin, in world pixels.
@export var head_offset: Vector2 = Vector2(0.0, -78.0)

var _window_total: float = 0.0
var _window_left: float = 0.0
var _counting: bool = false
var _linger_tween: Tween
var _subject: Node2D
var _keys: Array[KeyGlyph] = []
var _current: int = 0
var _step_tween: Tween

@onready var _ring: Control = $Ring
@onready var _key: KeyGlyph = $Ring/Key

func _ready() -> void:
	_keys.append(_key)
	_ring.draw.connect(_draw_ring)
	hide()

func _process(delta: float) -> void:
	_follow_subject()
	if not _counting:
		return
	# The window is real time: the world is slowed while it is open.
	var real := delta / maxf(Engine.time_scale, 0.001)
	_window_left = maxf(_window_left - real, 0.0)
	_ring.queue_redraw()

func show_for(action: StringName, seconds: float, steps: int = 1) -> void:
	_stop_linger()
	_current = 0
	_build_keys(maxi(steps, 1), action)
	_start_window(seconds)
	modulate = Color.WHITE
	_follow_subject()
	show()
	_ring.queue_redraw()

func on_step_taken(_remaining: int, seconds: float) -> void:
	var spent := _keys[_current]
	spent.stop_blink(KeyGlyph.Look.PRESSED)
	spent.modulate = SUCCESS_COLOR
	_current = mini(_current + 1, _keys.size() - 1)
	_start_window(seconds)
	_ring.queue_redraw()
	_stop_step()
	# Real time, like everything else in a recall, but bound to this pausable node so no pause runs it.
	_step_tween = create_tween().set_ignore_time_scale(true)
	_step_tween.tween_interval(STEP_HOLD)
	_step_tween.tween_callback(_ask_current)

## The body remembered: the key reads as pressed and glows.
func on_recalled(_skill: Enums.PlayerSkill) -> void:
	_counting = false
	_stop_step()
	_keys[_current].show()
	_keys[_current].stop_blink(KeyGlyph.Look.PRESSED)
	_keys[_current].modulate = SUCCESS_COLOR
	_ring.queue_redraw()
	_linger_then_hide()

func on_missed(_skill: Enums.PlayerSkill) -> void:
	_counting = false
	_stop_step()
	_keys[_current].show()
	_keys[_current].stop_blink()
	_keys[_current].modulate = FAIL_COLOR
	_ring.queue_redraw()
	_linger_then_hide()

func on_recall_ended() -> void:
	if _counting:
		_counting = false
		_stop_step()
		for key: KeyGlyph in _keys:
			key.stop_blink()
		call_deferred("_hide_unless_lingering")

func _start_window(seconds: float) -> void:
	_window_total = maxf(seconds, 0.001)
	_window_left = seconds
	_counting = true

func _build_keys(count: int, action: StringName) -> void:
	_stop_step()
	while _keys.size() < count:
		var extra := _key.duplicate() as KeyGlyph
		_ring.add_child(extra)
		_keys.append(extra)
	_ring.size = Vector2(KEY_SIZE + RING_MARGIN * 2.0, KEY_SIZE + RING_MARGIN * 2.0)
	for i: int in _keys.size():
		var key := _keys[i]
		key.position = Vector2(RING_MARGIN, RING_MARGIN)
		key.modulate = Color.WHITE
		key.stop_blink()
		key.hide()
		if i < count:
			key.show_action(action)
	_ask_current()

func _ask_current() -> void:
	# Show chained keys one at a time so they are not read as a chord.
	for i: int in _keys.size():
		_keys[i].visible = i == _current
	var key := _keys[_current]
	key.modulate = Color.WHITE
	key.start_blink()

func _stop_step() -> void:
	if _step_tween != null:
		_step_tween.kill()
		_step_tween = null

## Uses the canvas transform each frame because the prompt follows a moving body.
func _follow_subject() -> void:
	if not is_instance_valid(_subject):
		_subject = get_tree().get_first_node_in_group(Player.GROUP) as Node2D
		if _subject == null:
			return
	var screen := get_viewport().get_canvas_transform() * (_subject.global_position + head_offset)
	_ring.position = (screen - _ring.size / 2.0).round()

func _draw_ring() -> void:
	var fraction := _window_left / _window_total if _window_total > 0.0 else 0.0
	if not _counting and fraction <= 0.0:
		return
	var key := _keys[_current]
	var centre := key.position + key.size / 2.0
	var color := RING_COLOR.lerp(RING_LOW_COLOR, 1.0 - fraction)
	if not _counting:
		color = key.modulate
	_ring.draw_arc(centre, ring_radius, -PI / 2.0, -PI / 2.0 + TAU * maxf(fraction, 0.02), 48, color, ring_width, false)

func _hide_unless_lingering() -> void:
	if _linger_tween == null:
		hide()

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
