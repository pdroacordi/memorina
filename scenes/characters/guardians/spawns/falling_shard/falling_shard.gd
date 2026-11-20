class_name FallingShard
extends SpawnedAttack
## An icicle: a glint over the spot it was aimed at, then the fall onto the floor.

## Px above the floor it falls from.
@export var drop: float = 260.0
## Px/s of the fall.
@export var fall_speed: float = 720.0
## Px of the shard, the hit included.
@export var size: Vector2 = Vector2(10.0, 22.0)
## The icicle hanging, top-aligned: forming stages, whole, then whole with a glint; null draws the light/dark placeholder.
@export var art: SpawnArt
## The icicle bursting where it struck, stages as it fades; drawn only with `art`.
@export var shatter: SpawnArt


## The icicle frame for a warning `grow`n so far (0..1): forming stages up to whole, the glint frame on a `glint` beat
## once whole; `frames` counts the glint frame.
static func icicle_frame(grow: float, glint: bool, frames: int) -> int:
	var stage := SpawnArt.stage_of(grow, frames - 1)
	return frames - 1 if glint and stage == frames - 2 else stage


func aimed() -> bool:
	return true

func from_above() -> bool:
	return true

func _hit_offset(t: float) -> Vector2:
	return Vector2(0.0, minf(-drop + fall_speed * maxf(t - warn, 0.0), 0.0))

func _hit_size() -> Vector2:
	return size

func _drawn_rect() -> Rect2:
	return snapped_rect(Rect2(-size.x - 6.0, -drop - size.y - 10.0, size.x * 2.0 + 12.0, drop + size.y + 10.0))

func _draw() -> void:
	if art != null:
		_draw_icicle()
		return
	if _t < warn:
		# The icicle forming where it hangs, a glint on it with a dark rim (it reads on dark ice), and its spot
		# marked over the grass.
		var grow := clampf(_t / maxf(warn, 0.001), 0.0, 1.0)
		var top := -drop - size.y
		var tall := maxf(size.y * grow, 4.0)
		draw_rect(snapped_rect(Rect2(-size.x * 0.5 - 2.0, top - 2.0, size.x + 4.0, tall + 4.0)), dark)
		draw_rect(snapped_rect(Rect2(-size.x * 0.5, top, size.x, tall)), light)
		if int(_t * 16.0) % 2 == 0:
			draw_rect(snapped_rect(Rect2(-6.0, top - 8.0, 12.0, 8.0)), dark)
			draw_rect(snapped_rect(Rect2(-4.0, top - 6.0, 8.0, 4.0)), light)
		_draw_spot()
		return
	if _t >= warn + live:
		var left := clampf(1.0 - (_t - warn - live) / maxf(fade, 0.001), 0.0, 1.0)
		draw_rect(snapped_rect(Rect2(-size.x * 0.5 - 2.0, -6.0 * left - 2.0, size.x + 4.0, 6.0 * left + 2.0)), dark)
		draw_rect(snapped_rect(Rect2(-size.x * 0.5, -6.0 * left, size.x, 6.0 * left)), light)
		return
	var tip := _hit_offset(_t)
	draw_rect(snapped_rect(Rect2(tip.x - size.x * 0.5 - 2.0, tip.y - size.y - 2.0, size.x + 4.0, size.y + 2.0)), dark)
	draw_rect(snapped_rect(Rect2(tip.x - size.x * 0.5, tip.y - size.y, size.x, size.y - 2.0)), light)

## The spot is marked at full height from the first frame, with a dark shadow under it, so it never passes for the snow
## fringe (playtests/2026-11-18-grd14-frost-feel).
func _draw_spot() -> void:
	draw_rect(snapped_rect(Rect2(-size.x, -4.0, size.x * 2.0, 4.0)), dark)
	draw_floor_warning(-size.x, size.x, 1.0)

## The strip hangs its body's bottom at the hit's bottom: from `drop` while it forms, at the tip while it falls.
func _draw_icicle() -> void:
	if _t < warn:
		var grow := clampf(_t / maxf(warn, 0.001), 0.0, 1.0)
		art.draw_frame(self, icicle_frame(grow, int(_t * 16.0) % 2 == 0, art.frames), Vector2(0.0, -drop))
		_draw_spot()
		return
	if _t >= warn + live:
		if shatter != null:
			var left := clampf(1.0 - (_t - warn - live) / maxf(fade, 0.001), 0.0, 1.0)
			shatter.draw_frame(self, shatter.stage(left), Vector2.ZERO)
		return
	art.draw_frame(self, art.frames - 2, _hit_offset(_t))
