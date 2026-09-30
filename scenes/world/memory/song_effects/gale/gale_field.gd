class_name GaleField extends PulseEffect

## Vendaval (Enums.Song.GALE): a radial gale blowing outward from where the
## song was played, for as long as its pulse holds (design 02 section 7.1).
## It is air like any other - a RadialWind in the Airflow channel - so it
## carries Ivo out of the eye and across a gap, shoves light things and
## enemies, sums with a natural current it is played into, and raises the
## water it blows over, with no rule for any of those pairs.
##
## Looks like a SONG, not weather (design 03 section 5.3): radial, in the
## season's colour, racing out to the pulse's contracting edge.

## The air's speed where the gale is strongest, px/s.
@export var speed := 260.0
## Radius of the still eye around the player, px.
@export var eye := 48.0
## Strength while the grey takes the pulse back.
@export_range(0.0, 1.0) var contracting := 0.5

@onready var _wind: RadialWind = $RadialWind
@onready var _streaks: CPUParticles2D = $Streaks
@onready var _leaves: CPUParticles2D = $Leaves

func _ready() -> void:
	_wind.eye = eye
	var tint := pulse.song().tint()
	for emitter: CPUParticles2D in [_streaks, _leaves]:
		emitter.color = tint.lightened(0.35)
		emitter.emission_ring_inner_radius = eye

func _physics_process(_delta: float) -> void:
	var radius := pulse.radius()
	var phase := pulse.phase()
	var strength := contracting if phase == PulseTimeline.Phase.CONTRACT else 1.0
	_wind.radius = radius
	_wind.speed = speed * strength
	for emitter: CPUParticles2D in [_streaks, _leaves]:
		emitter.emission_ring_radius = maxf(radius * 0.6, eye + 1.0)
		emitter.emitting = phase != PulseTimeline.Phase.CONTRACT and radius > eye
	_streaks.lifetime = maxf(radius, 1.0) / (speed * 1.8)
