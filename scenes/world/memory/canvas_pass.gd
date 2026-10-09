class_name CanvasPass extends SubViewport

## Renders one visibility layer of the world into its own texture: the creatures, or the foreground
## (architecture/foreground-layer). Must run while paused and stay composited above the world.

## Creature visibility layer (bit 1).
const CREATURES := 2
## Foreground visibility layer (bit 2).
const FOREGROUND := 4

## The visibility bit this pass draws; the root viewport culls it.
@export_flags_2d_render var layer: int = CREATURES
## The shader global this pass is published under (declared in project.godot [shader_globals]).
@export var global_name: StringName = &"greyhush_creature_pass"


## Puts `item` on `pass_layer` alone and adds the bit to its CanvasItem ancestors.
# Ancestors need the bit too because a culled CanvasItem hides its whole subtree.
static func join_layer(item: CanvasItem, pass_layer: int) -> void:
	_set_layer(item, pass_layer)
	var walker: Node = item.get_parent()
	while walker != null and walker is CanvasItem:
		(walker as CanvasItem).visibility_layer |= pass_layer
		walker = walker.get_parent()

static func _set_layer(node: Node, pass_layer: int) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visibility_layer = pass_layer
	for child: Node in node.get_children():
		_set_layer(child, pass_layer)

# Published on entering rather than in _ready, which runs once: a pass removed
# and re-added would otherwise leave the global cleared by _exit_tree.
func _enter_tree() -> void:
	RenderingServer.global_shader_parameter_set(global_name, get_texture())
	# Each pass owns its bit of the root's mask, so two passes leave in any order.
	get_tree().root.canvas_cull_mask &= ~layer

func _ready() -> void:
	# Order matters: world_2d has to be shared before the first draw, or this
	# viewport spends a frame rendering its own empty world.
	var root := get_tree().root
	world_2d = root.world_2d
	canvas_cull_mask = layer
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# SubViewport defaults to LINEAR and no snapping, so mirror the root viewport.
	canvas_item_default_texture_filter = root.canvas_item_default_texture_filter
	snap_2d_transforms_to_pixel = root.snap_2d_transforms_to_pixel
	snap_2d_vertices_to_pixel = root.snap_2d_vertices_to_pixel

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(global_name, null)
	var tree := get_tree()
	if tree != null:
		tree.root.canvas_cull_mask |= layer

func _process(_delta: float) -> void:
	# No Camera2D of its own. Copying the main viewport's canvas transform is
	# exact by construction - it inherits the room clamping game.gd applies to
	# the camera - where a mirrored Camera2D would need its position, offset,
	# zoom and limits kept in sync by hand.
	var root := get_tree().root
	size = Vector2i(root.get_visible_rect().size)
	canvas_transform = root.get_canvas_transform()
