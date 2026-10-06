class_name MapCanvas
extends Node2D
## Draws every seen room as a faint fill with an ink line inside its edge, in pack px; world (0, 0) is the canvas origin.
## A Node2D, not a Control: a Control is culled by its own rect, and this one draws far outside it.

## Sampled from the approved mockup (style "C ink overlay"): cream ink, the fill the same cream at 0.27.
const INK := Color(0.92, 0.9, 0.84)
const FILL := Color(0.92, 0.9, 0.84, 0.27)

var _patches: Array[Patch] = []
## Pack px per cell.
var _cell_px: int = 4
## World px covered by every patch's seen cells.
var _seen: Rect2 = Rect2()
var _fill: Array[Rect2i] = []
var _ink: Array[Rect2i] = []


func _draw() -> void:
	for rect: Rect2i in _fill:
		draw_rect(Rect2(rect), FILL)
	for rect: Rect2i in _ink:
		draw_rect(Rect2(rect), INK)

func build(patches: Array[Patch]) -> void:
	_patches = patches
	_seen = Rect2()
	for patch: Patch in patches:
		for run: Rect2i in patch.runs:
			var world := Rect2(patch.origin + Vector2(run.position * MapGrid.CELL_PX), Vector2(run.size * MapGrid.CELL_PX))
			_seen = world if not _seen.has_area() else _seen.merge(world)
	_layout()

func set_cell_px(cell_px: int) -> void:
	_cell_px = cell_px
	_layout()

## World px; an empty rect when nothing was seen.
func seen_rect() -> Rect2:
	return _seen

## Each room's origin is rounded to a whole pack px at this zoom, so its cells land on the pixel grid.
func _layout() -> void:
	_fill.clear()
	_ink.clear()
	for patch: Patch in _patches:
		var at := Vector2i((patch.origin * _cell_px / MapGrid.CELL_PX).round())
		for run: Rect2i in patch.runs:
			_fill.append(Rect2i(at + run.position * _cell_px, run.size * _cell_px))
		for rect: Rect2i in MapOutline.ink(patch.edges, patch.notches, _cell_px):
			_ink.append(Rect2i(at + rect.position, rect.size))
	queue_redraw()


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
