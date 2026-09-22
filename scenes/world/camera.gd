class_name GameCamera
extends Camera2D
## Follows a subject, leading horizontally toward its facing and vertically
## toward its look intent and fall speed, without showing outside the room.
## Can hold a pair (a guardian and Ivo, for a call) and shake for a hit.

## The focus zoom has landed and no look-ahead is still in flight: the frame
## is final. `subject_screen_position` is the subject in canvas pixels, for
## whoever must lay out around it (the Memorina's sheet) - the camera is the
## one node that legitimately turns world into screen.
signal focused(subject_screen_position: Vector2)

@export_category("Framing")
## Constant vertical bias, so the character sits below centre. Exported rather
## than read from the node's own offset, which this script overwrites at runtime.
@export var framing_offset_y      : float = -64.0

@export_category("Look ahead")
@export var look_ahead_distance   : float = 96.0
@export var look_ahead_duration   : float = 0.4
@export var look_ahead_transition : Tween.TransitionType = Tween.TRANS_QUART
@export var look_ahead_ease       : Tween.EaseType = Tween.EASE_OUT

@export_category("Peek")
@export var peek_distance         : float = 96.0
## Seconds the look input must be held before the camera peeks, so a tap does
## not swing it. Releasing always returns immediately.
@export var peek_hold_time        : float = 0.3

@export_category("Air lead")
## How far the camera leads at full fall speed — ahead when falling, behind when
## rising.
@export var air_lead_distance     : float = 64.0

@export_category("Vertical smoothing")
## Seconds to close most of the gap to the vertical target. 0 snaps instantly.
@export var vertical_smooth_time  : float = 0.25

@export_category("Focus")
## Zoom while the Memorina is drawn. Non-integer values draw uneven pixels;
## retune to 2.0 if that shows.
@export var focus_zoom            : float = 1.5
@export var focus_duration        : float = 0.5
@export var focus_transition      : Tween.TransitionType = Tween.TRANS_QUAD
@export var focus_ease            : Tween.EaseType = Tween.EASE_OUT

@export_category("Pair")
## Seconds the frame takes to settle between the subject and a pair.
@export var pair_duration         : float = 0.8

@export_category("Shake")
## The shake decays over its time; strength is the first frame's reach in px.
@export var shake_time            : float = 0.18

var _subject: Node2D
## The other body the frame holds, with how far toward it the frame sits.
var _pair: Node2D
var _pair_blend: float = 0.0
var _pair_tween: Tween
var _shake_strength: float = 0.0
var _shake_left: float = 0.0
var _look_ahead_tween: Tween
var _focus_tween: Tween
## True between focus() and the `focused` it owes.
var _focus_pending: bool = false
var _peek_axis: float = 0.0
var _peek_hold: float = 0.0
var _bounds: Rect2
var _is_bound: bool = false


func _ready() -> void:
	offset.y = framing_offset_y

# Physics, not idle: the subject moves in _physics_process, and this game snaps
# transforms to whole pixels — sampling at render rate turns any drift visible.
func _physics_process(delta: float) -> void:
	if not _subject:
		return

	global_position = _subject.global_position
	if is_instance_valid(_pair) and _pair_blend > 0.0:
		var midpoint := (_subject.global_position.x + _pair.global_position.x) / 2.0
		global_position.x = lerpf(global_position.x, midpoint, _pair_blend)
	_update_vertical(delta)
	_apply_bounds()
	_update_shake(delta)

## Confines the visible rectangle to a world-space area.
func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds
	_is_bound = true

# subject stays Node2D rather than narrowing to Character: cutscenes can point
# the camera at a plain Marker2D with no facing, and the `is Character` checks
# below already degrade gracefully for that case.
func follow(subject: Node2D) -> void:
	if subject == _subject:
		return

	if _subject is Character:
		_subject.facing_changed.disconnect(_on_subject_facing_changed)

	_subject = subject

	if _subject is Character:
		_subject.facing_changed.connect(_on_subject_facing_changed)
		# An edge-triggered signal delivers nothing on connect, so seed the
		# current facing directly rather than waiting for the first turn.
		offset.x = look_ahead_distance * _subject.facing

## Eases in on the subject while the instrument is out. The tween runs through
## a paused tree, because the world is frozen while a performance plays and
## the lesson's draw may still be easing in when it starts.
func focus() -> void:
	_focus_pending = true
	# Holding a pair, the frame is already the call's: no zoom, just the report.
	if _pair != null:
		_check_focused.call_deferred()
		return
	_tween_zoom(Vector2.ONE * focus_zoom)

func unfocus() -> void:
	_focus_pending = false
	_tween_zoom(Vector2.ONE)

## Holds the frame between the subject and `other`, easing there. No zoom: a
## guardian already fills half the frame, and the call's sheet sits over the
## top of it.
func frame_pair(other: Node2D) -> void:
	_pair = other
	_tween_pair(1.0)

func release_pair() -> void:
	_tween_pair(0.0)

## A decaying random offset; a stronger call while one runs replaces it.
func shake(strength: float) -> void:
	if strength < _shake_strength * (_shake_left / maxf(shake_time, 0.001)):
		return
	_shake_strength = strength
	_shake_left = shake_time

func _tween_pair(target: float) -> void:
	if _pair_tween:
		_pair_tween.kill()
	_pair_tween = create_tween() \
		.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) \
		.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(focus_transition) \
		.set_ease(focus_ease)
	_pair_tween.tween_property(self, "_pair_blend", target, pair_duration)
	if target <= 0.0:
		_pair_tween.tween_callback(func() -> void: _pair = null)

## Applied last, on top of bounds: a shake may show a sliver past the room's
## edge for a frame, which is the point of a shake.
func _update_shake(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var reach := _shake_strength * (_shake_left / maxf(shake_time, 0.001))
	global_position += Vector2(randf_range(-reach, reach), randf_range(-reach, reach)).round()

func _tween_zoom(target: Vector2) -> void:
	if _focus_tween:
		_focus_tween.kill()
	_focus_tween = create_tween() \
		.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(focus_transition) \
		.set_ease(focus_ease)
	_focus_tween.tween_property(self, "zoom", target, focus_duration)
	_focus_tween.finished.connect(_check_focused)

func _on_subject_facing_changed(facing: int) -> void:
	if _look_ahead_tween:
		_look_ahead_tween.kill()

	# Pause-independent like the zoom: a lesson freezes the world moments after
	# the draw, and a look-ahead stuck mid-flight would never report `focused`.
	_look_ahead_tween = create_tween() \
		.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) \
		.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(look_ahead_transition) \
		.set_ease(look_ahead_ease)
	_look_ahead_tween.tween_property(self, "offset:x",
		look_ahead_distance * facing, look_ahead_duration)
	_look_ahead_tween.finished.connect(_check_focused)

## Called as each tween lands; `focused` fires once both have. A look-ahead
## begun by a turn just before the draw is the case that matters: the sheet
## laid out before it lands would sit where the subject is about to be.
func _check_focused() -> void:
	if not _focus_pending or _subject == null \
			or _is_running(_focus_tween) or _is_running(_look_ahead_tween):
		return
	_focus_pending = false
	focused.emit(get_viewport().get_canvas_transform() * _subject.global_position)

func _is_running(tween: Tween) -> bool:
	return tween != null and tween.is_valid() and tween.is_running()

# Smoothed toward a computed target rather than tweened like the horizontal
# axis: two sources feed this axis and the fall-speed one changes every frame,
# which a tween cannot track without being restarted constantly.
func _update_vertical(delta: float) -> void:
	if not (_subject is Character):
		return

	_update_peek_axis(delta)

	# GDScript has no interfaces, and air_axis()/look_axis() are camera-intent
	# accessors that deliberately live on the one character that has camera
	# intent, not on Character itself or a shared component — forcing every
	# future enemy to implement camera intent it will never use would be
	# worse. has_method() is Godot's idiom for an optional capability: a
	# subject without it simply contributes 0.0.
	var air_lead: float = _subject.air_axis() if _subject.has_method("air_axis") else 0.0

	var target: float = framing_offset_y \
		+ peek_distance * _peek_axis \
		+ air_lead_distance * air_lead

	offset.y = lerpf(offset.y, target, 1.0 - exp(-delta / vertical_smooth_time))

func _update_peek_axis(delta: float) -> void:
	# See the has_method note in _update_vertical(): look_axis() is optional
	# camera intent, not part of Character.
	var desired: float = _subject.look_axis() if _subject.has_method("look_axis") else 0.0

	if is_equal_approx(desired, _peek_axis):
		_peek_hold = 0.0
		return

	# Engaging a peek needs the hold; releasing one is immediate.
	if not is_zero_approx(desired):
		_peek_hold += delta
		if _peek_hold < peek_hold_time:
			return

	_peek_hold = 0.0
	_peek_axis = desired

# Clamps the visible rectangle, not the node position: offset is what look-ahead
# and peek drive, and Camera2D applies it after its own limits — which is why
# the built-in limit_* properties cannot confine this camera.
func _apply_bounds() -> void:
	if not _is_bound:
		return

	var half: Vector2 = get_viewport_rect().size * 0.5 / zoom
	var centre: Vector2 = global_position + offset

	centre.x = _clamp_axis(centre.x,
		_bounds.position.x + half.x, _bounds.end.x - half.x, _bounds.get_center().x)
	centre.y = _clamp_axis(centre.y,
		_bounds.position.y + half.y, _bounds.end.y - half.y, _bounds.get_center().y)

	global_position = centre - offset

func _clamp_axis(value: float, min_value: float, max_value: float, fallback: float) -> float:
	# A room smaller than the viewport on this axis has no travel: centre it.
	if min_value > max_value:
		return fallback
	return clampf(value, min_value, max_value)
