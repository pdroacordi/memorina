class_name RecallAura extends Node2D

## Recall window indicator; drawn on the creature layer and animated in real time.

enum State { HIDDEN, ARMED, FLARE, DROP }

const RAYS := 9
const WARM := Color(0.98, 0.78, 0.35)
const HOT := Color(1.0, 0.97, 0.85)
const FAIL := Color(1.0, 0.4, 0.35)
const VERDICT_TIME := 0.35
## How long a press of a chain brightens the crown, in real seconds.
const STEP_FLASH_TIME := 0.25

## Ray geometry in px.
@export var inner_radius: float = 10.0
@export var ray_length: float = 18.0
@export var ray_width: float = 2.0
## How far the rays sway sideways and how fast the wave travels along them.
@export var wave_amplitude: float = 1.6
@export var wave_speed: float = 9.0
@export var tremble_hz: float = 7.0

var _state := State.HIDDEN
var _time: float = 0.0
var _window_total: float = 1.0
var _window_left: float = 0.0
var _verdict_left: float = 0.0
## 1 right after a press of a chain landed, decaying back to 0.
var _step_flash: float = 0.0

func _ready() -> void:
	set_process(false)
	hide()

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	_time += real
	match _state:
		State.ARMED:
			_window_left = maxf(_window_left - real, 0.0)
			_step_flash = maxf(_step_flash - real / STEP_FLASH_TIME, 0.0)
		State.FLARE, State.DROP:
			_verdict_left -= real
			if _verdict_left <= 0.0:
				_settle()
				return
	queue_redraw()

## Starts the armed window.
func begin(_action: StringName, seconds: float) -> void:
	_state = State.ARMED
	_time = 0.0
	_window_total = maxf(seconds, 0.001)
	_window_left = seconds
	_step_flash = 0.0
	show()
	set_process(true)
	queue_redraw()

## Resets the armed window and flashes after a successful chain press.
func step(_remaining: int, seconds: float) -> void:
	if _state != State.ARMED:
		return
	_step_flash = 1.0
	_window_total = maxf(seconds, 0.001)
	_window_left = seconds

## Shows a successful recall verdict.
func flare(_skill: Enums.PlayerSkill) -> void:
	if _state != State.ARMED:
		return
	_state = State.FLARE
	_verdict_left = VERDICT_TIME

## Shows a failed recall verdict.
func drop(_skill: Enums.PlayerSkill) -> void:
	if _state != State.ARMED:
		return
	_state = State.DROP
	_verdict_left = VERDICT_TIME

## Defers settling so a same-frame flare or drop can be received first.
func end() -> void:
	_settle.call_deferred()

func _settle() -> void:
	if (_state == State.FLARE or _state == State.DROP) and _verdict_left > 0.0:
		return
	_state = State.HIDDEN
	set_process(false)
	hide()

func _draw() -> void:
	if _state == State.HIDDEN:
		return
	var verdict := 1.0 - clampf(_verdict_left / VERDICT_TIME, 0.0, 1.0)
	var tremble := 0.5 + 0.5 * sin(TAU * tremble_hz * _time)
	var color := WARM.lerp(HOT, tremble)
	var reach := 1.0
	var alpha := 1.0
	match _state:
		State.ARMED:
			# Increase reach as the recall window expires.
			var urgency := 1.0 - _window_left / _window_total
			reach = 1.0 + 0.5 * urgency + 0.9 * _step_flash
			alpha = 0.7 + 0.3 * tremble
			color = color.lerp(HOT, _step_flash)
		State.FLARE:
			color = HOT
			reach = 1.5 + 2.5 * verdict
			alpha = 1.0 - verdict
		State.DROP:
			color = FAIL
			reach = 1.0 - 0.6 * verdict
			alpha = 1.0 - verdict
	color.a = alpha
	for i: int in RAYS:
		var angle := -PI + (i + 0.5) * PI / RAYS
		# Alternating ray lengths avoid a uniform silhouette.
		var length := ray_length * reach * (1.0 if i % 2 == 0 else 0.7)
		_draw_ray(angle, length, color, i)

## Draws a ray whose sideways sway travels outward.
func _draw_ray(angle: float, length: float, color: Color, seed: int) -> void:
	var dir := Vector2.from_angle(angle)
	var side := dir.orthogonal()
	var points := PackedVector2Array()
	var steps := 5
	for s: int in steps + 1:
		var t := float(s) / steps
		var along := inner_radius + length * t
		var sway := sin(_time * wave_speed + t * 6.0 + seed * 1.7) * wave_amplitude * t
		points.append(dir * along + side * sway)
	draw_polyline(points, color, ray_width, false)
