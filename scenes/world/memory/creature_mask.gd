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

func _process(_delta: float) -> void:
	# No Camera2D of its own. Copying the main viewport's canvas transform is
	# exact by construction - it inherits the room clamping game.gd applies to
	# the camera - where a mirrored Camera2D would need its position, offset,
	# zoom and limits kept in sync by hand.
	var root := get_tree().root
	size = Vector2i(root.get_visible_rect().size)
	canvas_transform = root.get_canvas_transform()
