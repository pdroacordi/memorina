class_name WorldEdges extends StaticBody2D

## The invisible walls RoomEdges puts on the boundary of every room and its sky band; only Ivo collides with them.

## Physics layer 5, "Invisible Walls".
const LAYER := 16


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0

## Replaces the walls with those of `rooms`; each slab is named after the room it borders, for debugging.
func build(rooms: Array[Room]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var rects: Array[Rect2] = []
	var closed: Array[PackedByteArray] = []
	for room: Room in rooms:
		rects.append(room.get_bounds())
		var map := room.map()
		closed.append(RoomEdges.closed_top(map) if map != null else PackedByteArray())
	var slabs := RoomEdges.walls(rects, RoomEdges.bands(rects, closed))
	for k: int in slabs.size():
		var shape := RectangleShape2D.new()
		shape.size = slabs[k].size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = slabs[k].get_center() - global_position
		collider.name = "%s_%d" % [_bordered(rooms, rects, slabs[k]), k]
		add_child(collider)

# The id of the room whose sky band and ring hold `slab`'s centre.
func _bordered(rooms: Array[Room], rects: Array[Rect2], slab: Rect2) -> String:
	var reach := RoomEdges.CEILING_RISE + RoomEdges.THICKNESS
	for i: int in rects.size():
		if rects[i].grow(reach).has_point(slab.get_center()):
			return String(rooms[i].id())
	return "wall"
