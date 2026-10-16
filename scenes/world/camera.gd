class_name GameCamera
extends Camera2D
## Follows a subject and confines the view to room bounds.

## The focus zoom and look-ahead have landed; the position is in canvas pixels.
signal focused(subject_screen_position: Vector2)
## A glide between room bounds ran out, or snap() cut it; a glide retargeted by set_bounds() emits only when the new one ends.
signal glide_finished

## Px of ground kept in frame under a coming landing, so it reads as ground.
const LANDING_GROUND := 32.0

@export_category("Framing")
## Vertical framing bias in pixels; the script overwrites Camera2D.offset at runtime.
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

@export_category("Fall view")
## Px below the feet kept in frame at full fall speed, at least; the lead never shows less than the follow would.
@export var fall_view             : float = 176.0
## Px/s the lead may grow: a walk-off eases the frame down instead of dropping it in one step.
@export var fall_lead_rise        : float = 720.0
## Px/s the lead may move the frame down; above the fall speed, so it keeps up, but never in one jump.
@export var fall_lead_follow      : float = 1200.0

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

@export_category("Lesson")
## Lesson zoom and duration in real seconds; released with the letterbox.
## Keep the push running through the lesson track so the scene does not stop moving early.
@export var lesson_zoom           : float = 1.15
@export var lesson_push_time      : float = 45.0

@export_category("Room glide")
## Seconds the frame takes to move into a new room's bounds after Ivo walks across a seam.
@export var bounds_glide_time     : float = 0.45
## Px kept between the subject's body and the frame's edge where the room clamp would cut him off.
@export var subject_margin        : float = 8.0

@export_category("Shake")
## The shake decays over its time; strength is the first frame's reach in px.
@export var shake_time            : float = 0.18

var _subject: Node2D
## The other body the frame holds, with how far toward it the frame sits.
var _pair: Node2D
## Whether the frame is CURRENTLY meant to hold a pair. Not the same as
## `_pair`, which outlives a release until its tween has eased back.
var _pairing: bool = false
var _pair_blend: float = 0.0
var _pair_tween: Tween
var _shake_strength: float = 0.0
var _shake_left: float = 0.0
var _look_ahead_tween: Tween
## Px the frame leads the subject by. The look-ahead tween steps after the physics step's clamp, so a write never moves
## the frame past the room (bugs/a-facing-turn-in-a-one-screen-wide-room-slides-the-frame-past-its-bounds).
var _look_ahead := 0.0:
	set(value):
		_look_ahead = value
		_set_offset_x_within_reach(value)
var _focus_tween: Tween
## True between focus() and the `focused` it owes.
var _focus_pending: bool = false
var _peek_axis: float = 0.0
var _peek_hold: float = 0.0
var _bounds: Rect2
var _is_bound: bool = false
## Where the frame may yield past `_bounds` to keep the subject in view; `_bounds` until set_reach().
var _reach: Rect2
## Where the fall lead may yield past `_bounds`: this region's rooms below that span the frame; `_bounds` until set_reach().
var _fall_reach: Rect2
## World px from the new bounds' clamped centre to where the frame stood when they changed; eased out by `_glide_weight`.
var _glide_from: Vector2 = Vector2.ZERO
## 1..0 over a glide, linear in time: `RoomRing.glide_offset` eases each leg.
var _glide_weight: float = 0.0
## Whether the glide's axes ease together or one after the other, so no frame of it leaves the two rooms' rings.
var _glide_order: RoomRing.GlideOrder = RoomRing.GlideOrder.TOGETHER
var _glide_tween: Tween
## Px kept below the feet: rises at `fall_lead_rise`, eases back over `vertical_smooth_time`.
var _fall_lead: float = 0.0
## World y of the frame's centre last step, for `fall_lead_follow`; INF after a snap or before the first step.
var _last_centre_y: float = INF
## This step's shake, so the steady frame can be read without it.
var _shake_offset: Vector2 = Vector2.ZERO
## Reused by every ground ray.
var _ground_ray := PhysicsRayQueryParameters2D.new()
## The zoom the frame returns to after a focus or a cutscene: 1, or a talk's (`frame_talk`).
var _rest_zoom: float = 1.0
## The point a framed talk's speaker stands at; made on the first `frame_talk`.
var _talk_point: Node2D


func _ready() -> void:
	offset.y = framing_offset_y

# Physics sampling keeps the camera aligned with the pixel-snapped subject.
func _physics_process(delta: float) -> void:
	if not _subject:
		return

	global_position = _framed_position()
	_update_vertical(delta)
	_update_fall_lead(delta, global_position.y + offset.y + get_viewport_rect().size.y * 0.5 / zoom.y)
	_apply_bounds()
	global_position += RoomRing.glide_offset(_glide_from, _glide_weight, _glide_order)
	_keep_subject_in_view(delta)
	_last_centre_y = global_position.y + offset.y
	_update_shake(delta)

## Confines the visible rectangle to a world-space area, yielding up to `reach` (the area itself when empty) to keep the
## subject whole; `glide` eases the frame there from where it stands.
func set_bounds(bounds: Rect2, glide: bool = false, reach: Rect2 = Rect2()) -> void:
	var shown := global_position
	var shown_reach := _reach
	_bounds = bounds
	_reach = reach if reach.has_area() else bounds
	_fall_reach = bounds
	_is_bound = true
	_stop_glide()
	if not glide or _subject == null:
		return
	# Measured against the new clamp of the same centre, so a glide retargeted mid-way starts from where the frame is.
	global_position = _framed_position()
	_apply_bounds()
	_keep_subject_in_view(0.0)
	_glide_from = shown - global_position
	var size := get_viewport_rect().size / zoom
	var to := Rect2(global_position + offset - size * 0.5, size)
	_glide_order = RoomRing.glide_order(Rect2(to.position + _glide_from, size), to, shown_reach, _reach)
	global_position = shown
	_glide_weight = 1.0
	# Linear: glide_offset eases each leg out (fast first: until the glide moves, the frame still shows the old room).
	_glide_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_glide_tween.tween_property(self, "_glide_weight", 0.0, bounds_glide_time)
	_glide_tween.finished.connect(glide_finished.emit)

## Where the frame may yield past the bounds to keep the subject whole, and where the fall lead may; set before each step.
func set_reach(reach: Rect2, fall_reach: Rect2 = Rect2()) -> void:
	_reach = reach
	_fall_reach = fall_reach if fall_reach.has_area() else _bounds

## What the room lets the frame show, world-space; an empty rect when the
## room has not bound it. Read by anything that needs to know where the arena
## ENDS - a guardian choosing where to come down from its leap - rather than
## re-deriving the room's extent from the tilemap.
func bounds() -> Rect2:
	return _bounds if _is_bound else Rect2()

## The world rect the frame shows, from the centre and zoom the bounds clamp uses.
func view_rect() -> Rect2:
	var size: Vector2 = get_viewport_rect().size / zoom
	return Rect2(global_position + offset - size * 0.5, size)

## The frame without this step's shake: Game measures the fall reach from it, so a shake never closes the reach
## (bugs/the-frame-jumps-up-when-the-fall-reach-closes-under-a-yielded-frame).
func steady_view_rect() -> Rect2:
	var rect := view_rect()
	rect.position -= _shake_offset
	return rect

# Node2D also permits cutscenes to follow a Marker2D without character facing.
func follow(subject: Node2D) -> void:
	if subject == _subject:
		return

	if _subject is Character:
		_subject.facing_changed.disconnect(_on_subject_facing_changed)

	_subject = subject
	# A marker holds the offset it was given: a look-ahead still easing would drift the frame off the rig.
	if _look_ahead_tween and not (_subject is Character):
		_look_ahead_tween.kill()

	if _subject is Character:
		_subject.facing_changed.connect(_on_subject_facing_changed)
		# An edge-triggered signal delivers nothing on connect, so seed the
		# current facing directly rather than waiting for the first turn.
		_look_ahead = _look_ahead_target()

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
	_tween_zoom(Vector2.ONE * _rest_zoom)

## A talk frames its speaker at `at` with Ivo at `zoom_level` until `release_talk()` (Dialogue.zoom, STORY-16).
func frame_talk(at: Vector2, zoom_level: float) -> void:
	if _talk_point == null:
		_talk_point = Node2D.new()
		_talk_point.top_level = true
		add_child(_talk_point)
	_talk_point.global_position = at
	_rest_zoom = zoom_level
	frame_pair(_talk_point)
	_tween_zoom(Vector2.ONE * zoom_level, pair_duration)

func release_talk() -> void:
	_rest_zoom = 1.0
	if _pair == _talk_point:
		release_pair()
	_tween_zoom(Vector2.ONE, pair_duration)

## The zoom the frame rests at: 1, or a framed talk's.
func rest_zoom() -> float:
	return _rest_zoom

## Holds the frame between the subject and `other`, easing there. No zoom: a
## guardian already fills half the frame, and the call's sheet sits over the
## top of it.
func frame_pair(other: Node2D) -> void:
	_pair = other
	_pairing = true
	_tween_pair(1.0)
	_tween_look_ahead()

func release_pair() -> void:
	_pairing = false
	_tween_pair(0.0)
	_tween_look_ahead()

## A lesson began: the frame closes in on the pair, slowly, for as long as
## the track plays. Through the pause, like every lesson tween.
func push_in() -> void:
	_focus_pending = false
	_tween_zoom(Vector2.ONE * lesson_zoom, lesson_push_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)

func release_push() -> void:
	_tween_zoom(Vector2.ONE, focus_duration)

## Eases the zoom to `value` over `seconds` scaled seconds on the physics clock; 0 seconds sets it at once. A cutscene's
## frame uses it; prefer integer zooms (1.5 draws uneven pixels).
func zoom_to(value: float, seconds: float) -> void:
	if seconds <= 0.0:
		if _focus_tween:
			_focus_tween.kill()
		zoom = Vector2.ONE * value
		return
	_tween_zoom(Vector2.ONE * value, seconds)

## The centre of the frame shown now, without this step's shake.
func shown_centre() -> Vector2:
	return global_position + offset - _shake_offset

## The centre the frame aims at while following `subject`, before the room clamp: its feet, its look-ahead and the
## vertical framing as they stand now. A cutscene's rig returns here before `follow(subject)`, so the hand-back does not jump.
func centre_for(subject: Node2D) -> Vector2:
	var bias: float = subject.frame_bias() if subject.has_method("frame_bias") else 0.0
	var lead := 0.0
	if subject is Character and not _pairing:
		lead = look_ahead_distance * float((subject as Character).facing)
	var at := subject.global_position
	if subject is Character and is_instance_valid(_pair) and _pair_blend > 0.0:
		at.x = lerpf(at.x, (at.x + _pair.global_position.x) / 2.0, _pair_blend)
	return at + Vector2(lead, bias + offset.y)

## Where a followed marker stands for the frame to centre on `centre`: a marker carries no look-ahead or framing, so the
## offset the camera holds is taken off.
func rig_point_for(centre: Vector2) -> Vector2:
	return centre - offset

## Px below the subject's feet the frame keeps in view now; Game counts the rooms it reaches.
func fall_lead() -> float:
	return _fall_lead

## Snaps to the subject and clears smoothing for respawns behind a fade; `keep_fall_lead` keeps a fall's lead
## across a region cut, so the landing below the cut still shows.
func snap(keep_fall_lead: bool = false) -> void:
	_peek_axis = 0.0
	_peek_hold = 0.0
	if not keep_fall_lead:
		_fall_lead = 0.0
	_last_centre_y = INF
	offset.y = framing_offset_y
	if _look_ahead_tween:
		_look_ahead_tween.kill()
	_look_ahead = _look_ahead_target()
	var gliding := _glide_tween != null and _glide_tween.is_running()
	_stop_glide()
	if gliding:
		glide_finished.emit()
	reset_smoothing()

## A decaying random offset; a stronger call while one runs replaces it.
func shake(strength: float) -> void:
	if strength < _shake_strength * (_shake_left / maxf(shake_time, 0.001)):
		return
	_shake_strength = strength
	_shake_left = shake_time

## The subject, or the pair blend toward the other body, before bounds and glide.
func _framed_position() -> Vector2:
	var at := _subject.global_position
	at.y += _frame_bias()
	# A cutscene's rig carries its own frame: the pair blends only a followed character.
	if _subject is Character and is_instance_valid(_pair) and _pair_blend > 0.0:
		at.x = lerpf(at.x, (at.x + _pair.global_position.x) / 2.0, _pair_blend)
	return at

func _stop_glide() -> void:
	if _glide_tween:
		_glide_tween.kill()
	_glide_weight = 0.0
	_glide_from = Vector2.ZERO

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
	_shake_offset = Vector2.ZERO
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var reach := _shake_strength * (_shake_left / maxf(shake_time, 0.001))
	_shake_offset = Vector2(randf_range(-reach, reach), randf_range(-reach, reach)).round()
	global_position += _shake_offset

func _tween_zoom(target: Vector2, seconds: float = focus_duration,
		trans: Tween.TransitionType = focus_transition, ease_type: Tween.EaseType = focus_ease) -> void:
	if _focus_tween:
		_focus_tween.kill()
	# Physics, like the pair and look-ahead tweens: an idle tween steps after every _process, so the
	# canvas passes would copy last frame's zoom (bugs/the-canvas-passes-draw-one-frame-behind-a-camera-zoom-tween).
	_focus_tween = create_tween() \
		.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) \
		.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(trans) \
		.set_ease(ease_type)
	_focus_tween.tween_property(self, "zoom", target, seconds)
	_focus_tween.finished.connect(_check_focused)

func _on_subject_facing_changed(_facing: int) -> void:
	_tween_look_ahead()

## Pair framing disables look-ahead so neither subject is pushed off-screen.
func _look_ahead_target() -> float:
	if _pairing or not (_subject is Character):
		return 0.0
	return look_ahead_distance * float((_subject as Character).facing)

func _tween_look_ahead() -> void:
	if _look_ahead_tween:
		_look_ahead_tween.kill()

	# Pause-independent like the zoom: a lesson freezes the world moments after
	# the draw, and a look-ahead stuck mid-flight would never report `focused`.
	_look_ahead_tween = create_tween() \
		.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) \
		.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) \
		.set_trans(look_ahead_transition) \
		.set_ease(look_ahead_ease)
	_look_ahead_tween.tween_property(self, "_look_ahead",
		_look_ahead_target(), look_ahead_duration)
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

# The vertical target changes each frame with fall speed, so it uses smoothing rather than a tween.
func _update_vertical(delta: float) -> void:
	if not (_subject is Character):
		return

	_update_peek_axis(delta)

	var target: float = framing_offset_y \
		+ peek_distance * _peek_axis \
		+ air_lead_distance * _air_axis()

	offset.y = lerpf(offset.y, target, 1.0 - exp(-delta / vertical_smooth_time))

# Rises at `fall_lead_rise` and eases back after a landing, so the frame never jumps; never past the landing's
# ground, which is already in view (bugs/the-fall-lead-dips-the-frame-below-a-solid-floor-on-a-hard-landing).
# `follow_bottom` is the unclamped frame's bottom edge: matching it, the lead takes over from the follow at a seam
# without a stall (bugs/the-frame-stalls-at-the-floor-seam-before-the-fall-lead-takes-over).
func _update_fall_lead(delta: float, follow_bottom: float) -> void:
	var target := 0.0
	if _air_axis() > 0.0 and _subject.has_method("body_rect"):
		var feet: float = (_subject.body_rect() as Rect2).end.y
		target = maxf(fall_view * _air_axis(), follow_bottom - feet - subject_margin)
	if target >= _fall_lead:
		_fall_lead = minf(target, _fall_lead + fall_lead_rise * delta)
	else:
		_fall_lead = lerpf(_fall_lead, target, 1.0 - exp(-delta / vertical_smooth_time))
	_fall_lead = minf(_fall_lead, _ground_below(_fall_lead, _air_axis() > 0.0))
	# An ease never reaches 0: below half a pixel the lead is gone, and the rays and reach stop running.
	if _fall_lead < 0.5:
		_fall_lead = 0.0

## Px from the subject's feet to the ground below plus `LANDING_GROUND`, looking `reach` px down, by a ray at each
## side of the body. Descending, ground counts only under both sides (a body drifting off an edge does not land
## there); standing or rising, the nearer hit counts, so a stance at an edge never dips the frame. INF if none counts.
func _ground_below(reach: float, descending: bool) -> float:
	if reach <= 0.0 or not _subject.has_method("body_rect"):
		return INF
	var body: Rect2 = _subject.body_rect()
	var deepest := 0.0
	var nearest := INF
	_ground_ray.collision_mask = GroundCollision.COLLISION_LAYER
	for x: float in [body.position.x, body.end.x]:
		# A ray that starts on a surface misses it: start just above the feet, so a stance finds its floor.
		_ground_ray.from = Vector2(x, body.end.y - 2.0)
		_ground_ray.to = _ground_ray.from + Vector2(0.0, reach)
		var hit := get_world_2d().direct_space_state.intersect_ray(_ground_ray)
		if hit.is_empty():
			if descending:
				return INF
			continue
		var depth := maxf((hit.position as Vector2).y - body.end.y, 0.0)
		deepest = maxf(deepest, depth)
		nearest = minf(nearest, depth)
	return (deepest if descending else nearest) + LANDING_GROUND

## -1 rising .. 1 at full fall speed; 0 for a subject without camera intent.
# GDScript has no interfaces, and air_axis()/look_axis() are camera-intent accessors that live on the one character
# with camera intent, not on Character: has_method() is Godot's idiom for an optional capability.
func _air_axis() -> float:
	return _subject.air_axis() if _subject.has_method("air_axis") else 0.0

## Px added to the subject's height before framing: on a helix stair, the steady rise under the risers (systems/helix-stair).
func _frame_bias() -> float:
	return _subject.frame_bias() if _subject.has_method("frame_bias") else 0.0

func _update_peek_axis(delta: float) -> void:
	# See the has_method note at _air_axis(): look_axis() is optional
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

# Clamp the visible rectangle because Camera2D applies offset after its built-in limits.
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

# The room clamp yields to the subject: astride a seam he stays whole in frame over a sliver of the running
# neighbour (bugs/a-hop-below-a-seam-flips-the-room-twice). A subject without body_rect() has no body to keep.
func _keep_subject_in_view(delta: float) -> void:
	if not _is_bound or not _subject.has_method("body_rect"):
		return
	var body: Rect2 = (_subject.body_rect() as Rect2).grow(subject_margin)
	var half: Vector2 = get_viewport_rect().size * 0.5 / zoom
	var centre: Vector2 = global_position + offset
	var kept := Vector2(
		_clamp_axis(centre.x, body.end.x - half.x, body.position.x + half.x, centre.x),
		_clamp_axis(centre.y, body.end.y - half.y, body.position.y + half.y, centre.y))
	# The yield stops at the reach, so over an open top with nothing above no void shows; a glide in progress is never pulled back.
	centre.x = _yield_axis(centre.x, kept.x, _reach.position.x + half.x, _reach.end.x - half.x)
	centre.y = _yield_axis(centre.y, kept.y, _reach.position.y + half.y, _reach.end.y - half.y)
	# The lead yields only into the fall reach (bugs/the-fall-lead-jumps-the-frame-into-a-room-the-body-already-touches-below),
	# capped so body and lead still fit the frame.
	var lead := minf(_fall_lead, maxf(half.y * 2.0 - body.size.y, 0.0))
	if lead > 0.0:
		var shown := maxf(centre.y, body.end.y + lead - half.y)
		# The lead never moves the frame faster than `fall_lead_follow`, so a room swap or glide shows no jump
		# (bugs/the-fall-lead-jumps-the-frame-when-a-glide-swaps-into-a-narrow-room,
		# bugs/the-fall-lead-collapses-at-a-same-region-glide-swap).
		if delta > 0.0 and _last_centre_y != INF:
			shown = minf(shown, maxf(centre.y, _last_centre_y + fall_lead_follow * delta))
		centre.y = _yield_axis(centre.y, shown, _fall_reach.position.y + half.y, _fall_reach.end.y - half.y)
	global_position = centre - offset

## Sets `offset.x` and moves the frame's centre with it only as far as the room's clamp allows: the ring is for keeping
## the subject whole, not for leading him. A frame already past the clamp (a yield, a glide) holds.
func _set_offset_x_within_reach(value: float) -> void:
	var centre := global_position.x + offset.x
	offset.x = value
	if not _is_bound:
		return
	var half := get_viewport_rect().size.x * 0.5 / zoom.x
	var shown := _yield_axis(centre, global_position.x + value, _bounds.position.x + half, _bounds.end.x - half)
	global_position.x = shown - value

func _yield_axis(from: float, to: float, min_value: float, max_value: float) -> float:
	if to > from:
		return minf(to, maxf(from, max_value))
	if to < from:
		return maxf(to, minf(from, min_value))
	return from

func _clamp_axis(value: float, min_value: float, max_value: float, fallback: float) -> float:
	# A room smaller than the viewport on this axis has no travel: centre it.
	if min_value > max_value:
		return fallback
	return clampf(value, min_value, max_value)
