@tool
class_name Backdrop
extends Node2D
## A room's background: one Parallax2D per layer of its set, anchored to its region's horizon where the art has an edge and
## to world 0 where it repeats (design 04 section 6, architecture/vertical-backdrops, architecture/backdrop-seams).

const SHADER := preload("res://scenes/world/environment/backdrop/backdrop_layer.gdshader")
## Half the 640x360 view, px.
const HALF_VIEW := Vector2(320.0, 180.0)
## Px each layer covers past the camera's travel: shake and zoom slack.
const MARGIN := 32.0
## Touching rooms a layer's shader takes (its array size).
const MAX_NEIGHBOURS := 8
## World px a clip grows past the drawn cells: the scissor is whole screen pixels, rounded.
const CLIP_PAD := 2.0
## Bounds relative to this node without a Room (the editor, a contents scene opened alone).
const PREVIEW_BOUNDS := Rect2(0.0, -384.0, 1920.0, 768.0)
## Behind a room's [back] walls (-20) and props (-10) (architecture/props-and-ambient-life).
const Z := -30

## Which of its pixels a layer draws: all, all but the void over the room's top, or only that void. Must match the shader's
## `part`.
enum Part { ALL, UNDER_TOP, OVER_TOP }

## The world rect each clipped item (this node, its Sky holder) is scissored to.
var _clips: Dictionary = {}

## Overrides the region's set (caves, interiors, rooms inside rock); null shows the region's.
@export var backdrop_set: BackdropSet:
	set(value):
		if backdrop_set != null and backdrop_set.changed.is_connected(refresh):
			backdrop_set.changed.disconnect(refresh)
		backdrop_set = value
		if backdrop_set != null:
			backdrop_set.changed.connect(refresh)
		if is_node_ready():
			refresh()


## The set a Backdrop with override `own` draws in `region`: the override, else the region's (null without either).
static func shown_set(own: BackdropSet, region: Region) -> BackdropSet:
	if own != null or region == null:
		return own
	return region.backdrop_set

## The bounds of the rooms touching `room` that its layers judge the ring among; none without a Room (the editor).
static func neighbours_of(room: Room) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if room == null or not room.is_inside_tree():
		return rects
	for other: Room in RoomResidency.touching(room, room.get_tree().get_nodes_in_group(Room.GROUP)):
		if other != room and rects.size() < MAX_NEIGHBOURS:
			rects.append(other.get_bounds())
	return rects

func _ready() -> void:
	z_index = Z
	refresh()

# Showing a canvas item again redraws it and drops its scissor, and a room's contents hide while it idles: the redraw sets
# this node's clip again (measured: without it a woken room's layers run unclipped). The Sky holder re-clips from its own.
func _draw() -> void:
	_clip(self, clip_of(self))

## The world rect `item` (this node or its Sky holder) is scissored to; empty when unclipped.
func clip_of(item: CanvasItem) -> Rect2:
	return _clips.get(item, Rect2())

## Rebuilds every layer; the built nodes are never saved.
func refresh() -> void:
	# A backdrop in a background editor tab is out of the tree and shares the cached set.
	if not is_inside_tree():
		return
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_clips.clear()
	_clip(self, Rect2())
	var room := Room.of(self)
	var region := room.get_parent() as Region if room != null else null
	var shown := shown_set(backdrop_set, region)
	if shown == null:
		return
	var bounds := room.get_bounds() if room != null else Rect2(global_position + PREVIEW_BOUNDS.position, PREVIEW_BOUNDS.size)
	var anchor := global_position
	if region != null:
		anchor.y = region.global_position.y + region.horizon_y
	var camera: Camera2D = null if Engine.is_editor_hint() else get_viewport().get_camera_2d()
	var neighbours := neighbours_of(room)
	# Over its top a room shows its region's open set, so sky stays sky above an overridden room's walls
	# (bugs/a-wall-climb-over-the-seam-pillar-shows-the-wall-up-cut-in-the-sky).
	var sky := region.backdrop_set if region != null else null
	var split := room != null and sky != null and sky != shown
	# Scissored to the cells the room keeps, so no fragment runs where the shader would discard it (systems/backdrops,
	# "Clipped quads"); a clip off screen culls its layers.
	if room != null:
		_clip(self, BackdropMath.bounding(BackdropMath.drawn_cells(bounds, neighbours, RoomRing.WIDTH, Part.ALL)))
	_add_set(self, "Layer", shown, Part.UNDER_TOP if split else Part.ALL, bounds, anchor, camera, room != null, neighbours)
	if split:
		var over := BackdropMath.bounding(BackdropMath.drawn_cells(bounds, neighbours, RoomRing.WIDTH, Part.OVER_TOP))
		if over.has_area():
			var holder := Node2D.new()
			holder.name = "Sky"
			add_child(holder)
			_clip(holder, over)
			# Its own redraw, queued after this node's when the room wakes, clears the clip: set it again from there
			# (bugs/a-split-backdrops-sky-holder-loses-its-clip-when-its-room-wakes).
			var reclip := _clip.bind(holder, over)
			if not holder.draw.is_connected(reclip):
				holder.draw.connect(reclip)
			_add_set(holder, "Sky", sky, Part.OVER_TOP, bounds, anchor, camera, true, neighbours)


func _add_set(parent: Node2D, prefix: String, drawn: BackdropSet, part: Part, bounds: Rect2, anchor: Vector2, camera: Camera2D,
		clip: bool, neighbours: Array[Rect2]) -> void:
	for i: int in drawn.layers.size():
		var layer := drawn.layers[i]
		if layer != null and layer.texture != null:
			var layer_anchor := BackdropMath.layer_anchor(anchor, layer.repeat_x, layer.repeats_y()) if clip else anchor
			var ref := BackdropMath.reference_centre(layer_anchor, drawn.horizon_screen_y, HALF_VIEW)
			_add_layer(parent, "%s%d" % [prefix, i], layer, part, bounds, layer_anchor, ref, camera, clip, neighbours)

# `parent` sits at this node's origin, so the scroll offset is measured from this node.
func _add_layer(parent: Node2D, layer_name: String, layer: BackdropLayer, part: Part, bounds: Rect2, anchor: Vector2,
		ref: Vector2, camera: Camera2D, clip: bool, neighbours: Array[Rect2]) -> void:
	# Under a Room the camera may show the ring too (RoomRing.reach).
	var shown := RoomRing.reach(bounds) if clip else bounds
	var cover := BackdropMath.cover_rect(shown, anchor, ref, layer.scroll_scale, HALF_VIEW, MARGIN)
	cover = BackdropMath.clip_to_fills(cover, layer.strip_size(), layer.horizon_row, layer.fill_above, layer.fill_below, layer.repeat_x)
	if cover.size == Vector2i.ZERO:
		return
	var parallax := Parallax2D.new()
	parallax.name = layer_name
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
	# Clipped to the room and the void it is nearest within the ring (systems/backdrops).
	if clip:
		material.set_shader_parameter(&"room_rect", Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y))
		var rects := PackedVector4Array()
		for other: Rect2 in neighbours:
			rects.append(Vector4(other.position.x, other.position.y, other.size.x, other.size.y))
		rects.resize(MAX_NEIGHBOURS)
		material.set_shader_parameter(&"neighbour_rects", rects)
		material.set_shader_parameter(&"neighbour_count", neighbours.size())
		material.set_shader_parameter(&"ring", RoomRing.WIDTH)
		material.set_shader_parameter(&"part", part)
	quad.material = material
	parallax.add_child(quad)
	parent.add_child(parallax)

# Scissors `item` and its children to the world rect `world`; an empty rect lifts the clip.
func _clip(item: CanvasItem, world: Rect2) -> void:
	var rid := item.get_canvas_item()
	_clips[item] = world
	if not world.has_area():
		RenderingServer.canvas_item_set_clip(rid, false)
		RenderingServer.canvas_item_set_custom_rect(rid, false)
		return
	var local := Rect2(world.position - global_position, world.size).grow(CLIP_PAD)
	RenderingServer.canvas_item_set_custom_rect(rid, true, local)
	RenderingServer.canvas_item_set_clip(rid, true)

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
