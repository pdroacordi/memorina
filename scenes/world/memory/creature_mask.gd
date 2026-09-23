class_name CreatureMask extends SubViewport

## Renders the creatures, and only the creatures, into their own texture.
##
## This is what makes a GreyhushShield silhouette-exact. The world pass is a
## full-screen shader: it can drain what the camera drew, but it has no idea
## where a sprite's edges are, so a shield could only ever be an approximate
## blob around a body. A pass that contains ONLY creatures knows their edges
## exactly, because every other pixel in it is transparent.
##
## HOW THE SPLIT WORKS. Every CanvasItem has a `visibility_layer`, and every
## Viewport has a `canvas_cull_mask`; an item draws in a viewport only when the
## two overlap. So:
##
##   - creatures are moved to LAYER (bit 1) by GreyhushShield
##   - the main viewport's mask has bit 1 CLEARED, so creatures vanish from it
##   - this SubViewport's mask is bit 1 ALONE, so it gets creatures and nothing
##     else
##   - a TextureRect above the world pass composites them back
##
## PAUSE. This pass mirrors the main viewport every frame, so it must run
## through a pause like the rest of the memory layer: the camera still moves
## while the world is frozen (a lesson pushes in), and a creature pass left on
## the last transform draws every creature where it USED to be - bodies
## floating off the floor. PROCESS_MODE_ALWAYS is set in game.tscn.
##
## COST AND CONSEQUENCE. One extra render pass over the creature layer, which is
## a handful of sprites. The consequence worth knowing is Z ORDER: creatures are
## composited above the finished world, so they draw in front of everything,
## including any future foreground tile layer. Nothing in the game has such a
## layer today; when one arrives it needs its own creature-bit treatment.

## The visibility layer creatures are moved to. Bit 1, because bit 0 is the
## default every other CanvasItem in the project already uses.
const LAYER := 2

## The main viewport's mask with the creature bit removed, so creatures render
## here and nowhere else.
const WORLD_CULL_MASK := 0xFFFFFFFF & ~LAYER

## The shader global this pass is published under, so a world shader that must
## see the creatures (water reflecting Ivo) can sample them without a path to
## this node. Declared in project.godot [shader_globals].
const GLOBAL := &"greyhush_creature_pass"

## Moves `item` and its whole subtree onto the creature layer, and opens the
## path to it.
##
## Both halves are required, and the second is the one that is easy to miss:
## CanvasItem rendering is HIERARCHICAL. If an ancestor fails this pass's cull
## mask, the whole subtree under it is skipped and the item never draws, however
## its own layer is set. So every CanvasItem ancestor gets the creature bit
## OR-ed in - keeping bit 0 so it still renders normally in the world pass -
## while the item itself gets the creature bit ALONE, which is what removes it
## from the world pass.
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
	# A SubViewport does NOT inherit the project's default texture filter: it
	# defaults to LINEAR on its own, so every creature drawn through this pass
	# came out bilinear-blurred while the world stayed crisp. Mirror the root.
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
