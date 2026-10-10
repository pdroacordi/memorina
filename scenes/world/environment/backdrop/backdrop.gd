@tool
class_name Backdrop
extends Node2D
## A room's background: one Parallax2D per layer of its set, anchored to the room's horizon where the art has an edge and to
## world 0 where it repeats (design 04 section 6, architecture/vertical-backdrops, architecture/backdrop-seams).

const SHADER := preload("res://scenes/world/environment/backdrop/backdrop_layer.gdshader")
## Half the 640x360 view, px.
const HALF_VIEW := Vector2(320.0, 180.0)
## Px each layer covers past the camera's travel: shake and zoom slack.
const MARGIN := 32.0
## World px across which two touching rooms' backdrops dither into each other (architecture/backdrop-seams).
const SEAM_BAND := 64.0
## Touching rooms a layer's shader takes (its array size).
const MAX_NEIGHBOURS := 8
## Bounds relative to this node without a Room (the editor, a contents scene opened alone).
const PREVIEW_BOUNDS := Rect2(0.0, -384.0, 1920.0, 768.0)
## Behind a room's [back] walls (-20) and props (-10) (architecture/props-and-ambient-life).
const Z := -30

@export var backdrop_set: BackdropSet:
	set(value):
		if backdrop_set != null and backdrop_set.changed.is_connected(refresh):
			backdrop_set.changed.disconnect(refresh)
		backdrop_set = value
		if backdrop_set != null:
			backdrop_set.changed.connect(refresh)
		if is_node_ready():
			refresh()
## The room's horizon, px below this node: where each layer's horizon row stands at the reference camera.
@export var horizon_y: float = 0.0:
	set(value):
		horizon_y = value
		if is_node_ready():
			refresh()


func _ready() -> void:
	z_index = Z
	refresh()

## Rebuilds every layer; the built nodes are never saved.
func refresh() -> void:
	# A backdrop in a background editor tab is out of the tree and shares the cached set.
	if not is_inside_tree():
		return
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if backdrop_set == null:
		return
	var room := Room.of(self)
	var bounds := room.get_bounds() if room != null else Rect2(global_position + PREVIEW_BOUNDS.position, PREVIEW_BOUNDS.size)
	var anchor := global_position + Vector2(0.0, horizon_y)
	var camera: Camera2D = null if Engine.is_editor_hint() else get_viewport().get_camera_2d()
	var neighbours := _neighbours(room)
	for i: int in backdrop_set.layers.size():
		var layer := backdrop_set.layers[i]
		if layer != null and layer.texture != null:
			var layer_anchor := BackdropMath.layer_anchor(anchor, layer.repeat_x, layer.repeats_y()) if room != null else anchor
			var ref := BackdropMath.reference_centre(layer_anchor, backdrop_set.horizon_screen_y, HALF_VIEW)
			_add_layer(i, layer, bounds, layer_anchor, ref, camera, room != null, neighbours)

# The touching rooms' bounds, for the seam band; none without a Room (the editor).
func _neighbours(room: Room) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if room == null:
		return rects
	for other: Room in RoomResidency.touching(room, get_tree().get_nodes_in_group(Room.GROUP)):
		if other != room and rects.size() < MAX_NEIGHBOURS:
			rects.append(other.get_bounds())
	return rects

func _add_layer(index: int, layer: BackdropLayer, bounds: Rect2, anchor: Vector2, ref: Vector2, camera: Camera2D, clip: bool,
		neighbours: Array[Rect2]) -> void:
	var cover := BackdropMath.cover_rect(bounds, anchor, ref, layer.scroll_scale, HALF_VIEW, MARGIN + (SEAM_BAND * 0.5 if clip else 0.0))
	cover = BackdropMath.clip_to_fills(cover, layer.strip_size(), layer.horizon_row, layer.fill_above, layer.fill_below, layer.repeat_x)
	if cover.size == Vector2i.ZERO:
		return
	var parallax := Parallax2D.new()
	parallax.name = "Layer%d" % index
	parallax.scroll_scale = layer.scroll_scale
	if Engine.is_editor_hint():
		parallax.ignore_camera_scroll = true
		parallax.scroll_offset = anchor - global_position
	else:
		parallax.scroll_offset = BackdropMath.scroll_offset(anchor, ref, global_position, layer.scroll_scale, HALF_VIEW)
		if camera != null:
			parallax.screen_offset = camera.get_screen_center_position() - HALF_VIEW
	var quad := MeshInstance2D.new()
	quad.name = "Art"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(cover.size)
	quad.mesh = mesh
	quad.position = Vector2(cover.position) + Vector2(cover.size) * 0.5
	var material := _material(layer, quad.position)
	# Clipped to the room and dithered into its neighbours across the seam band (systems/backdrops).
	if clip:
		material.set_shader_parameter(&"room_rect", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
		var rects := PackedVector4Array()
		for other: Rect2 in neighbours:
			rects.append(Vector4(other.position.x, other.position.y, other.size.x, other.size.y))
		rects.resize(MAX_NEIGHBOURS)
		material.set_shader_parameter(&"neighbour_rects", rects)
		material.set_shader_parameter(&"neighbour_count", neighbours.size())
		material.set_shader_parameter(&"seam_band", SEAM_BAND)
	quad.material = material
	parallax.add_child(quad)
	add_child(parallax)

func _material(layer: BackdropLayer, quad_position: Vector2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"sheet", layer.texture)
	material.set_shader_parameter(&"band_count", layer.band_count)
	material.set_shader_parameter(&"band_of_season", layer.band_of_season)
	material.set_shader_parameter(&"horizon_row", layer.horizon_row)
	material.set_shader_parameter(&"fill_above", layer.fill_above)
	material.set_shader_parameter(&"fill_below", layer.fill_below)
	material.set_shader_parameter(&"repeat_x", layer.repeat_x)
	material.set_shader_parameter(&"distance", layer.distance)
	material.set_shader_parameter(&"quad_position", quad_position)
	return material
