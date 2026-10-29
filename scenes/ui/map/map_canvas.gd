class_name MapCanvas
extends Node2D
## Draws every seen room as a faint fill with an ink line inside its edge, the rooms of a bought map as a fainter line,
## and the rumour marks, in pack px; world (0, 0) is the canvas origin.
## A Node2D, not a Control: a Control is culled by its own rect, and this one draws far outside it.

## Sampled from the approved mockup (style "C ink overlay"): cream ink, the fill the same cream at 0.27.
const INK := Color(0.92, 0.9, 0.84)
const FILL := Color(0.92, 0.9, 0.84, 0.27)
## A bought map's rooms: the same ink at 0.35, no fill ("Accept all (Recommended)", user, 2026-10-28).
const FAINT_INK := Color(0.92, 0.9, 0.84, 0.35)
## Pack px from a rumour mark's centre to its tips: a 5x5 diamond.
const MARK_HALF := 2
## Pack px between the marks of one region.
const MARK_STEP := 7.0

var _patches: Array[Patch] = []
var _known: Array[Patch] = []
## World px of each rumour mark.
var _marks: PackedVector2Array = PackedVector2Array()
## Each mark's x offset in MARK_STEPs.
var _mark_steps: PackedFloat32Array = PackedFloat32Array()
## Pack px per cell.
var _cell_px: int = 4
## World px covered by every patch's seen cells.
var _seen: Rect2 = Rect2()
var _seen_any: bool = false
var _fill: Array[Rect2i] = []
var _ink: Array[Rect2i] = []
var _faint: Array[Rect2i] = []
var _mark_rects: Array[Rect2i] = []


## The pixel rows of a rumour mark's diamond centred on `centre`, in pack px.
static func diamond(centre: Vector2i) -> Array[Rect2i]:
	var rows: Array[Rect2i] = []
	for dy: int in range(-MARK_HALF, MARK_HALF + 1):
		var width := MARK_HALF - absi(dy)
		rows.append(Rect2i(centre.x - width, centre.y + dy, width * 2 + 1, 1))
	return rows

func _draw() -> void:
	for rect: Rect2i in _faint:
		draw_rect(Rect2(rect), FAINT_INK)
	for rect: Rect2i in _fill:
		draw_rect(Rect2(rect), FILL)
	for rect: Rect2i in _ink:
		draw_rect(Rect2(rect), INK)
	for rect: Rect2i in _mark_rects:
		draw_rect(Rect2(rect), INK)

## `known` are a bought map's rooms, drawn under the seen ones; `marks` are rumour points in world px, spread by
## `mark_steps` (MapExtras.steps).
func build(patches: Array[Patch], known: Array[Patch] = [], marks: PackedVector2Array = PackedVector2Array(),
		mark_steps: PackedFloat32Array = PackedFloat32Array()) -> void:
	_patches = patches
	_known = known
	_marks = marks
	_mark_steps = mark_steps
	_seen = Rect2()
	_seen_any = false
	for patch: Patch in known + patches:
		for run: Rect2i in patch.runs:
			_grow_seen(Rect2(patch.origin + Vector2(run.position * MapGrid.CELL_PX), Vector2(run.size * MapGrid.CELL_PX)))
	for mark: Vector2 in marks:
		_grow_seen(Rect2(mark, Vector2.ZERO))
	_layout()

func set_cell_px(cell_px: int) -> void:
	_cell_px = cell_px
	_layout()

## The bought rooms drawn faint.
func known_count() -> int:
	return _known.size()

## World px of each rumour mark drawn.
func marks() -> PackedVector2Array:
	return _marks

## World px covered by the seen cells, the bought rooms and the marks; an empty rect when there is none.
func seen_rect() -> Rect2:
	return _seen

## Each room's origin is rounded to a whole pack px at this zoom, so its cells land on the pixel grid.
func _layout() -> void:
	_fill.clear()
	_ink.clear()
	_faint.clear()
	_mark_rects.clear()
	for patch: Patch in _known:
		_faint.append_array(_ink_of(patch))
	for patch: Patch in _patches:
		var at := _origin_of(patch)
		for run: Rect2i in patch.runs:
			_fill.append(Rect2i(at + run.position * _cell_px, run.size * _cell_px))
		_ink.append_array(_ink_of(patch))
	for i: int in _marks.size():
		var step := _mark_steps[i] if i < _mark_steps.size() else 0.0
		var centre := Vector2i((_marks[i] * _cell_px / MapGrid.CELL_PX + Vector2(step * MARK_STEP, 0.0)).round())
		_mark_rects.append_array(diamond(centre))
	queue_redraw()

func _origin_of(patch: Patch) -> Vector2i:
	return Vector2i((patch.origin * _cell_px / MapGrid.CELL_PX).round())

func _ink_of(patch: Patch) -> Array[Rect2i]:
	var at := _origin_of(patch)
	var rects: Array[Rect2i] = []
	for rect: Rect2i in MapOutline.ink(patch.edges, patch.notches, _cell_px):
		rects.append(Rect2i(at + rect.position, rect.size))
	return rects

func _grow_seen(world: Rect2) -> void:
	_seen = _seen.merge(world) if _seen_any else world
	_seen_any = true


## One room's seen cells and where they sit in the world; its geometry is built once.
class Patch:
	## World px of the room's top-left.
	var origin: Vector2
	var runs: Array[Rect2i]
	var edges: Array[MapOutline.Edge]
	var notches: Dictionary[Vector2i, Vector2i]

	func _init(room_origin: Vector2, grid: MapGrid) -> void:
		origin = room_origin
		runs = MapOutline.fill_runs(grid)
		edges = MapOutline.edges(grid)
		notches = MapOutline.notches(grid)
