@tool
class_name GreyhushShield extends Node2D

## A creature holds a little of its own memory, so it stays more colourful than
## the dead ground it is standing on.
##
## Mounted on anything that should resist the grey: Ivo, an NPC, a
## creature-teacher, a guardian mid-restoration. Costs one uniform slot each.
##
## RENDERING ONLY. This never touches MemoryField.sample(), which is why
## standing in a dead room does not thaw it, wake its weather, or make its water
## freezable. Colour around a body and memory in the ground are two different
## claims, and only the second one is gameplay.
##
## The lore already asks for exactly this shape: the emergency QTE has "cor
## nasce ao redor da cabeca/olhos do heroi - origem no corpo, nao no
## instrumento" (docs/design/02_mecanicas.md section 4).
##
## A Node2D rather than a plain Node, so it can be positioned inside the
## creature and drawn in the editor. Its own position IS the centre of the
## shield, so nudging it to chest height is a drag rather than an exported
## offset.

## How the shield decides which pixels it touches.
enum Mode {
	## The shape lights everything inside it, creature and scenery alike. A
	## capsule of restored colour around a body, with the world showing through.
	HALO,
	## Only the creature's own drawn pixels are lit; nothing behind it brightens
	## at all. The shape still decides how much colour and where the gradient
	## falls - it just acts as a mask rather than as a light.
	SILHOUETTE,
}

## HALO bleeds onto the scenery; SILHOUETTE is pixel-exact to the sprite.
##
## SILHOUETTE moves this creature onto CreatureMask.LAYER so it is rendered by
## the creature pass rather than the world pass - see creature_mask.gd. The one
## consequence to know is Z ORDER: creatures on that layer composite above the
## whole world, so they draw in front of any foreground scenery.
## Read once, in _ready: SILHOUETTE moves the creature onto another visibility
## layer, and moving it back mid-game would need the whole ancestor walk undone.
## Change it in the inspector, not at runtime.
@export var mode: Mode = Mode.SILHOUETTE:
	set(value):
		mode = value
		queue_redraw()

## In SILHOUETTE mode this is not what you see - the sprite is - but it still
## shapes WHERE the gradient falls across the body, so a capsule taller than the
## figure lights it evenly while a small circle at the chest fades the hands and
## feet toward grey.
@export var shape: MemoryFieldMath.Shape = MemoryFieldMath.Shape.CAPSULE:
	set(value):
		shape = value
		notify_property_list_changed()
		queue_redraw()

## CIRCLE: the radius. CAPSULE: the radius of the caps, i.e. half the width.
## Ignored by RECT.
@export var radius: float = 13.0:
	set(value):
		radius = maxf(value, 0.0)
		queue_redraw()

## CAPSULE: half the height of the straight section, NOT counting the caps, so
## the total height is 2 * (height + radius). Ignored by circle and rect.
@export var height: float = 14.0:
	set(value):
		height = maxf(value, 0.0)
		queue_redraw()

## RECT: full width and height. Ignored by the other two.
@export var rect_size: Vector2 = Vector2(26.0, 54.0):
	set(value):
		rect_size = value.max(Vector2.ZERO)
		queue_redraw()

## How many pixels the effect takes to fade out beyond the shape, measured
## outward. Zero gives a hard edge, which against a dithered background reads as
## a cut-out; a little softness usually sits better.
@export var feather: float = 10.0:
	set(value):
		feather = maxf(value, 0.0)
		queue_redraw()

## How much of the grey this creature holds back, 0..1, inside the solid shape.
## At 1 it stays fully coloured no matter how dead the ground is; at 0 it is
## treated like scenery.
##
## Worth landing on a quantisation band - the shader steps memory in
## 1/(memory_levels-1) increments. A value ON a band renders as a solid step; a
## value between two speckles, which is right for a creature that is itself
## fading and wrong for one that is not.
@export_range(0.0, 1.0) var amount: float = 0.8:
	set(value):
		amount = clampf(value, 0.0, 1.0)
		queue_redraw()

## The gradient across the fade, authored on a curve. X runs 0 (the edge of the
## solid shape) to 1 (the outer limit of the feather); Y is how much of `amount`
## survives there.
##
## Left null it is a straight linear ramp.
@export var falloff: Curve:
	set(value):
		if falloff and falloff.changed.is_connected(_on_curve_changed):
			falloff.changed.disconnect(_on_curve_changed)
		falloff = value
		if falloff and not falloff.changed.is_connected(_on_curve_changed):
			falloff.changed.connect(_on_curve_changed)
		queue_redraw()

@export_group("Editor")
## Draw the shield in the editor viewport. Never drawn in a running game.
@export var show_in_editor: bool = true:
	set(value):
		show_in_editor = value
		queue_redraw()

var _field: MemoryField

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if mode == Mode.SILHOUETTE:
		_move_to_creature_layer()
	_field = MemoryField.find_in(self)
	if _field:
		_field.register_shield(self)

## Moves this creature onto the layer the creature pass renders (see
## CreatureMask.join_layer for why its ancestors are touched too).
func _move_to_creature_layer() -> void:
	var creature := get_parent() as CanvasItem
	if creature == null:
		return
	CreatureMask.join_layer(creature)

func _exit_tree() -> void:
	if _field:
		_field.unregister_shield(self)

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_in_editor:
		return
	var hue := Color(0.55, 0.85, 0.7)
	var core := hue
	core.a = 0.14 + 0.2 * amount
	var outline := hue
	outline.a = 0.85
	var faded := hue
	faded.a = 0.3

	_draw_shape(core, true, 0.0)
	_draw_shape(outline, false, 0.0)
	if feather > 0.0:
		_draw_shape(faded, false, feather)

## The shape's half-size, packed the way both the CPU and the shader read it.
func extent() -> Vector2:
	match shape:
		MemoryFieldMath.Shape.RECT:
			return rect_size * 0.5
		MemoryFieldMath.Shape.CAPSULE:
			return Vector2(radius, height)
		_:
			return Vector2(radius, radius)

## Whether this shield should be drawn at all. Riding on the creature's own
## visibility means a hidden creature - or one in a deactivated room - drops out
## without extra bookkeeping.
func is_active() -> bool:
	return amount > 0.0 and is_visible_in_tree()

## Sampled into the curve atlas the shader reads. Returns a flat linear ramp
## when no curve is authored, so the shader has one code path either way.
func sample_falloff(t: float) -> float:
	if falloff == null:
		return 1.0 - t
	return clampf(falloff.sample_baked(t), 0.0, 1.0)

func _draw_shape(color: Color, filled: bool, grow: float) -> void:
	match shape:
		MemoryFieldMath.Shape.RECT:
			var half := rect_size * 0.5 + Vector2(grow, grow)
			draw_rect(Rect2(-half, half * 2.0), color, filled, 1.0)
		MemoryFieldMath.Shape.CAPSULE:
			var r := radius + grow
			var h := height
			if filled:
				draw_rect(Rect2(Vector2(-r, -h), Vector2(r * 2.0, h * 2.0)), color, true)
				draw_circle(Vector2(0.0, -h), r, color)
				draw_circle(Vector2(0.0, h), r, color)
			else:
				draw_arc(Vector2(0.0, -h), r, PI, TAU, 24, color, 1.0)
				draw_arc(Vector2(0.0, h), r, 0.0, PI, 24, color, 1.0)
				draw_line(Vector2(-r, -h), Vector2(-r, h), color, 1.0)
				draw_line(Vector2(r, -h), Vector2(r, h), color, 1.0)
		_:
			var cr := radius + grow
			if filled:
				draw_circle(Vector2.ZERO, cr, color)
			else:
				draw_arc(Vector2.ZERO, cr, 0.0, TAU, 40, color, 1.0)

## Hides the size fields the chosen shape does not use.
func _validate_property(property: Dictionary) -> void:
	var name: StringName = property.name
	var hide := false
	match shape:
		MemoryFieldMath.Shape.CIRCLE:
			hide = name in [&"height", &"rect_size"]
		MemoryFieldMath.Shape.RECT:
			hide = name in [&"radius", &"height"]
		MemoryFieldMath.Shape.CAPSULE:
			hide = name == &"rect_size"
	if hide:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _on_curve_changed() -> void:
	queue_redraw()
