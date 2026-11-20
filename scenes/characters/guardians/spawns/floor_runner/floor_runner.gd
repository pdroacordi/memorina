class_name FloorRunner
extends SpawnedAttack
## A row of thorns or an ice wave running along the floor away from the guardian. Where it stops (a gap, a wall, the
## arena's edge or its reach) it ends: its box goes off and it fades, so it never waits on the spot
## (bugs/the-mentors-ice-wave-parks-at-the-lanterns-west-step-on-a-pinned-ivo).

## Px it keeps from the arena's wall.
const EDGE_MARGIN := 8.0
## Px below the floor a probe looks for ground.
const PROBE_DEPTH := 12.0
## Px of trail drawn behind the head.
const TRAIL := 48.0

## Px/s along the floor.
@export var speed: float = 320.0
## Px it runs at most.
@export var reach: float = 560.0
## Px tall, the hit and the drawn spikes.
@export var height: float = 28.0
## Px wide, the hit at its head.
@export var width: float = 20.0
## Physics layers that count as floor under its head.
@export_flags_2d_physics var floor_mask: int = 1
## Spike rise stages, one drawn every frame width; null draws the light/dark placeholder.
@export var art: SpawnArt

## Px along the facing where a probe found a gap; INF while the floor holds.
var _gap_at: float = INF


## Px run along the facing at `t`.
func run_at(t: float) -> float:
	return clampf(speed * (t - warn), 0.0, minf(minf(reach, _edge()), _gap_at))

func aimed() -> bool:
	return true

func is_live(t: float) -> bool:
	return t >= warn and t < _end_time()

func lifetime() -> float:
	return _end_time() + fade

## Scaled s at which its box goes off: the end of `live`, or earlier when its head stops.
func _end_time() -> float:
	var run := minf(minf(reach, _edge()), _gap_at)
	return minf(warn + live, warn + run / maxf(speed, 1.0))

func _advance(_delta: float) -> void:
	if not is_live(_t) or _gap_at < INF:
		return
	var ahead := run_at(_t) + width * 0.5
	var from := global_position + Vector2(facing * ahead, -8.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 8.0 + PROBE_DEPTH), floor_mask)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		_gap_at = run_at(_t)

func _hit_offset(t: float) -> Vector2:
	return Vector2(facing * run_at(t), 0.0)

func _hit_size() -> Vector2:
	return Vector2(width, height)

## Px to the arena's wall ahead; INF when unbounded.
func _edge() -> float:
	if context.arena.size.x <= 0.0:
		return INF
	# The spawner is top-level at the origin, so the position is the world's.
	if facing > 0:
		return maxf(context.arena.end.x - EDGE_MARGIN - position.x - width * 0.5, 0.0)
	return maxf(position.x - context.arena.position.x - EDGE_MARGIN - width * 0.5, 0.0)

func _drawn_rect() -> Rect2:
	var far := facing * minf(reach, _edge())
	return snapped_rect(Rect2(minf(0.0, far) - width * 0.5, -height, absf(far) + width, height))

func _draw() -> void:
	if _t < warn:
		# The crack it will burst from, rising along the way it will run.
		var ahead := facing * (width * 0.5 + TRAIL * 0.5)
		draw_floor_warning(minf(-width * 0.5, ahead), maxf(width * 0.5, ahead), _t / maxf(warn, 0.001))
		return
	var head := run_at(_t)
	var tail := maxf(head - TRAIL, 0.0)
	var end := _end_time()
	var fading := clampf(1.0 - (_t - end) / maxf(fade, 0.001), 0.0, 1.0) if _t >= end else 1.0
	if art != null:
		_draw_spikes(head, tail, fading)
		return
	var step := 8.0
	var along := tail
	while along <= head:
		var rise := height * (0.45 + 0.55 * (along - tail) / maxf(head - tail, 1.0)) * fading
		var x := facing * along
		draw_rect(snapped_rect(Rect2(x - 3.0, -rise, 6.0, rise)), dark)
		draw_rect(snapped_rect(Rect2(x - 1.0, -rise, 2.0, rise * 0.6)), light)
		along += step

## Spikes planted every frame width from the root, tallest at the head and sinking behind it.
func _draw_spikes(head: float, tail: float, fading: float) -> void:
	var step := maxf(art.frame_size().x, 2.0)
	var k := ceili(tail / step)
	while k * step <= head:
		var along := k * step
		var rise := (0.45 + 0.55 * (along - tail) / maxf(head - tail, 1.0)) * fading
		art.draw_frame(self, art.stage(rise), Vector2(facing * along, 0.0), k % 2 == 1)
		k += 1
