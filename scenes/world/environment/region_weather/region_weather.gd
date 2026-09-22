class_name RegionWeather extends Node2D

## A region's weather, scaled by its memory (docs/design/03_mundo_e_ambiente.md
## sections 5.1-5.2): the season's own particles - petals, snow, leaves -
## falling across the screen in full where the region remembers itself
## (baseline 1.0), thinning as it forgets, and hanging in the air, stopped,
## where it is gone (baseline 0). "O clima existe em todo lugar, mas fica
## congelado no cinza." Restoring a guardian is what brings it back to life.
##
## The particle scene is the same one a pulse of that season mounts inside
## itself, wearing the same shader but with `ambient` set: it shows wherever
## no pulse has swapped the art, and inside pulses of its own season. Follows
## the camera so the sky is always full; reads MemoryField every frame and
## holds no state of its own beyond which season it is currently showing.
## PROCESS_MODE_ALWAYS in the scene: the weather waking up is part of the
## lesson, and the lesson runs through a pause.

## How many particles the scene's own `amount` becomes at full memory. Below
## 1.0 keeps the sky from reading as a blizzard on every region.
@export_range(0.1, 2.0) var density: float = 1.0

var _field: MemoryField
var _season: int = -1
var _particles: CPUParticles2D

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
	# The clock of the weather is the region's memory: 0 is a sky stopped
	# mid-fall, 1 is the season in full.
	_particles.speed_scale = _field.baseline

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
	add_child(_particles)
