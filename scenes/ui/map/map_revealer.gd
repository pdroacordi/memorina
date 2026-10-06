class_name MapRevealer
extends Node
## Marks the current room's cells the camera shows and writes them through to the live save.
## Pausable and after the camera in tree order: nothing is revealed during a freeze, and the frame is this step's.

@export var camera: GameCamera

var _key: String = ""
## The room's bounds in world px; cells are counted from its top-left.
var _bounds: Rect2 = Rect2()
var _grid: MapGrid
## The last cell range marked; a frame that shows the same range does nothing.
var _marked: Rect2i = Rect2i()


func _physics_process(_delta: float) -> void:
	if _grid == null:
		return
	var view := camera.view_rect().intersection(_bounds)
	view.position -= _bounds.position
	var cells := _grid.cells_in(view, _bounds.size)
	if cells == _marked:
		return
	_marked = cells
	if _grid.mark_cells(cells):
		SaveSystem.set_map_seen(_key, _grid.to_bytes())

## Wired from `Game.room_changed`.
func on_room_changed(room: Room) -> void:
	_bounds = room.get_bounds()
	_key = SceneKey.of(room)
	_grid = MapGrid.from_bytes(SaveSystem.map_seen(_key), MapGrid.dims_for(_bounds))
	_marked = Rect2i()
