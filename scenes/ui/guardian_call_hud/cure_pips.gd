class_name CurePips extends Control

## One pip per answer the guardian's cure needs, drawn as small diamonds in
## the song's tint: filled for the answers already given, outlined for the
## ones still to come. The fight's progress at a glance, without a number.
## Draws what it is told; decides nothing.

const PIP_SIZE := 8.0
const PIP_GAP := 14.0
const OUTLINE_WIDTH := 1.0
const FILL_TIME := 0.25

var _done: int = 0
var _total: int = 0
var _tint: Color = Color.WHITE
## The pip being filled, swelling from 0 to 1 as it does; -1 when none is.
var _filling: int = -1
var _fill_progress: float = 0.0

func show_cure(done: int, total: int, tint: Color) -> void:
	_done = clampi(done, 0, total)
	_total = maxi(total, 0)
	_tint = tint
	_filling = -1
	queue_redraw()

## The next pip fills with a beat: the answer that was just given.
func fill_next() -> void:
	if _done >= _total:
		return
	_filling = _done
	_done += 1
	_fill_progress = 0.0
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_fill_progress, 0.0, 1.0, FILL_TIME)
	tween.tween_callback(func() -> void: _filling = -1)

func _set_fill_progress(value: float) -> void:
	_fill_progress = value
	queue_redraw()

func _draw() -> void:
	if _total <= 0:
		return
	var width := (_total - 1) * PIP_GAP
	var start_x := roundf((size.x - width) / 2.0)
	var y := roundf(size.y / 2.0)
	for i: int in _total:
		var centre := Vector2(start_x + i * PIP_GAP, y)
		var half := PIP_SIZE / 2.0
		if i == _filling:
			half *= 0.6 + 0.4 * _fill_progress
		var points := PackedVector2Array([
			centre + Vector2(0.0, -half),
			centre + Vector2(half, 0.0),
			centre + Vector2(0.0, half),
			centre + Vector2(-half, 0.0),
		])
		if i < _done:
			draw_colored_polygon(points, _tint)
		else:
			points.append(points[0])
			draw_polyline(points, _tint.darkened(0.2), OUTLINE_WIDTH)
