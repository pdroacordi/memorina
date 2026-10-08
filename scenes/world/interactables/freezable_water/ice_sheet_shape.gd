class_name IceSheetShape extends RefCounted

## One ice band per water column, captured where the water stood and kept at that height (docs/knowledge/architecture/ice-is-its-own-sheet.md).

var _left := 0.0
var _column_width := 1.0
var _tops := PackedFloat32Array()
var _bottoms := PackedFloat32Array()
var _present := PackedByteArray()

## `left` is the world x of the first column's left edge; widths in world px.
func _init(column_count: int, column_width: float, left: float) -> void:
	assert(column_count > 0, "Ice needs at least one column")
	_left = left
	_column_width = column_width
	_tops.resize(column_count)
	_bottoms.resize(column_count)
	_present.resize(column_count)

## Whether segment `index` of `points` may be stood on: no steeper than `max_angle` radians.
static func walkable(points: PackedVector2Array, index: int, max_angle: float) -> bool:
	var run := points[index + 1] - points[index]
	return atan2(absf(run.y), absf(run.x)) <= max_angle + 0.0001

func column_count() -> int:
	return _tops.size()

## Ice in `column` from world y `top` down to `bottom`.
func capture(column: int, top: float, bottom: float) -> void:
	assert(bottom >= top, "An ice band's bottom is below its top")
	_tops[column] = top
	_bottoms[column] = bottom
	_present[column] = 1

func release(column: int) -> void:
	_present[column] = 0

func has(column: int) -> bool:
	return _present[column] == 1

func top(column: int) -> float:
	return _tops[column]

## The column's band as (top, bottom), its bottom lowered to the top of a lower neighbour so a steep run is one face.
func band(column: int) -> Vector2:
	var bottom := _bottoms[column]
	if column > 0 and has(column - 1):
		bottom = maxf(bottom, _tops[column - 1])
	if column + 1 < _tops.size() and has(column + 1):
		bottom = maxf(bottom, _tops[column + 1])
	return Vector2(_tops[column], bottom)

## The world y span of every band, as (highest top, lowest bottom); zero when there is no ice.
func y_range() -> Vector2:
	var span := Vector2(INF, -INF)
	for column in _tops.size():
		if has(column):
			var b := band(column)
			span = Vector2(minf(span.x, b.x), maxf(span.y, b.y))
	return span if span.x <= span.y else Vector2.ZERO

func segment_count(per_segment: int) -> int:
	return ceili(float(_tops.size()) / float(per_segment))

## The ice's top as a chain of `segment_count(per_segment) + 1` world points, each joint the mean of the columns meeting there, in whole px.
func segment_points(per_segment: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for joint in segment_count(per_segment) + 1:
		var column := mini(joint * per_segment, _tops.size())
		points.append(Vector2(roundf(_left + column * _column_width), roundf(_joint_y(column - 1, column))))
	return points

# The top where columns `left` and `right` meet: their mean, or the one that has ice.
func _joint_y(left: int, right: int) -> float:
	var total := 0.0
	var count := 0
	for column: int in [left, right]:
		if column >= 0 and column < _tops.size() and has(column):
			total += _tops[column]
			count += 1
	return total / count if count > 0 else 0.0
