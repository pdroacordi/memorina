@tool
class_name RoomVoid extends Node2D

## The black over a room's void cells, outside its shell (architecture/room-void-outside-the-shell). World art, so the
## greyhush greys it like the world.

## Over every room layer in the root canvas: backdrop -30, back walls -20, props -10, ground 0, secret twin 40, water 50.
const Z := 60

## Rects to fill, px in the room map's space.
var rects: Array[Rect2] = []


## The void cells of `map` as rects of cells: runs along each row, merged down while the next row's run matches.
static func runs(map: RoomMap) -> Array[Rect2i]:
	var found: Array[Rect2i] = []
	var open: Dictionary[Vector2i, int] = {}
	for y: int in map.size.y:
		var next_open: Dictionary[Vector2i, int] = {}
		var x := 0
		while x < map.size.x:
			if not map.is_void(map.origin + Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < map.size.x and map.is_void(map.origin + Vector2i(x, y)):
				x += 1
			var key := Vector2i(start, x)
			if open.has(key):
				found[open[key]].size.y += 1
				next_open[key] = open[key]
			else:
				found.append(Rect2i(map.origin + Vector2i(start, y), Vector2i(x - start, 1)))
				next_open[key] = found.size() - 1
		open = next_open
	return found

## Fills `map`'s void with one black rect per run.
func setup(map: RoomMap) -> void:
	z_index = Z
	rects.clear()
	for run: Rect2i in runs(map):
		rects.append(Rect2(Vector2(run.position * RoomMap.CELL_PX), Vector2(run.size * RoomMap.CELL_PX)))
	queue_redraw()

func _draw() -> void:
	for rect: Rect2 in rects:
		draw_rect(rect, Color.BLACK)
