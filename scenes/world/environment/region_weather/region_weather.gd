class_name RegionWeather extends Node2D

## A region's weather, scaled by its memory (docs/design/03_mundo_e_ambiente.md
## sections 5.1-5.2): the season's own particles - petals, snow, leaves -
## falling across the screen in full where the place remembers itself (memory
## 1.0), thinning as it forgets, and hanging in the air, stopped, where it is
## gone. The value is the field SAMPLED where the camera looks, so a well of
## forgetting stills the sky above it and a pulse makes the flakes fall again
## inside itself, exactly as the design asks. "O clima existe em todo lugar, mas fica
## congelado no cinza." Restoring a guardian is what brings it back to life.
##
## The particle scene is the same one a pulse of that season mounts inside
## itself, wearing the same shader but with `ambient` set: it shows wherever
## no pulse has swapped the art, and inside pulses of its own season. Follows
## the camera so the sky is always full; reads MemoryField every frame and
## holds no state of its own beyond which season it is currently showing.
## PROCESS_MODE_ALWAYS in the scene: the weather waking up is part of the
## lesson, and the lesson runs through a pause.
##
## THE GREY MUST STAY EMPTY. A forgotten sky is not a sky full of stopped
## flakes - at any density that registers, speckle reads as static and is
## tiring to look at (see the greyhush rule in CLAUDE.md). So memory drives
## three knobs at once, none of which restarts the emitter (CPUParticles2D has
## no `amount_ratio` in 4.7, and writing `amount` would respawn the whole sky
## mid-lesson): `speed_scale` stops the fall, `modulate.a` takes the contrast
## away, and the emission rectangle is SPREAD WIDER than the screen so the
## same particles are scattered thin and most of them fall outside the frame.

## How many particles the scene's own `amount` becomes. Below 1.0 keeps the
## sky from reading as a blizzard on every region.
@export_range(0.1, 2.0) var density: float = 1.0
## What is left of the weather at memory 0: how visible each flake is, and how
## far the emission box is spread beyond its authored size (bigger = thinner
## on screen). At memory 1.0 both are the scene's own values.
@export_range(0.0, 1.0) var quiet_alpha: float = 0.22
@export_range(1.0, 6.0) var quiet_spread: float = 3.0

var _field: MemoryField
var _season: int = -1
var _particles: CPUParticles2D
## The particle scene's authored emission box, to spread from.
var _base_extents: Vector2 = Vector2.ZERO

func _ready() -> void:
	_field = MemoryField.find_in(self)

func _process(_delta: float) -> void:
	if _field == null:
		return
	if int(_field.season) != _season or (_particles == null and _field.palette != null):
		_mount(_field.palette)
	if _particles == null:
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
	_particles.speed_scale = memory
	_particles.modulate.a = lerpf(quiet_alpha, 1.0, memory)
	var extents := _base_extents * lerpf(quiet_spread, 1.0, memory)
	_particles.emission_rect_extents = extents
	# A sky emitter is a thin band (snow falls FROM somewhere); a screen-sized
	# box is the weather itself (drifting petals). Lift the band to the top of
	# the frame - the node follows the camera CENTRE, so an unlifted band would
	# snow out of thin air at eye level - and leave a full box centred.
	var half_height := get_viewport_rect().size.y * 0.5 / maxf(_zoom(), 0.001)
	_particles.position.y = -maxf(half_height - extents.y, 0.0)

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
