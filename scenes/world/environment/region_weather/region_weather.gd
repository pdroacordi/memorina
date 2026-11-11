class_name RegionWeather extends Node2D

## Scales regional weather with the memory sampled at the camera (design 03 sections 5.1-5.2; docs/knowledge/systems/seasonal-art.md).

## Seconds the sky takes to fade out or in on entering or leaving a room without sky.
const SKY_FADE := 0.5

## Particle count multiplier.
@export_range(0.1, 2.0) var density: float = 1.0
## Alpha and emission-box scale at memory 0.
@export_range(0.0, 1.0) var quiet_alpha: float = 0.22
@export_range(1.0, 6.0) var quiet_spread: float = 3.0
## The region's gust clock, whose drive blows the gust layer sideways.
@export var wind: RegionWind

var _field: MemoryField
var _season: int = -1
var _particles: CPUParticles2D
## The particle scene's authored emission box, to spread from.
var _base_extents: Vector2 = Vector2.ZERO
## The sideways snow of the region's gusts, or null.
var _gust_layer: CPUParticles2D
var _gust_profile: WeatherProfile
## 1 under the sky, 0 under rock or indoors, eased between over SKY_FADE.
var _sky_level: float = 1.0
var _sky_target: float = 1.0
var _seen_room: bool = false

func _ready() -> void:
	_field = MemoryField.find_in(self)

func _process(delta: float) -> void:
	_sky_level = move_toward(_sky_level, _sky_target, delta / SKY_FADE)
	var intensity := Settings.weather_intensity()
	visible = _sky_level > 0.0 and intensity > 0.0
	if _field == null:
		return
	if int(_field.season) != _season or (_particles == null and _field.palette != null):
		_mount(_field.palette)
	var profile := wind.profile() if wind != null else null
	if profile != _gust_profile:
		_mount_gusts(profile)
	if _particles == null and _gust_layer == null:
		return
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		global_position = camera.get_screen_center_position()
	# The clock of the weather is how remembered THIS PLACE is - the region's
	# baseline, less any well of forgetting, plus any pulse lit here. 0 is a sky
	# stopped mid-fall, 1 is the season in full. Sampling rather than reading
	# the baseline is what gives the design's image for free: "dentro do pulso
	# os flocos voltam a cair" (03_mundo_e_ambiente section 5.1).
	var memory := clampf(_field.sample(global_position), 0.0, 1.0)
	if _gust_layer != null:
		var drive := wind.drive()
		if not is_zero_approx(drive):
			_gust_layer.direction = Vector2(signf(drive), _gust_layer.direction.y)
		_gust_layer.speed_scale = memory
		_gust_layer.modulate.a = absf(drive) * _sky_level
	if _particles == null:
		return
	_particles.speed_scale = memory
	# `amount` is never written per frame: it respawns the whole sky (systems/seasonal-art).
	_particles.modulate.a = lerpf(quiet_alpha, 1.0, memory) * intensity * _sky_level
	var extents := _base_extents * lerpf(quiet_spread, 1.0, memory)
	_particles.emission_rect_extents = extents
	# Position the emission band at the screen top; full-screen emitters stay centered.
	var half_height := get_viewport_rect().size.y * 0.5 / maxf(_zoom(), 0.001)
	_particles.position.y = -maxf(half_height - extents.y, 0.0)

## Wired from `Game.room_changed`: no sky indoors or under rock; the first room of a build shows at once.
func on_room_changed(room: Room) -> void:
	_sky_target = 1.0 if room.has_sky() else 0.0
	if not _seen_room:
		_seen_room = true
		_sky_level = _sky_target

## The camera's zoom, so the band sits at the top of what is actually shown.
func _zoom() -> float:
	var camera := get_viewport().get_camera_2d()
	return camera.zoom.y if camera != null else 1.0

func _mount(palette: SeasonPalette) -> void:
	_season = int(_field.season)
	if _particles != null:
		_particles.queue_free()
		_particles = null
	if palette == null or palette.pulse_particles == null:
		return
	_particles = palette.pulse_particles.instantiate() as CPUParticles2D
	assert(_particles != null, "SeasonPalette.pulse_particles must be a CPUParticles2D scene.")
	# The material is shared with every pulse of this season; ours must clip
	# the other way round.
	var material := _particles.material as ShaderMaterial
	if material != null:
		material = material.duplicate() as ShaderMaterial
		material.set_shader_parameter(&"ambient", true)
		_particles.material = material
	_particles.amount = maxi(int(_particles.amount * density), 1)
	_particles.local_coords = false
	_base_extents = _particles.emission_rect_extents
	add_child(_particles)

func _mount_gusts(profile: WeatherProfile) -> void:
	_gust_profile = profile
	if _gust_layer != null:
		_gust_layer.queue_free()
		_gust_layer = null
	if profile == null or profile.gust_particles == null:
		return
	_gust_layer = profile.gust_particles.instantiate() as CPUParticles2D
	assert(_gust_layer != null, "WeatherProfile.gust_particles must be a CPUParticles2D scene.")
	# The snow drives at the profile's wind speed, so a profile is the one place that sets it.
	_gust_layer.initial_velocity_min = profile.speed * 0.9
	_gust_layer.initial_velocity_max = profile.speed * 1.1
	_gust_layer.modulate.a = 0.0
	add_child(_gust_layer)
