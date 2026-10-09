class_name CreatureMask extends SubViewport

## Renders creatures into a separate texture for silhouette-accurate memory effects.
## Must run while paused and stay composited above the world; see `game.tscn` process mode.

## Creature visibility layer (bit 1).
const LAYER := 2

## Main viewport cull mask with the creature bit removed.
const WORLD_CULL_MASK := 0xFFFFFFFF & ~LAYER

## The shader global this pass is published under, so a world shader that must
## see the creatures (water reflecting Ivo) can sample them without a path to
## this node. Declared in project.godot [shader_globals].
const GLOBAL := &"greyhush_creature_pass"

## Adds the creature bit to CanvasItem ancestors and assigns it alone to `item`.
# Ancestors need the bit too because a culled CanvasItem hides its whole subtree.
static func join_layer(item: CanvasItem) -> void:
	_set_layer(item, LAYER)
	var walker: Node = item.get_parent()
	while walker != null and walker is CanvasItem:
		(walker as CanvasItem).visibility_layer |= LAYER
		walker = walker.get_parent()

static func _set_layer(node: Node, layer: int) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visibility_layer = layer
	for child: Node in node.get_children():
		_set_layer(child, layer)

# Published on entering rather than in _ready, which runs once: a pass removed
# and re-added would otherwise leave the global cleared by _exit_tree.
func _enter_tree() -> void:
	RenderingServer.global_shader_parameter_set(GLOBAL, get_texture())

func _ready() -> void:
	# Order matters: world_2d has to be shared before the first draw, or this
	# viewport spends a frame rendering its own empty world.
	world_2d = get_tree().root.world_2d
	canvas_cull_mask = LAYER
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# SubViewport defaults to LINEAR, so mirror the root viewport's filter.
	canvas_item_default_texture_filter = get_tree().root.canvas_item_default_texture_filter

func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set(GLOBAL, null)

func _process(_delta: float) -> void:
	# No Camera2D of its own. Copying the main viewport's canvas transform is
	# exact by construction - it inherits the room clamping game.gd applies to
	# the camera - where a mirrored Camera2D would need its position, offset,
	# zoom and limits kept in sync by hand.
	var root := get_tree().root
	size = Vector2i(root.get_visible_rect().size)
	canvas_transform = root.get_canvas_transform()
