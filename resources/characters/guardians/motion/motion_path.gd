class_name MotionPath
extends RefCounted
## A planned reposition: offsets from the start feet by strike time, in px and scaled s (GuardianMover, combat_reach_test).

## The strike's length, s.
var duration: float = 0.0
## Scaled s of the blink; negative when the path has none.
var blink_at: float = -1.0
## Offset the blink lands on.
var blink_to: Vector2 = Vector2.ZERO
## Window, s, in which the body cannot be hit or hurt (a blink's out-to-in).
var intangible_from: float = INF
var intangible_to: float = -INF

var _segments: Array[Segment] = []


func _init(strike_duration: float = 0.0) -> void:
	duration = strike_duration

## Moves from the previous end to `to` over `from_t..to_t` s; `arc` px rises above the line at its middle.
## `vertical` gives the path the body's vertical motion there; `ease_out` decelerates into `to`.
func add(from_t: float, to_t: float, to: Vector2, arc: float = 0.0, vertical: bool = false,
		ease_out: bool = false) -> MotionPath:
	var segment := Segment.new()
	segment.t0 = clampf(from_t, 0.0, duration)
	segment.t1 = clampf(maxf(to_t, from_t), 0.0, duration)
	segment.from = end_offset()
	segment.to = to
	segment.arc = arc
	segment.vertical = vertical
	segment.ease_out = ease_out
	_segments.append(segment)
	return self

## Jumps to `to` at `t` s, intangible for `fade` s either side.
func blink(t: float, to: Vector2, fade: float) -> MotionPath:
	blink_at = clampf(t, 0.0, duration)
	blink_to = to
	intangible_from = blink_at - fade
	intangible_to = blink_at + fade
	return add(blink_at, blink_at, to)

## The offset from the start feet at `t` s.
func at(t: float) -> Vector2:
	var offset := Vector2.ZERO
	for segment: Segment in _segments:
		if t < segment.t0:
			return offset
		offset = segment.at(t)
	return offset

func end_offset() -> Vector2:
	return _segments[_segments.size() - 1].to if not _segments.is_empty() else Vector2.ZERO

## Last scaled s at which the path still moves.
func end_time() -> float:
	return _segments[_segments.size() - 1].t1 if not _segments.is_empty() else 0.0

## Whether the path owns the body's vertical motion at `t` s (gravity is suspended).
func holds_vertical(t: float) -> bool:
	for segment: Segment in _segments:
		if segment.vertical and t >= segment.t0 and t <= segment.t1:
			return true
	return false

func is_intangible(t: float) -> bool:
	return t >= intangible_from and t <= intangible_to


class Segment:
	var t0: float = 0.0
	var t1: float = 0.0
	var from: Vector2 = Vector2.ZERO
	var to: Vector2 = Vector2.ZERO
	## Px above the straight line at the middle.
	var arc: float = 0.0
	var vertical: bool = false
	var ease_out: bool = false

	func at(t: float) -> Vector2:
		if t1 <= t0:
			return to if t >= t0 else from
		var u := clampf((t - t0) / (t1 - t0), 0.0, 1.0)
		var along := 1.0 - (1.0 - u) * (1.0 - u) if ease_out else u
		var point := from.lerp(to, along)
		point.y -= 4.0 * arc * u * (1.0 - u)
		return point
