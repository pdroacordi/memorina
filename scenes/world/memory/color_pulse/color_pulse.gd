class_name ColorPulse extends Node2D

## A song pulse drives its memory source, receiver area, timeline, particles, and optional effect.

## Group used to find live pulses, including by Solstice effects.
const GROUP := &"color_pulse"

## PulseEmitter body, used by performer-specific effects; set before start().
var performer: Node2D
## Whether its clock and particles stop during pause; its node remains PROCESS_MODE_ALWAYS. Set before start().
var holds_in_pause := false

@onready var _source: MemorySource = $Source
@onready var _area: SongArea = $SongArea
@onready var _shape: CollisionShape2D = $SongArea/CollisionShape2D

var _timeline: PulseTimeline
var _particles: CPUParticles2D
var _song: Song
var _acts := true

## Every live pulse of `song_id` in the tree `node` belongs to.
static func lit(node: Node, song_id: Enums.Song) -> Array[ColorPulse]:
	var found: Array[ColorPulse] = []
	for member: Node in node.get_tree().get_nodes_in_group(GROUP):
		var pulse := member as ColorPulse
		if pulse and pulse.acts() and pulse.song() and pulse.song().id == song_id:
			found.append(pulse)
	return found

func _enter_tree() -> void:
	add_to_group(GROUP)

## Starts the pulse; optional stats override its timeline and with_effect disables song actions.
func start(song: Song, stats: PulseStats = null, with_effect: bool = true) -> void:
	_source.tint = song.tint()
	_source.season = song.season()
	_source.radius = 0.0
	_area.song = song
	_song = song
	_acts = with_effect
	# A pulse that does not act (a guardian's lesson or answer: the song
	# remembered, not played) reaches no receiver either - the Frost Guardian's
	# lesson must not freeze its own arena's water.
	_area.monitorable = with_effect
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

## Whether this pulse runs its song effect and triggers world responses; see PulseEmitter.song_acts.
func acts() -> bool:
	return _acts

## Current gameplay radius uses the clean disc; see docs/design/02_mecanicas.md section 7.3.
func radius() -> float:
	return maxf(_timeline.radius(), 0.0) if _timeline else 0.0

## Extends reach and duration once; see PulseTimeline.stretch.
func stretch(reach: float, duration: float) -> bool:
	return _timeline != null and _timeline.stretch(reach, duration)

func is_stretched() -> bool:
	return _timeline != null and _timeline.is_stretched()

## Maximum reach, stretched or not.
func max_radius() -> float:
	return _timeline.max_radius() if _timeline else 0.0

func phase() -> PulseTimeline.Phase:
	return _timeline.phase if _timeline else PulseTimeline.Phase.DONE

func contains(global_point: Vector2) -> bool:
	return global_point.distance_to(global_position) <= radius()

func _apply_radius() -> void:
	var reach := radius()
	_source.radius = reach
	# Scale feather with radius so edge softness remains proportional while contracting.
	_source.feather = reach * MemoryFieldMath.DEFAULT_FEATHER_RATIO
	var circle: CircleShape2D = _shape.shape
	circle.radius = maxf(reach, 0.01)
