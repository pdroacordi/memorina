class_name SpriteBursts extends Node2D

## A pool of short-lived sprites drawn by one node: a splash where a raindrop
## landed, a gust curling across the gale. Each plays its SpriteStrip, drifts
## at its own velocity and is gone. Positions are GLOBAL and snapped to whole
## pixels when drawn, so the art stays on the pixel grid; the node runs on the
## world's clock (it inherits its effect's PAUSABLE mode), so a pause leaves a
## splash hanging where it was. Give it a material to clip it (the season's).

## Alpha steps a fading burst passes through: whole steps, never a smooth fade.
const FADE_STEPS := 3

var _bursts: Array[Burst] = []

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO

func spawn(strip: SpriteStrip, at: Vector2, velocity := Vector2.ZERO, color := Color.WHITE, flip := false) -> void:
	var burst := Burst.new()
	burst.strip = strip
	burst.position = at
	burst.velocity = velocity
	burst.color = color
	burst.flip = flip
	_bursts.append(burst)

func count() -> int:
	return _bursts.size()

func _physics_process(delta: float) -> void:
	var i := 0
	while i < _bursts.size():
		var burst := _bursts[i]
		burst.age += delta
		burst.position += burst.velocity * delta
		if burst.age >= burst.strip.life:
			_bursts[i] = _bursts[_bursts.size() - 1]
			_bursts.pop_back()
		else:
			i += 1
	queue_redraw()

func _draw() -> void:
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	for burst: Burst in _bursts:
		var strip := burst.strip
		var size := strip.frame_size()
		var origin := (burst.position - strip.anchor * size).round()
		if not view.intersects(Rect2(origin, size)):
			continue
		var t := burst.age / strip.life
		var frame := int(burst.age * strip.fps) % strip.frames if strip.fps > 0.0 \
			else mini(int(t * strip.frames), strip.frames - 1)
		var color := burst.color
		if strip.fade > 0.0 and t > 1.0 - strip.fade:
			var left := (1.0 - t) / strip.fade
			color.a *= ceilf(left * FADE_STEPS) / FADE_STEPS
		var region := Rect2(Vector2(frame * size.x, 0.0), size)
		if burst.flip:
			draw_set_transform(origin + Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect_region(strip.texture, Rect2(Vector2.ZERO, size), region, color)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect_region(strip.texture, Rect2(origin, size), region, color)

class Burst:
	var strip: SpriteStrip
	var position := Vector2.ZERO
	var velocity := Vector2.ZERO
	var color := Color.WHITE
	var flip := false
	var age := 0.0
