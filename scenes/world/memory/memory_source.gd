@tool
class_name MemorySource extends Node2D

## One contribution to the memory field. Composed, never subclassed: an authored
## "this corner is worse" patch is a bare instance with negative strength, a
## colour pulse mounts one as a child and drives its radius, and a death mark
## will be a third user of the same node.
##
## @tool so the zone draws itself in the editor viewport. A memory zone has no
## sprite and no collision shape, so without this it is an invisible dot and
## level design is guesswork - you would be placing the most important visual
## feature of the game blind.

## Circle, rectangle or capsule. A rectangle covers a room, a ledge or a
## corridor without the corner overshoot a circle forces on you.
@export var shape: MemoryFieldMath.Shape = MemoryFieldMath.Shape.CIRCLE:
	set(value):
		shape = value
		_refresh()

## CIRCLE: the radius. CAPSULE: the radius of the caps. Ignored by RECT.
@export var radius: float = 64.0:
	set(value):
		radius = maxf(value, 0.0)
		_refresh()

## CAPSULE: half the height of the straight section, NOT counting the caps, so
## the total height is 2 * (height + radius). Ignored by circle and rect.
@export var height: float = 96.0:
	set(value):
		height = maxf(value, 0.0)
		_refresh()

## RECT: full width and height. Ignored by the other two.
@export var rect_size: Vector2 = Vector2(256.0, 128.0):
	set(value):
		rect_size = value.max(Vector2.ZERO)
		_refresh()

## How many pixels the edge takes to fade out, measured OUTWARD from the core.
##
## In pixels rather than as a fraction of the size, which is the whole point for
## level design: a 60px fade looks the same on a small patch and on a room-sized
## one, so a whole region can be given one consistent softness. Left at 0 it
## falls back to DEFAULT_FEATHER_RATIO of the extent.
@export var feather: float = 0.0:
	set(value):
		feather = maxf(value, 0.0)
		_refresh()

## Positive restores memory, negative takes it away.
@export_range(-1.0, 1.0) var strength: float = 1.0:
	set(value):
		strength = clampf(value, -1.0, 1.0)
		_refresh()

## What the greyhush shader tints this source's area with.
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_refresh()

## Decorrelates this source's ragged edge from every other one. Randomised on
## entry when left at zero, so authored patches do not wobble in lockstep.
@export var edge_seed: float = 0.0

@export_group("Editor")
## Draw the zone in the editor viewport. Never drawn in a running game.
@export var show_in_editor: bool = true:
	set(value):
		show_in_editor = value
		_refresh()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if is_zero_approx(edge_seed):
		edge_seed = randf() * 1000.0
	var field := MemoryField.find_in(self)
	if field:
		field.register(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var field := MemoryField.find_in(self)
	if field:
		field.unregister(self)

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_in_editor:
		return
	# Red takes memory away, blue-green gives it back - the same reading as the
	# strength slider, so a glance at the level says which way a zone runs.
	var hue := Color(0.95, 0.35, 0.35) if strength < 0.0 else Color(0.4, 0.8, 0.95)
	var core := hue
	core.a = 0.16 + 0.22 * absf(strength)
	var outline := hue
	outline.a = 0.85
	var faded := hue
	faded.a = 0.3

	_draw_shape(core, true, 0.0)
	_draw_shape(outline, false, 0.0)
	var soft := effective_feather()
	if soft > 0.0:
		_draw_shape(faded, false, soft)

func _draw_shape(color: Color, filled: bool, grow: float) -> void:
	match shape:
		MemoryFieldMath.Shape.RECT:
			var half := rect_size * 0.5 + Vector2(grow, grow)
			draw_rect(Rect2(-half, half * 2.0), color, filled, 1.0)
		MemoryFieldMath.Shape.CAPSULE:
			var r := radius + grow
			if filled:
				draw_rect(Rect2(Vector2(-r, -height), Vector2(r * 2.0, height * 2.0)), color, true)
				draw_circle(Vector2(0.0, -height), r, color)
				draw_circle(Vector2(0.0, height), r, color)
			else:
				draw_arc(Vector2(0.0, -height), r, PI, TAU, 24, color, 1.0)
				draw_arc(Vector2(0.0, height), r, 0.0, PI, 24, color, 1.0)
				draw_line(Vector2(-r, -height), Vector2(-r, height), color, 1.0)
				draw_line(Vector2(r, -height), Vector2(r, height), color, 1.0)
		_:
			var cr := radius + grow
			if filled:
				draw_circle(Vector2.ZERO, cr, color)
			else:
				draw_arc(Vector2.ZERO, cr, 0.0, TAU, 40, color, 1.0)

## The core half-size, packed the way both the CPU and the shader read it.
func extent() -> Vector2:
	match shape:
		MemoryFieldMath.Shape.RECT:
			return rect_size * 0.5
		MemoryFieldMath.Shape.CAPSULE:
			return Vector2(radius, height)
		_:
			return Vector2(radius, radius)

## The fade width actually used, resolving the "0 means pick one for me" default.
func effective_feather() -> float:
	if feather > 0.0:
		return feather
	var e := extent()
	return maxf(e.x, e.y) * MemoryFieldMath.DEFAULT_FEATHER_RATIO

## How far this source reaches from its origin - core plus fade. Used for
## culling, so it may be generous but must never be short.
func reach() -> float:
	var e := extent()
	# Summed, not hypot(). A capsule's furthest point is cap radius PLUS
	# straight half-height, and hypot of the same pair is always smaller - a
	# capsule zone would be culled while its caps were still on screen.
	return e.x + e.y + effective_feather()

func influence_at(global_point: Vector2) -> float:
	var offset := global_point - global_position
	var dist := MemoryFieldMath.source_distance(offset, extent(), shape)
	return MemoryFieldMath.disc_influence(dist, effective_feather(), strength)

func _refresh() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
