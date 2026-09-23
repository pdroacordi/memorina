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
var _materials: Array[ShaderMaterial] = []

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
	_solidity.resize(columns)
	_build_floors(columns)
	_memory = MemoryField.find_in(self)
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
		_field.step(delta, _rates, _time)
	_upload()

## The world y of the waterline at rest. The single source every part of the
## water reads - the shader, the veil, the volume, the ice - so a water level
## that moves later moves everything with it.
func surface_rest_y() -> float:
	return global_position.y

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
## bodies of different sizes).
func fit_area(area_shape: CollisionShape2D, top: float) -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, maxf(size.y - top, 1.0))
	area_shape.shape = rect
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
	var width := float(profile.splash_half_width)
	for k in range(-3 * profile.splash_half_width, 3 * profile.splash_half_width + 1):
		var x := float(k) / width
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
