class_name ColorPulse extends Node2D

## A song, made visible and physical for a few seconds.
##
## Composes rather than extends: a MemorySource child gives it its effect on
## the world's colour, season and time, a SongArea child gives it its reach for
## receivers, a PulseTimeline gives it its shape over time, and the season's
## own particle scene (if any) is mounted under it. The pulse itself only
## drives the radius those agree on and then frees itself.

@onready var _source: MemorySource = $Source
@onready var _area: SongArea = $SongArea
@onready var _shape: CollisionShape2D = $SongArea/CollisionShape2D

var _timeline: PulseTimeline
var _particles: CPUParticles2D

## Called by whoever spawned it, immediately after it enters the tree.
func start(song: Song) -> void:
	_source.tint = song.tint()
	_source.season = song.season()
	_source.radius = 0.0
	_area.song = song
	if song.palette.pulse_particles:
		_particles = song.palette.pulse_particles.instantiate() as CPUParticles2D
		assert(_particles != null, "SeasonPalette.pulse_particles must be a CPUParticles2D scene.")
		add_child(_particles)
	# Sampled once, excluding this pulse's own light, so the pulse is judged
	# against the world it arrived in rather than against itself. Re-sampling
	# every frame would make a pulse prop itself up.
	var local_memory := 1.0
	var field := MemoryField.find_in(self)
	if field:
		local_memory = field.sample(global_position, _source)
	_timeline = PulseTimeline.new(song.pulse_stats, local_memory)
	_apply_radius()

func _physics_process(delta: float) -> void:
	if _timeline == null:
		return
	_timeline.advance(delta)
	if _timeline.is_finished():
		queue_free()
		return
	_apply_radius()
	_source.ring = _timeline.ring()
	# Once the grey starts reclaiming, no new snow: what is already falling is
	# clipped away by the mask as the edge passes over it.
	if _particles and _timeline.phase == PulseTimeline.Phase.CONTRACT:
		_particles.emitting = false

func _apply_radius() -> void:
	var radius: float = maxf(_timeline.radius(), 0.0)
	_source.radius = radius
	# A pulse's edge scales with the pulse, unlike an authored zone whose
	# feather is a fixed pixel width. Contracting light should keep the same
	# proportion of softness the whole way down.
	_source.feather = radius * MemoryFieldMath.DEFAULT_FEATHER_RATIO
	var circle: CircleShape2D = _shape.shape
	circle.radius = maxf(radius, 0.01)
