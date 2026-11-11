class_name WorldRoomsFixture extends RefCounted

## Every room game.tscn places, and the song trials DebugTrials mounts in debug builds, without a running game: each as
## {id, bounds (world), at (the Room's world position), contents (its PackedScene)}.

const GAME := "res://scenes/world/game.tscn"
const REGION_SCRIPT := preload("res://scenes/world/rooms/region.gd")
const DEBUG_TRIALS := preload("res://scenes/world/debug/debug_trials.gd")


static func rooms() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var state := (load(GAME) as PackedScene).get_state()
	for i: int in state.get_node_count():
		if _property(state, i, &"script") == DEBUG_TRIALS:
			var trials := DEBUG_TRIALS.new() as DebugTrials
			var regions: Array = _property(state, i, &"regions", trials.regions)
			var origin: Vector2 = _property(state, i, &"origin", trials.origin)
			var spacing: Vector2 = _property(state, i, &"spacing", trials.spacing)
			trials.free()
			for k: int in regions.size():
				_add_region(found, regions[k] as PackedScene, origin + spacing * k)
		var scene := state.get_node_instance(i)
		if scene == null or scene.get_state().get_node_count() == 0 or _property(scene.get_state(), 0, &"script") != REGION_SCRIPT:
			continue
		_add_region(found, scene, _property(state, i, &"position", _property(scene.get_state(), 0, &"position", Vector2.ZERO)))
	return found

## The bounds of the rooms touching `own` among `rooms`, at most Backdrop.MAX_NEIGHBOURS, as Backdrop.neighbours_of finds them.
static func neighbours(own: Rect2, rooms: Array[Dictionary]) -> Array[Rect2]:
	var near: Array[Rect2] = []
	for room: Dictionary in rooms:
		var bounds: Rect2 = room.bounds
		if bounds != own and own.grow(1.0).intersects(bounds) and near.size() < Backdrop.MAX_NEIGHBOURS:
			near.append(bounds)
	return near

static func _add_region(found: Array[Dictionary], scene: PackedScene, at: Vector2) -> void:
	var region := scene.instantiate() as Node2D
	for child: Node in region.get_children():
		if child is Room:
			var room := child as Room
			var shape := room.get_node("CollisionShape2D") as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			found.append({
				"id": room.id(),
				"bounds": Rect2(at + room.position + shape.position - size * 0.5, size),
				"at": at + room.position,
				"contents": room.contents_scene,
			})
	region.free()

static func _property(state: SceneState, node: int, property: StringName, fallback: Variant = null) -> Variant:
	for j: int in state.get_node_property_count(node):
		if state.get_node_property_name(node, j) == property:
			return state.get_node_property_value(node, j)
	return fallback
