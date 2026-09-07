extends Camera2D
## Follows a subject, leading horizontally toward its facing and vertically
## toward its look intent and fall speed, without showing outside the room.

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

var _subject: Node2D
var _look_ahead_tween: Tween
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
	_update_vertical(delta)
	_apply_bounds()

## Confines the visible rectangle to a world-space area.
func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds
	_is_bound = true

func follow(subject: Node2D) -> void:
	if subject == _subject:
		return

	if _subject is Player:
		_subject.facing_changed.disconnect(_on_subject_facing_changed)

	_subject = subject

	if _subject is Player:
		_subject.facing_changed.connect(_on_subject_facing_changed)
		# An edge-triggered signal delivers nothing on connect, so seed the
		# current facing directly rather than waiting for the first turn.
		offset.x = look_ahead_distance * _subject.facing

func _on_subject_facing_changed(facing: int) -> void:
	if _look_ahead_tween:
		_look_ahead_tween.kill()

	_look_ahead_tween = create_tween() \
		.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) \
		.set_trans(look_ahead_transition) \
		.set_ease(look_ahead_ease)
	_look_ahead_tween.tween_property(self, "offset:x",
		look_ahead_distance * facing, look_ahead_duration)

# Smoothed toward a computed target rather than tweened like the horizontal
# axis: two sources feed this axis and the fall-speed one changes every frame,
# which a tween cannot track without being restarted constantly.
func _update_vertical(delta: float) -> void:
	if not (_subject is Player):
		return

	_update_peek_axis(delta)

	var target: float = framing_offset_y \
		+ peek_distance * _peek_axis \
		+ air_lead_distance * _subject.air_axis()

	offset.y = lerpf(offset.y, target, 1.0 - exp(-delta / vertical_smooth_time))

func _update_peek_axis(delta: float) -> void:
	var desired: float = _subject.look_axis()

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
