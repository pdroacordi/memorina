class_name ColorPulse extends Node2D

## A song, made visible and physical for a few seconds.
##
## Composes rather than extends: a MemorySource child gives it its effect on
## the world's colour, season and time, a SongArea child gives it its reach for
## receivers, a PulseTimeline gives it its shape over time, and the season's
## own particle scene (if any) is mounted under it, and so is the song's own
## PulseEffect (if any). The pulse itself only drives the radius those agree on
## and then frees itself.

## Every live pulse is in this group, so a song that acts on other pulses
## (Solstice) or on what they leave behind (wet earth after Rain) can find them
## without anyone keeping a list.
const GROUP := &"color_pulse"

## Who played the song (the PulseEmitter's body), for an effect that is about
## them - the burned shadow copies their frame. Null for a pulse nobody
## played. Set before start().
var performer: Node2D
## Whether it holds still while the tree is paused (see PulseEmitter). It stays
## PROCESS_MODE_ALWAYS either way - a lesson's pulse must spread under the
## pause - and only its clock and its particles stop. Set before start().
var holds_in_pause := false

@onready var _source: MemorySource = $Source
@onready var _area: SongArea = $SongArea
@onready var _shape: CollisionShape2D = $SongArea/CollisionShape2D

var _timeline: PulseTimeline
var _particles: CPUParticles2D
var _song: Song

## Every live pulse of `song_id` in the tree `node` belongs to.
static func lit(node: Node, song_id: Enums.Song) -> Array[ColorPulse]:
	var found: Array[ColorPulse] = []
	for member: Node in node.get_tree().get_nodes_in_group(GROUP):
		var pulse := member as ColorPulse
		if pulse and pulse.song() and pulse.song().id == song_id:
			found.append(pulse)
	return found

func _enter_tree() -> void:
	add_to_group(GROUP)

## Called by whoever spawned it, immediately after it enters the tree. `stats`
## overrides the song's own shape in time - a lesson's pulse is the same
## song, opened slowly across its whole track. `with_effect` false lights the
## colour without what the song does (a guardian's pulse; see PulseEmitter).
func start(song: Song, stats: PulseStats = null, with_effect: bool = true) -> void:
	_source.tint = song.tint()
	_source.season = song.season()
	_source.radius = 0.0
	_area.song = song
	_song = song
	if song.palette.pulse_particles:
		_particles = song.palette.pulse_particles.instantiate() as CPUParticles2D
		assert(_particles != null, "SeasonPalette.pulse_particles must be a CPUParticles2D scene.")
		add_child(_particles)
		if holds_in_pause:
			_particles.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Sampled once, excluding this pulse's own light, so the pulse is judged
	# against the world it arrived in rather than against itself. Re-sampling
	# every frame would make a pulse prop itself up.
	var local_memory := 1.0
	var field := MemoryField.find_in(self)
	if field:
		local_memory = field.sample(global_position, _source)
	_timeline = PulseTimeline.new(stats if stats != null else song.pulse_stats, local_memory)
	_apply_radius()
	# Mounted last, so the effect's first frame already sees a started pulse.
	if song.pulse_effect and with_effect:
		var effect := song.pulse_effect.instantiate() as PulseEffect
		assert(effect != null, "Song.pulse_effect must be a PulseEffect scene.")
		effect.pulse = self
		add_child(effect)

func _physics_process(delta: float) -> void:
	if _timeline == null or (holds_in_pause and get_tree().paused):
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

func song() -> Song:
	return _song

## The pulse's current reach. The CLEAN disc: gameplay never asks where the
## dithered edge happened to fall (docs/design/02_mecanicas.md section 7.3).
func radius() -> float:
	return maxf(_timeline.radius(), 0.0) if _timeline else 0.0

func phase() -> PulseTimeline.Phase:
	return _timeline.phase if _timeline else PulseTimeline.Phase.DONE

func contains(global_point: Vector2) -> bool:
	return global_point.distance_to(global_position) <= radius()

func _apply_radius() -> void:
	var reach := radius()
	_source.radius = reach
	# A pulse's edge scales with the pulse, unlike an authored zone whose
	# feather is a fixed pixel width. Contracting light should keep the same
	# proportion of softness the whole way down.
	_source.feather = reach * MemoryFieldMath.DEFAULT_FEATHER_RATIO
	var circle: CircleShape2D = _shape.shape
	circle.radius = maxf(reach, 0.01)
