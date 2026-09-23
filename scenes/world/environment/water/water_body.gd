@tool
class_name WaterBody extends Node2D

## A body of water: the one node a level places and the one other systems talk
## to. It composes whatever it finds under it - a Surface always, a Veil and a
## Volume when the water is one bodies can enter - so a decorative strip and a
## pool are the same script with different children, never a flag.
##
## Every frame it reads the memory field over each column, steps the surface
## (WaterSurfaceField), and hands the result to the shaders as a 1xN texture.
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
## seconds; reading it every frame for every column is wasted work.
const RATE_REFRESH_FRAMES := 3
## Columns between two samples of the field; those between are interpolated.
const RATE_STRIDE := 4

@export var size := Vector2i(192, 24):
	set(value):
		size = value
		_layout()
## World pixels from the rest line to the mirror axis; negative is above the
## water. For water lying below a bank `b` pixels tall, -b/2 puts the axis
## halfway up it: the first row of water then mirrors the top of the bank, so
## the bank itself is skipped and what stands on it sits close to the water.
@export var mirror_axis_offset := 0
@export var profile: WaterProfile
@export var look: WaterLook

var _field: WaterSurfaceField
var _texture: WaterSurfaceTexture
var _rates := PackedFloat32Array()
var _solidity := PackedFloat32Array()
var _time := 0.0
var _frames_until_rates := 0
var _memory: MemoryField
var _materials: Array[ShaderMaterial] = []

@onready var _surface: WaterQuad = $Surface
@onready var _veil: WaterQuad = get_node_or_null("Veil")
@onready var _volume: WaterVolume = get_node_or_null("Volume")
@onready var _notifier: VisibleOnScreenNotifier2D = get_node_or_null("Notifier")

func _ready() -> void:
	_layout()
	if Engine.is_editor_hint():
		return
	assert(profile != null and look != null, "%s needs a WaterProfile and a WaterLook" % name)
	assert(global_position == global_position.round(), "Water must sit on whole pixels: %s" % name)
	assert(is_zero_approx(global_rotation) and global_scale.is_equal_approx(Vector2.ONE),
		"Water is mirrored in world space and must not be rotated or scaled: %s" % name)
	assert(size.x % 2 == 0, "The origin is the centre of the waterline, so the width must be even")
	var columns := ceili(float(size.x) / float(profile.column_width))
	_field = WaterSurfaceField.new(columns, profile)
	_texture = WaterSurfaceTexture.new(columns)
	_rates.resize(columns)
	_solidity.resize(columns)
	_memory = MemoryField.find_in(self)
	for quad: WaterQuad in [_surface, _veil]:
		if quad:
			# Each body tunes its own uniforms, so it owns its own materials.
			quad.material = quad.material.duplicate()
			_materials.append(quad.material)
	if _volume:
		_volume.min_speed = profile.splash_min_speed
		var shape := RectangleShape2D.new()
		shape.size = Vector2(size)
		var body_shape := _volume.get_node("Shape") as CollisionShape2D
		body_shape.shape = shape
		body_shape.position = Vector2(0.0, size.y * 0.5)
	_push_look()
	_refresh_rates()
	_upload()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _field == null:
		return
	# The rates are read even off screen: FREEZE's ice is never gated, and a
	# pulse can reach a pool before the camera does - ice grown on rates read
	# when it was last seen would ignore the memory it is spreading over.
	_frames_until_rates -= 1
	if _frames_until_rates <= 0:
		_refresh_rates()
	if _notifier and not _notifier.is_on_screen():
		return
	var fastest := 0.0
	for rate: float in _rates:
		fastest = maxf(fastest, rate)
	# The water's own clock - the swell, the reflection's bands, the caustics -
	# stops only where the whole body is forgotten.
	_time += delta * fastest
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

func column_of(world_x: float) -> int:
	var left := global_position.x - size.x * 0.5
	return clampi(floori((world_x - left) / profile.column_width), 0, column_count() - 1)

## The memory over each column, as last read: the rate its time runs at.
func column_rates() -> PackedFloat32Array:
	return _rates

## A body fell in at `world_x` at `speed` pixels per second: the water dents
## under it and a crest rises either side. Wired from the Volume in the scene.
func splash(world_x: float, speed: float) -> void:
	var depth := minf(speed * profile.splash_depth_per_speed, profile.splash_max_depth)
	var centre := column_of(world_x)
	_field.disturb(centre, -depth)
	for k in range(1, profile.splash_half_width + 1):
		var rise := depth * 0.5 * (1.0 - float(k - 1) / float(profile.splash_half_width))
		_field.disturb(centre - k, rise)
		_field.disturb(centre + k, rise)

## How much of a column ice has taken, 0..1 (see WaterSurfaceField.set_hold).
func set_hold(column: int, hold: float) -> void:
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

func _refresh_rates() -> void:
	_frames_until_rates = RATE_REFRESH_FRAMES
	var count := column_count()
	if _memory == null:
		_rates.fill(1.0)
		return
	var left := global_position.x - size.x * 0.5
	var y := surface_rest_y()
	var previous := 0
	var previous_rate := _memory.sample(Vector2(left + profile.column_width * 0.5, y))
	_rates[0] = previous_rate
	var column := RATE_STRIDE
	while previous < count - 1:
		column = mini(column, count - 1)
		var rate := _memory.sample(Vector2(left + (column + 0.5) * profile.column_width, y))
		for i in range(previous + 1, column + 1):
			_rates[i] = lerpf(previous_rate, rate, float(i - previous) / float(column - previous))
		previous = column
		previous_rate = rate
		column += RATE_STRIDE

func _upload() -> void:
	_texture.write(_field, _solidity)
	_set_uniform(&"water_time", _time)

func _push_look() -> void:
	var common := {
		&"surface_data": _texture.texture,
		&"rest_y": surface_rest_y(),
		&"body_left": global_position.x - size.x * 0.5,
		&"column_width": profile.column_width,
		&"depth_band_px": look.depth_band_px,
		&"transmit_ramp": look.transmit_ramp,
	}
	for key: StringName in common:
		_set_uniform(key, common[key])
	var surface := _surface.material as ShaderMaterial
	surface.set_shader_parameter(&"body_ramp", look.body_ramp)
	surface.set_shader_parameter(&"reflection_ramp", look.reflection_ramp)
	surface.set_shader_parameter(&"ice_ramp", look.ice_ramp)
	surface.set_shader_parameter(&"top_line_color", look.top_line_color)
	surface.set_shader_parameter(&"foam_color", look.foam_color)
	surface.set_shader_parameter(&"mirror_axis_offset", float(mirror_axis_offset))
	surface.set_shader_parameter(&"reflection_strength", look.reflection_strength)
	surface.set_shader_parameter(&"reflect_levels", look.reflect_levels)
	surface.set_shader_parameter(&"reflect_memory_low", look.reflect_memory_low)
	surface.set_shader_parameter(&"reflect_memory_high", look.reflect_memory_high)
	surface.set_shader_parameter(&"band_height", look.band_height)
	surface.set_shader_parameter(&"band_shift_max", float(look.band_shift_max))
	surface.set_shader_parameter(&"band_speed", look.band_speed)
	surface.set_shader_parameter(&"edge_fade_px", look.edge_fade_px)
	surface.set_shader_parameter(&"caustic_depth", look.caustic_depth)
	surface.set_shader_parameter(&"caustic_band_px", look.caustic_band_px)
	surface.set_shader_parameter(&"caustic_rate", look.caustic_rate)
	surface.set_shader_parameter(&"caustic_density", look.caustic_density)
	surface.set_shader_parameter(&"caustic_strength", look.caustic_strength)

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
