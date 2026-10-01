class_name RainFall extends PulseEffect

## Chuva (Enums.Song.RAIN): it rains inside the pulse (design 02 section 7.1).
## What the rain FILLS is the world's answer, not the effect's: a RainBasin
## hears the song. The effect is the weather itself:
##
## - DROPS fall, each to where it LANDS: when a drop is born a ray finds the
##   ground, a load or a Redoma's shell under it, or the water, and the drop
##   stops there and splashes instead of falling through the floor. On water it
##   dents the surface and throws up a crown;
## - a CHARACTER in the rain is rained on: a drop crossing the top of Ivo or a
##   creature bursts on its head (characters move, so they are checked as the
##   drop falls, not when it is born);
## - all of it is clipped to the season mask, so it exists only where the pulse
##   has redrawn the world.
##
## Looks like a SONG and not the spring drizzle (design 03 section 5.3): it
## falls only in the pulse, and stops as the grey takes the pulse back. Drops
## are only born over the screen (plus a margin): the ones nobody could see
## would change nothing, and water off screen does not simulate.

## Terrain, Props and the Shell: what a drop lands on.
const LANDS_ON := (1 << 0) | (1 << 1) | (1 << 3)
## Player and Enemy bodies: who is rained on.
const RAINED_ON := (1 << 8) | (1 << 16)
## Characters on screen it looks for at most.
const MAX_HEADS := 16
## Height of a drop's bright head, px.
const HEAD := 2
## How far into a lake's plane (from its far shore toward the viewer) drops
## land, px.
const LAKE_DEPTH := 96.0

## Drops born per second for every pixel of the pulse's width on screen.
@export var drops_per_px := 0.3
@export var fall_speed := Vector2(480.0, 600.0)
## Length of a drop, px (shortest, longest).
@export var drop_length := Vector2i(4, 7)
@export var drop_color := Color(0.78, 0.88, 1.0, 0.8)
## How deep a drop dents the water, px.
@export var drip_depth := 1.2
@export var splash: SpriteStrip
@export var water_splash: SpriteStrip
@export var splash_color := Color(0.86, 0.94, 1.0, 0.9)

# The drops, local to the effect: x, y, speed, where it lands (y), length,
# and the water it lands on (null on the ground, and past the pulse's bottom
# when it lands on nothing).
var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _land := PackedFloat32Array()
var _length := PackedInt32Array()
# Untyped: a body can be freed with its room while a drop is on its way.
var _water: Array = []
var _grounded := PackedByteArray()
var _debt := 0.0
var _query := PhysicsRayQueryParameters2D.new()
# The tops of the characters on screen this frame (local), and the query and
# box that find them.
var _heads: Array[Rect2] = []
var _head_query := PhysicsShapeQueryParameters2D.new()
var _head_box := RectangleShape2D.new()
var _airflow: Airflow

@onready var _splashes: SpriteBursts = $Splashes
## Bursts on a head draw in the creature pass, over the body they land on:
## in the world canvas the character, composited later, would hide them.
@onready var _head_splashes: SpriteBursts = $HeadSplashes

func _ready() -> void:
	_query.collision_mask = LANDS_ON
	# A drop born inside rock (an overhang above the screen's top) is under a
	# roof: it is not born at all.
	_query.hit_from_inside = true
	_head_query.shape = _head_box
	_head_query.collision_mask = RAINED_ON
	_airflow = Airflow.find_in(self)
	var season := pulse.song().season()
	CreatureMask.join_layer(_head_splashes)
	for clipped: CanvasItem in [self, _splashes, _head_splashes]:
		(clipped.material as ShaderMaterial).set_shader_parameter(&"season", season)

## Drops in the air right now.
func drop_count() -> int:
	return _x.size()

func _physics_process(delta: float) -> void:
	var radius := pulse.radius()
	var raining := pulse.phase() != PulseTimeline.Phase.CONTRACT and radius > 8.0
	if raining:
		_rain(delta, radius)
	_find_heads()
	_fall(delta)
	queue_redraw()

func _draw() -> void:
	var view := _view()
	var head_color := Color(drop_color, 1.0)
	for i in _x.size():
		var x := roundf(_x[i])
		var bottom := roundf(_y[i])
		if x < view.position.x or x > view.end.x or bottom < view.position.y or bottom - _length[i] > view.end.y:
			continue
		draw_rect(Rect2(x, bottom - _length[i], 1.0, _length[i] - HEAD), drop_color)
		draw_rect(Rect2(x, bottom - HEAD, 1.0, HEAD), head_color)

## The screen, in the effect's own coordinates.
func _view() -> Rect2:
	var global_view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	return Rect2(global_view.position - global_position, global_view.size)

func _rain(delta: float, radius: float) -> void:
	var view := _view().grow(16.0)
	var left := maxf(view.position.x, -radius)
	var right := minf(view.end.x, radius)
	if right <= left:
		return
	_debt += delta * drops_per_px * (right - left)
	while _debt >= 1.0:
		_debt -= 1.0
		var x := randf_range(left, right)
		var chord := sqrt(maxf(radius * radius - x * x, 0.0))
		# Born at the disc's top or just above the screen, whichever is lower.
		var top := maxf(-chord, view.position.y)
		if top < chord:
			_spawn(x, top, chord)

func _spawn(x: float, top: float, bottom: float) -> void:
	var from := global_position + Vector2(x, top)
	var land := bottom
	var grounded := 0
	_query.from = from
	_query.to = global_position + Vector2(x, bottom)
	var hit := get_world_2d().direct_space_state.intersect_ray(_query)
	if not hit.is_empty():
		land = (hit.position as Vector2).y - global_position.y
		if land <= top:
			return
		grounded = 1
	# The water it falls through, if any: a pool is checked as the drop falls,
	# because the rain itself raises it (a drop aimed at a basin's bed must
	# stop at the waterline that rose to meet it).
	var lands_in: WaterBody = null
	for member: Node in get_tree().get_nodes_in_group(WaterBody.GROUP):
		var water := member as WaterBody
		var painted_top := water.level_range().x - global_position.y
		if water.contains_x(from.x) and painted_top > top and painted_top < land:
			lands_in = water
			if water.is_lake() and not water.is_dry():
				# A lake is seen from above: a drop lands anywhere across its
				# plane, not on its far shore.
				land = water.surface_rest_y() - global_position.y + randf() * minf(water.size.y, LAKE_DEPTH)
	_x.append(x)
	_y.append(top)
	_speed.append(randf_range(fall_speed.x, fall_speed.y))
	_land.append(land)
	_length.append(randi_range(drop_length.x, drop_length.y))
	_water.append(lands_in)
	_grounded.append(grounded)

func _fall(delta: float) -> void:
	var i := 0
	while i < _x.size():
		var was := _y[i]
		_y[i] += _speed[i] * delta
		var surface := _surface_under(i)
		var head := _head_crossed(_x[i], was, _y[i])
		if head < minf(_land[i], surface):
			_head_splashes.spawn(splash, global_position + Vector2(_x[i], head), Vector2.ZERO, splash_color)
		elif _y[i] < minf(_land[i], surface):
			i += 1
			continue
		else:
			_land_drop(i, _y[i] >= surface)
		_remove(i)

## Swaps drop `i` with the last and drops it.
func _remove(i: int) -> void:
	var last := _x.size() - 1
	_x[i] = _x[last]
	_y[i] = _y[last]
	_speed[i] = _speed[last]
	_land[i] = _land[last]
	_length[i] = _length[last]
	_water[i] = _water[last]
	_grounded[i] = _grounded[last]
	_x.resize(last)
	_y.resize(last)
	_speed.resize(last)
	_land.resize(last)
	_length.resize(last)
	_water.resize(last)
	_grounded.resize(last)

## The characters on screen, as the boxes of their collision shapes (local).
func _find_heads() -> void:
	_heads.clear()
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	_head_box.size = view.size
	_head_query.transform = Transform2D(0.0, view.get_center())
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_shape(_head_query, MAX_HEADS):
		var body := hit.get("collider") as CollisionObject2D
		var shape := _first_shape(body)
		if shape:
			var box := shape.shape.get_rect()
			_heads.append(Rect2(shape.global_position + box.position - global_position, box.size))

## The local y where a drop falling from `was` to `now` at `x` crossed the top
## of a character, or INF.
func _head_crossed(x: float, was: float, now: float) -> float:
	for head: Rect2 in _heads:
		if x > head.position.x + 1.0 and x < head.end.x - 1.0 and was < head.position.y and now >= head.position.y:
			return head.position.y
	return INF

static func _first_shape(body: CollisionObject2D) -> CollisionShape2D:
	if body == null:
		return null
	for child: Node in body.get_children():
		var shape := child as CollisionShape2D
		if shape and shape.shape and not shape.disabled:
			return shape
	return null

## The waterline a pool drop is falling toward right now (local y), or INF
## when there is none to stop it: no pool, dry, or held back by a shell. A
## lake's drops stop at the point chosen on its plane (_land).
func _surface_under(i: int) -> float:
	if not is_instance_valid(_water[i]):
		return INF
	var water := _water[i] as WaterBody
	var x := global_position.x + _x[i]
	if water.is_lake() or water.is_dry() or water.is_held_out(x):
		return INF
	return water.surface_rest_y() - global_position.y

## Where a drop ends: a dent and a crown on water, a burst on the ground,
## nothing where it only ran out of pulse.
func _land_drop(i: int, on_pool: bool) -> void:
	var at := global_position + Vector2(_x[i], _land[i])
	var lake := is_instance_valid(_water[i]) and (_water[i] as WaterBody).is_lake() and not (_water[i] as WaterBody).is_dry()
	if on_pool or lake:
		var water := _water[i] as WaterBody
		at.y = at.y if lake else minf(water.surface_y(at.x), water.surface_rest_y())
		if not (_airflow and _airflow.is_sheltered(at)):
			water.drip(at.x, drip_depth)
			_splashes.spawn(water_splash, at, Vector2.ZERO, splash_color)
	elif _grounded[i] == 1:
		_splashes.spawn(splash, at, Vector2.ZERO, splash_color)
