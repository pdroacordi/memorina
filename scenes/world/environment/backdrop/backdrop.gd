@tool
class_name Backdrop
extends Node2D
## A room's background: one Parallax2D per layer of its set, anchored to the room's horizon (design 04 section 6, architecture/vertical-backdrops).

const SHADER := preload("res://scenes/world/environment/backdrop/backdrop_layer.gdshader")
## Half the 640x360 view, px.
const HALF_VIEW := Vector2(320.0, 180.0)
## Px each layer covers past the camera's travel: shake and zoom slack.
const MARGIN := 32.0
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
	var ref := BackdropMath.reference_centre(anchor, backdrop_set.horizon_screen_y, HALF_VIEW)
	var camera: Camera2D = null if Engine.is_editor_hint() else get_viewport().get_camera_2d()
	for i: int in backdrop_set.layers.size():
		var layer := backdrop_set.layers[i]
		if layer != null and layer.texture != null:
			_add_layer(i, layer, bounds, anchor, ref, camera)

func _add_layer(index: int, layer: BackdropLayer, bounds: Rect2, anchor: Vector2, ref: Vector2, camera: Camera2D) -> void:
	var cover := BackdropMath.cover_rect(bounds, anchor, ref, layer.scroll_scale, HALF_VIEW, MARGIN)
	cover = BackdropMath.clip_to_fills(cover, layer.strip_size(), layer.horizon_row, layer.fill_above, layer.fill_below, layer.repeat_x)
	if cover.size == Vector2i.ZERO:
		return
	var parallax := Parallax2D.new()
	parallax.name = "Layer%d" % index
	parallax.scroll_scale = layer.scroll_scale
	if Engine.is_editor_hint():
		parallax.ignore_camera_scroll = true
		parallax.scroll_offset = Vector2(0.0, horizon_y)
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
	quad.material = _material(layer, quad.position)
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
