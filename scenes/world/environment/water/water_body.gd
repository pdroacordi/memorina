@tool
class_name WaterBody extends Node2D

## A body of water: the one node other systems talk to (a level paints it with
## a WaterLayer, which places these). It composes whatever it finds under it -
## a Surface always; a Veil, a Volume and a Hazard when the water is one bodies
## can fall into - so what a body of water does is decided by its scene.
##
## It reads the memory field over each column (every few frames), steps the
## surface (WaterSurfaceField) and hands the result to the shaders as a 1xN
## texture.
##
## TWO PROJECTIONS. A pool in a pit is seen EDGE-ON: its waterline is a profile
## that waves and splashes, so it has a `profile` and simulates one. A lake in
## front of the land is seen FROM ABOVE: its top edge is the far shore and
## stays straight, and its waves are drawn by the shader. It has no `profile`
## and simulates nothing - the widest water is the cheapest - but each of its
## columns keeps its own clock, running at the memory over it, because a lake
## runs the width of a room and one clock for all of it would keep the grey end
## moving at the pace of the remembered one.
##
## Motion is TIME: this node is pausable, so a performance or a lesson stops
## the water with the world. The reflection is MEMORY: the shader reads it from
## the season mask, which runs through a pause - so a lesson that returns colour
## returns the reflection while the waves hold still.
##
## ORIGIN: the centre of the rest waterline. `size` is the water below it; the
## quads draw HEADROOM rows above as well, for crests to rise into.
##
## THE LEVEL CAN MOVE (set_level, driven by Chuva's RainBasin): the body is
## painted at its HIGHEST level and can sink to dry. Moving it moves the origin,
## so everything that reads surface_rest_y() follows; the floors keep their
## world height, so the water gets shallower over the same stepped bed and a
## column whose floor is above the level is simply dry.

## Rows above the rest line the quads draw, so a crest has somewhere to rise.
const HEADROOM := 12
## Physics frames between two readings of the memory field. Memory changes over
## seconds; reading it every frame for every column is wasted work. Read while
## on screen, and on demand (column_rates()) by whoever needs it off screen.
const RATE_REFRESH_FRAMES := 3
## Columns between two samples of the field; those between are interpolated.
const RATE_STRIDE := 4
## Column width of a body with no profile (a lake): it only reads memory and
## keeps a clock per column, so one painted cell (WaterLayer) is one column.
const PLANE_COLUMN_WIDTH := 16
## Every body of water at runtime, for what looks for the water under a point
## (a floating log, the rain).
const GROUP := &"water_body"
## Marks a shape fit_area() made, which it may resize in place.
const FITTED := &"water_fitted"
## Discs the water can be held out of at once (the shaders' array size).
const MAX_HELD := 4
## Pixels between the points of the hazard's outline around a held disc.
const HAZARD_STEP := 4.0
## Thinner water than this under a held disc takes no one.
const HAZARD_MIN_DEPTH := 3.0

@export var size := Vector2i(192, 24):
	set(value):
		size = value
		_layout()
## World pixels from the rest line to the mirror axis; negative is above the
## water. For water lying below a bank `b` pixels tall, -b/2 puts the axis
## halfway up it: the first row of water then mirrors the top of the bank, so
## the bank itself is skipped and what stands on it sits close to the water.
@export var mirror_axis_offset := 0
## How the surface moves. None for a lake seen from above, which has no
## waterline profile to move.
@export var profile: WaterProfile
@export var look: WaterLook
## World pixels below the rest line where the water TAKES a body (the Hazard
## begins): enough that a fall visibly goes in before the beat, never so much
## that standing on ice at the surface counts as being in the water.
@export var hazard_depth := 4.0

var _field: WaterSurfaceField
var _texture: WaterSurfaceTexture
var _rates := PackedFloat32Array()
## The air's horizontal speed over each column (Airflow), refreshed with _rates.
var _winds := PackedFloat32Array()
var _solidity := PackedFloat32Array()
var _floors := PackedFloat32Array()
# A stepped floor handed in before _ready (see set_floor): depth in world
# pixels below the rest line, one per span of _floor_span px from the left.
var _floor_spans := PackedFloat32Array()
var _floor_span := 0.0
var _time := 0.0
# A lake's clock per column (see TWO PROJECTIONS); empty for a pool.
var _clocks := PackedFloat32Array()
var _rates_frame := -RATE_REFRESH_FRAMES
var _memory: MemoryField
var _airflow: Airflow
var _materials: Array[ShaderMaterial] = []
# The level range (world y): painted top, deepest floor. And each column's
# floor as a world height, so a moved level keeps the bed where it was.
var _top_y := 0.0
var _bottom_y := 0.0
var _floor_bottoms := PackedFloat32Array()
var _mirror_top := 0
# Discs the water is held out of (Redoma's shells), by holder, and which
# columns have their waterline inside one.
var _held_out := {}
var _dry := PackedByteArray()
# The hazard's outlines while a disc is held out, reused as the water moves.
var _outlines: Array[CollisionPolygon2D] = []

@onready var _surface: WaterQuad = $Surface
@onready var _veil: WaterQuad = get_node_or_null("Veil")
@onready var _volume: WaterVolume = get_node_or_null("Volume")
@onready var _hazard: HazardZone = get_node_or_null("Hazard")
@onready var _notifier: VisibleOnScreenNotifier2D = get_node_or_null("Notifier")

func _ready() -> void:
	_layout()
	if Engine.is_editor_hint():
		return
	assert(look != null, "%s needs a WaterLook" % name)
	# The veil reads r as the waterline's height and the volume splashes the
	# field: both need a surface that moves.
	assert(profile != null or (_volume == null and _veil == null),
		"%s: water bodies can stand in needs a WaterProfile" % name)
	assert(global_position == global_position.round(), "Water must sit on whole pixels: %s" % name)
	assert(is_zero_approx(global_rotation) and global_scale.is_equal_approx(Vector2.ONE),
		"Water is mirrored in world space and must not be rotated or scaled: %s" % name)
	assert(size.x % 2 == 0, "The origin is the centre of the waterline, so the width must be even")
	var columns := ceili(float(size.x) / float(column_width()))
	if profile:
		_field = WaterSurfaceField.new(columns, profile)
	else:
		_clocks.resize(columns)
	_texture = WaterSurfaceTexture.new(columns)
	_rates.resize(columns)
	_winds.resize(columns)
	_solidity.resize(columns)
	_build_floors(columns)
	add_to_group(GROUP)
	_top_y = global_position.y
	_bottom_y = _top_y + size.y
	_floor_bottoms = _floors.duplicate()
	for column in _floor_bottoms.size():
		_floor_bottoms[column] += _top_y
	_mirror_top = mirror_axis_offset
	_dry.resize(columns)
	_memory = MemoryField.find_in(self)
	_airflow = Airflow.find_in(self)
	for quad: WaterQuad in [_surface, _veil]:
		if quad:
			# Each body tunes its own uniforms, so it owns its own materials.
			quad.material = quad.material.duplicate()
			_materials.append(quad.material)
	if _volume:
		_volume.min_speed = profile.splash_min_speed
		fit_area(_volume.get_node("Shape") as CollisionShape2D, 0.0)
	if _hazard:
		fit_area(_hazard.get_node("Shape") as CollisionShape2D, hazard_depth)
	_push_look()
	_refresh_rates()
	_upload()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _texture == null:
		return
	if _notifier and not _notifier.is_on_screen():
		return
	_refresh_rates_if_stale()
	var fastest := 0.0
	for rate: float in _rates:
		fastest = maxf(fastest, rate)
	# The water's own clock - the swell, the reflection's bands, the caustics -
	# stops only where the whole body is forgotten.
	_time += delta * fastest
	_set_uniform(&"water_time", _time)
	if _field == null:
		for column in _clocks.size():
			_clocks[column] += delta * _rates[column]
	else:
		_wade(delta)
		_blow(delta)
		_field.step(delta, _rates, _time)
	_upload()

## The world y of the waterline at rest. The single source every part of the
## water reads - the shader, the veil, the volume, the ice - so a water level
## that moves later moves everything with it.
func surface_rest_y() -> float:
	return global_position.y

## The body under `point` at runtime: the one whose columns span its x and
## whose level range (painted top to deepest floor) holds its y. Null if none.
static func at(node: Node, point: Vector2) -> WaterBody:
	for member: Node in node.get_tree().get_nodes_in_group(GROUP):
		var body := member as WaterBody
		if body and body.contains_x(point.x):
			var levels := body.level_range()
			if point.y >= levels.x - 1.0 and point.y <= levels.y + 1.0:
				return body
	return null

## The world y of the waterline at `world_x`, with its waves: what floats sits
## on this.
func surface_y(world_x: float) -> float:
	return surface_rest_y() - (_field.height(column_of(world_x)) if _field else 0.0)

func contains_x(world_x: float) -> bool:
	return absf(world_x - global_position.x) <= size.x * 0.5

## (highest level, deepest floor) in world y: the level set_level() moves in.
func level_range() -> Vector2:
	return Vector2(_top_y, _bottom_y)

## No water left anywhere in the body.
func is_dry() -> bool:
	return size.y <= 0

## A lake is seen from above (it has no waterline profile); a pool edge-on.
func is_lake() -> bool:
	return profile == null

## Moves the waterline to `rest_y` (world), rounded to a whole pixel and held
## between the level it was painted at and its deepest floor. The depths, the
## volume, the hazard, the mirror axis and the shaders all follow; a dry body
## hides and stops taking bodies.
func set_level(rest_y: float) -> void:
	var y := clampf(roundf(rest_y), _top_y, _bottom_y)
	if is_equal_approx(y, global_position.y):
		return
	global_position.y = y
	size = Vector2i(size.x, roundi(_bottom_y - y))
	# Which columns have their waterline in a shell's disc: the line has moved.
	_refresh_dry()
	_apply_floors()
	# The bank above the water grows as it sinks; the axis stays halfway up it.
	mirror_axis_offset = _mirror_top - floori((y - _top_y) * 0.5)
	var dry := is_dry()
	for quad: WaterQuad in [_surface, _veil]:
		if quad:
			quad.visible = not dry
	if _volume:
		var volume_shape := _volume.get_node("Shape") as CollisionShape2D
		fit_area(volume_shape, 0.0)
		volume_shape.set_deferred(&"disabled", dry)
	_refit_hazard()
	_set_uniform(&"rest_y", y)
	_set_uniform(&"mirror_axis_offset", float(mirror_axis_offset))
	_upload()

func column_count() -> int:
	return _rates.size()

func column_width() -> int:
	return profile.column_width if profile else PLANE_COLUMN_WIDTH

func column_of(world_x: float) -> int:
	var left := global_position.x - size.x * 0.5
	return clampi(floori((world_x - left) / column_width()), 0, column_count() - 1)

## The memory over each column: the rate its time runs at. Read afresh when
## stale, even off screen - FREEZE's ice is never gated, and a pulse can reach
## a pool before the camera does; ice grown on rates read when the pool was
## last seen would ignore the memory it is spreading over.
func column_rates() -> PackedFloat32Array:
	_refresh_rates_if_stale()
	return _rates

## Sizes a rectangle area to the water, from `top` world pixels below the rest
## line (negative reaches above it) down to the bottom, across the full width.
## Everything that must cover this body - its volume, its hazard, a song
## receiver - is fitted here, in a shape of its own (never shared between
## bodies of different sizes). A shape this has already fitted is resized in
## place, so a level moving every frame (set_level) allocates nothing.
func fit_area(area_shape: CollisionShape2D, top: float) -> void:
	var rect := area_shape.shape as RectangleShape2D
	if rect == null or not rect.has_meta(FITTED):
		rect = RectangleShape2D.new()
		rect.set_meta(FITTED, true)
		area_shape.shape = rect
	rect.size = Vector2(size.x, maxf(size.y - top, 1.0))
	area_shape.global_position = global_position + Vector2(0.0, top + rect.size.y * 0.5)

## A body fell in at `world_x` at `speed` pixels per second: the water dents
## under it and a crest rises either side. Wired from the Volume in the scene.
##
## The shape is a smooth "Mexican hat" (a Ricker wavelet) several columns wide,
## never a one-column notch: a notch is almost all zig-zag, which the springs
## ring as a comb of teeth instead of a crest (docs/knowledge/bugs/
## splash-rings-the-alternating-column-mode.md).
func splash(world_x: float, speed: float) -> void:
	assert(_field != null, "%s has no surface to splash: it has no WaterProfile" % name)
	var depth := minf(speed * profile.splash_depth_per_speed, profile.splash_max_depth)
	var centre := column_of(world_x)
	if _dry.size() > centre and _dry[centre] == 1:
		return
	var width := float(profile.splash_half_width)
	for k in range(-3 * profile.splash_half_width, 3 * profile.splash_half_width + 1):
		var x := float(k) / width
		_field.disturb(centre + k, -depth * (1.0 - 2.0 * x * x) * exp(-x * x))

## Holds the water out of a disc (Redoma's shell, design 02 section 7.1): no
## water inside it, pixel for pixel - the water stands against the curve with
## its lighter line along it, and the hazard's outline follows the same curve
## - until the disc shrinks off it or `holder` lets go. A radius of 0 lets go.
## A lake is never held out: it is seen from above, lying in front of the
## land, and a hole cut in it reads as the water vanishing, not standing back.
func hold_out(holder: Object, centre: Vector2, radius: float) -> void:
	if is_lake():
		return
	var key := holder.get_instance_id()
	if radius <= 0.0:
		release(holder)
		return
	var disc := Vector3(centre.x, centre.y, radius)
	if _held_out.get(key, Vector3.ZERO) == disc:
		return
	assert(_held_out.has(key) or _held_out.size() < MAX_HELD, "%s: more held discs than the shaders take" % name)
	_held_out[key] = disc
	_held_changed()

func release(holder: Object) -> void:
	if _held_out.erase(holder.get_instance_id()):
		_held_changed()

## Whether the waterline at `world_x` is inside a held disc (nothing to splash
## or dent there).
func is_held_out(world_x: float) -> bool:
	return _dry.size() > 0 and _dry[column_of(world_x)] == 1

## A raindrop landing at `world_x`: a small dent `depth` px deep, a few columns
## wide - never a one-column notch, which the springs ring as a comb (see
## splash()).
func drip(world_x: float, depth: float) -> void:
	if _field == null or is_dry():
		return
	var centre := column_of(world_x)
	if _dry[centre] == 1:
		return
	for k in range(-3, 4):
		var x := float(k)
		_field.disturb(centre + k, -depth * (1.0 - 2.0 * x * x) * exp(-x * x))

## Gives the body a stepped floor instead of a flat one at `size.y`: `depths`
## is the water's depth in world pixels below the rest line for each span of
## `span` pixels from the left edge. A painted basin (WaterLayer) calls it
## before the body enters the tree; the shaders clip the water to it.
func set_floor(span: float, depths: PackedFloat32Array) -> void:
	assert(_texture == null, "set_floor() must come before %s enters the tree" % name)
	_floor_span = span
	_floor_spans = depths

## How much of a column ice has taken, 0..1 (see WaterSurfaceField.set_hold).
func set_hold(column: int, hold: float) -> void:
	assert(_field != null, "%s has no surface to hold: it has no WaterProfile" % name)
	_field.set_hold(column, hold)

## How solid the ice over a column looks, 0..1; drawn from the next upload.
func set_solidity(column: int, solidity: float) -> void:
	_solidity[column] = solidity

func set_ice_thickness(pixels: int) -> void:
	_set_uniform(&"ice_thickness", float(pixels))

func _wade(delta: float) -> void:
	if _volume == null:
		return
	for body: Vector2 in _volume.disturbances():
		_field.disturb(column_of(body.x), -body.y * profile.wake_per_speed * delta)

## Moving air drags the surface downwind: every column is pushed in
## proportion to the wind over it and to how far downwind of the body's middle
## it lies, so water piles on the downwind bank and draws off the upwind one.
## The springs pull it back, so a steady wind holds a slope and a dropping one
## lets a crest run.
func _blow(delta: float) -> void:
	if _airflow == null or is_zero_approx(profile.wind_stress):
		return
	var half := maxf((column_count() - 1) * 0.5, 1.0)
	for column in column_count():
		var wind := _winds[column]
		if not is_zero_approx(wind):
			_field.disturb(column, -wind * profile.wind_stress * delta * ((column - half) / half))

func _held_changed() -> void:
	_refresh_dry()
	_push_held()
	_refit_hazard()

## Which columns have their waterline inside a held disc. The disc test is
## the same as wc_held() in water_common.gdshaderinc: change one, change the
## other.
func _refresh_dry() -> void:
	var left := global_position.x - size.x * 0.5
	var width := column_width()
	var line := surface_rest_y()
	var discs: Array = _held_out.values()
	for column in _dry.size():
		var point := Vector2(left + (column + 0.5) * width, line)
		var dry := 0
		for disc: Vector3 in discs:
			if point.distance_to(Vector2(disc.x, disc.y)) < disc.z:
				dry = 1
				break
		_dry[column] = dry

func _push_held() -> void:
	var discs := PackedVector4Array()
	for disc: Vector3 in _held_out.values():
		discs.append(Vector4(disc.x, disc.y, disc.z, 0.0))
	var count := discs.size()
	discs.resize(MAX_HELD)
	_set_uniform(&"held_discs", discs)
	_set_uniform(&"held_count", count)

## Each column's depth: its bed at its world height under the current level.
func _apply_floors() -> void:
	var y := global_position.y
	for column in _floors.size():
		_floors[column] = maxf(_floor_bottoms[column] - y, 0.0)

## The hazard follows the water: one rectangle over the whole body, or - while
## a disc is held out - outlines of the water left around it (one above the
## disc where it lies under the surface, one below it), reused in place.
func _refit_hazard() -> void:
	if _hazard == null:
		return
	var base := _hazard.get_node("Shape") as CollisionShape2D
	fit_area(base, hazard_depth)
	var shallow := size.y <= hazard_depth
	var held := not _held_out.is_empty()
	base.set_deferred(&"disabled", held or shallow)
	var outlines: Array[PackedVector2Array] = []
	if held and not shallow:
		outlines = _wet_outlines()
	while _outlines.size() < outlines.size():
		var outline := CollisionPolygon2D.new()
		outline.name = "Outline%d" % _outlines.size()
		_hazard.add_child(outline)
		_outlines.append(outline)
	for i in _outlines.size():
		var used := i < outlines.size()
		if used:
			_outlines[i].set_deferred(&"polygon", outlines[i])
		_outlines[i].set_deferred(&"disabled", not used)

## The water left around the held discs, as polygons in the hazard's space:
## sampled every HAZARD_STEP px, each sample the water column from
## `hazard_depth` down to the bottom with the discs' span cut out of it.
func _wet_outlines() -> Array[PackedVector2Array]:
	var top := surface_rest_y() + hazard_depth
	var bottom := surface_rest_y() + size.y
	var left := global_position.x - size.x * 0.5
	var samples := maxi(ceili(size.x / HAZARD_STEP), 1)
	var discs: Array = _held_out.values()
	var xs := PackedFloat32Array()
	var uppers := PackedFloat32Array()
	var lowers := PackedFloat32Array()
	for i in samples + 1:
		var x := left + minf(i * HAZARD_STEP, size.x)
		var cut := Vector2(INF, -INF)
		for disc: Vector3 in discs:
			var dx := x - disc.x
			if absf(dx) < disc.z:
				var h := sqrt(disc.z * disc.z - dx * dx)
				cut = Vector2(minf(cut.x, disc.y - h), maxf(cut.y, disc.y + h))
		xs.append(x)
		# Water above the cut (where a disc lies under the surface), and below.
		uppers.append(clampf(cut.x, top, bottom) if cut.x < INF else top)
		lowers.append(clampf(cut.y, top, bottom) if cut.y > -INF else top)
	var outlines: Array[PackedVector2Array] = []
	_bands(xs, PackedFloat32Array(), uppers, top, outlines)
	_bands(xs, lowers, PackedFloat32Array(), bottom, outlines)
	return outlines

## One polygon per run of samples where the band is at least
## HAZARD_MIN_DEPTH deep: its top follows `tops` (or `fixed` when empty), its
## bottom `bottoms` (or `fixed`).
func _bands(xs: PackedFloat32Array, tops: PackedFloat32Array, bottoms: PackedFloat32Array, fixed: float, into: Array[PackedVector2Array]) -> void:
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in xs.size() + 1:
		var deep := false
		var y_top := 0.0
		var y_bottom := 0.0
		if i < xs.size():
			y_top = fixed if tops.is_empty() else tops[i]
			y_bottom = fixed if bottoms.is_empty() else bottoms[i]
			deep = y_bottom - y_top >= HAZARD_MIN_DEPTH
		if deep:
			upper.append(_hazard.to_local(Vector2(xs[i], y_top)))
			lower.append(_hazard.to_local(Vector2(xs[i], y_bottom)))
			continue
		if upper.size() >= 2:
			lower.reverse()
			upper.append_array(lower)
			into.append(upper)
		upper = PackedVector2Array()
		lower = PackedVector2Array()

func _build_floors(columns: int) -> void:
	_floors.resize(columns)
	_floors.fill(float(size.y))
	if _floor_spans.is_empty():
		return
	var width := float(column_width())
	for column in columns:
		var span := clampi(floori((column + 0.5) * width / _floor_span), 0, _floor_spans.size() - 1)
		_floors[column] = minf(_floor_spans[span], float(size.y))

func _refresh_rates_if_stale() -> void:
	if Engine.get_physics_frames() - _rates_frame >= RATE_REFRESH_FRAMES:
		_refresh_rates()

func _refresh_rates() -> void:
	_rates_frame = Engine.get_physics_frames()
	var count := column_count()
	if _memory == null:
		_rates.fill(1.0)
		return
	var left := global_position.x - size.x * 0.5
	var width := column_width()
	var y := surface_rest_y()
	_refresh_winds(left, width, y)
	var previous := 0
	var previous_rate := _memory.sample(Vector2(left + width * 0.5, y))
	_rates[0] = previous_rate
	var column := RATE_STRIDE
	while previous < count - 1:
		column = mini(column, count - 1)
		var rate := _memory.sample(Vector2(left + (column + 0.5) * width, y))
		for i in range(previous + 1, column + 1):
			_rates[i] = lerpf(previous_rate, rate, float(i - previous) / float(column - previous))
		previous = column
		previous_rate = rate
		column += RATE_STRIDE

## The air a few pixels above the waterline, sampled every RATE_STRIDE columns
## and held between them. Airflow already scales it by memory.
func _refresh_winds(left: float, width: int, y: float) -> void:
	if _airflow == null:
		_winds.fill(0.0)
		return
	var wind := 0.0
	for column in column_count():
		if column % RATE_STRIDE == 0:
			wind = _airflow.sample(Vector2(left + (column + 0.5) * width, y - 4.0)).x
		_winds[column] = wind

func _upload() -> void:
	_texture.write(_field, _clocks, _floors, _solidity)

func _push_look() -> void:
	var placement := {
		&"surface_data": _texture.texture,
		&"rest_y": surface_rest_y(),
		&"body_left": global_position.x - size.x * 0.5,
		&"column_width": column_width(),
		&"mirror_axis_offset": float(mirror_axis_offset),
	}
	for key: StringName in placement:
		_set_uniform(key, placement[key])
	# Every WaterLook property is named after the uniform it feeds, so each
	# material takes exactly the ones its shader declares: the pool never sees
	# the lake's, the veil only its ramp and bands.
	for material: ShaderMaterial in _materials:
		for uniform: Dictionary in material.shader.get_shader_uniform_list():
			var value: Variant = look.get(uniform[&"name"])
			if value != null:
				material.set_shader_parameter(uniform[&"name"], value)

func _set_uniform(uniform: StringName, value: Variant) -> void:
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter(uniform, value)

func _layout() -> void:
	if not is_inside_tree():
		return
	var rect := Rect2(-size.x * 0.5, -HEADROOM, size.x, size.y + HEADROOM)
	for child: Node in get_children():
		if child is WaterQuad:
			(child as WaterQuad).rect = rect
		elif child is VisibleOnScreenNotifier2D and (child as VisibleOnScreenNotifier2D).rect != rect:
			# Only on change: in the editor an unconditional write resaves every
			# level that places water.
			(child as VisibleOnScreenNotifier2D).rect = rect
