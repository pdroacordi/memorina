class_name ForegroundPiece
extends Sprite2D
## Art drawn in front of the creatures: parallax from the view centre, a whole-piece fade while a
## character stands behind it (design 04 section 6, architecture/foreground-layer).

## 1..2 per axis: how fast it crosses the screen relative to the play plane (1 is the same depth).
@export var scroll_scale: Vector2 = Vector2.ONE
## Fades while a character stands behind it.
@export var reveals: bool = true
## Alpha (0..1) it fades to.
@export_range(0.0, 1.0) var faded_alpha: float = 0.3
## Scaled seconds from opaque to faded; a hold stops it.
@export var fade_time: float = 0.25
## Fraction (0..1) of a body's rect the piece must cover to fade.
@export_range(0.0, 1.0) var reveal_coverage: float = 0.15
## Local px of the opaque mass; empty uses the whole sprite rect.
@export var reveal_rect: Rect2

## The authored position: the parallax is measured from here.
var _anchor: Vector2


func _ready() -> void:
	assert(get_parent() is Node2D and is_zero_approx((get_parent() as Node2D).global_rotation)
		and (get_parent() as Node2D).global_scale.is_equal_approx(Vector2.ONE),
		"A ForegroundPiece's parent must have no rotation or scale.")
	_anchor = position
	CanvasPass.join_layer(self, CanvasPass.FOREGROUND)
	# The pass mirrors the camera even while paused; the piece must follow it there too.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(scroll_scale != Vector2.ONE or reveals)

# `delta` is scaled by Engine.time_scale, so a hold (scale 0) freezes the fade where it is.
func _process(delta: float) -> void:
	# A deactivated room's contents are hidden; its pieces wait.
	if not is_visible_in_tree():
		return
	var viewport := get_viewport()
	var centre := ForegroundMath.view_centre(viewport.get_canvas_transform(), viewport.get_visible_rect().size)
	var bodies: Array[Rect2] = []
	for node: Node in get_tree().get_nodes_in_group(Character.CHARACTERS_GROUP):
		var body := node as Character
		if body != null and body.is_visible_in_tree():
			bodies.append(body.body_rect())
	update_for(centre, bodies, delta)

## Places the piece for a view centre and fades it by the bodies' rects: the seam tests drive.
func update_for(centre: Vector2, bodies: Array[Rect2], delta: float) -> void:
	var world_anchor := (get_parent() as Node2D).global_position + _anchor
	position = _anchor + ForegroundMath.parallax_offset(world_anchor, centre, scroll_scale)
	var target := 1.0
	if reveals:
		var area := _world_reveal_rect()
		for body: Rect2 in bodies:
			if ForegroundMath.coverage(area, body) >= reveal_coverage:
				target = faded_alpha
				break
	modulate.a = ForegroundMath.fade_toward(modulate.a, target, faded_alpha, fade_time, delta)

func _world_reveal_rect() -> Rect2:
	var local := reveal_rect if reveal_rect.has_area() else get_rect()
	return Rect2(global_position + local.position, local.size)
