class_name GaleField extends PulseEffect

## Vendaval (Enums.Song.GALE): a gale blowing across its pulse the way Ivo
## faced when the song ended, for as long as the pulse holds (design 02
## section 7.1). It is air like any other - a GaleWind in the Airflow channel -
## so it carries Ivo out of the eye and across a gap, shoves light things and
## enemies, sums with a natural current it is played into, and piles up the
## water it blows over, with no rule for any of those pairs.
##
## Looks like a SONG, not weather (design 03 section 5.3): it lives only inside
## the pulse's colour (its bursts are clipped to the season mask), in the
## season's tint, its gusts curl as they go, and it dies with the pulse - where
## a natural current is uncoloured streaks in layers across the whole screen.

## The air's speed where the gale is strongest, px/s.
@export var speed := 260.0
## Radius of the still eye around the player, px.
@export var eye := 48.0
## Strength while the grey takes the pulse back.
@export_range(0.0, 1.0) var contracting := 0.5
@export var gust: SpriteStrip
@export var dash: SpriteStrip
@export var leaf: SpriteStrip
## Bursts born per second over the part of the pulse on screen.
@export var gusts_per_second := 12.0
@export var dashes_per_second := 90.0
@export var leaves_per_second := 10.0
## How far upwind of the screen bursts may be born, so they fly into view.
@export var upwind_margin := 96.0

var _direction := 1.0
var _debt := Vector3.ZERO
var _tint := Color.WHITE

@onready var _wind: GaleWind = $GaleWind
@onready var _bursts: SpriteBursts = $Bursts

func _ready() -> void:
	var body := pulse.performer as Character
	_direction = -1.0 if body and body.facing < 0 else 1.0
	_wind.eye = eye
	_wind.direction = _direction
	_tint = Color(pulse.song().tint().lightened(0.75), 1.0)
	(_bursts.material as ShaderMaterial).set_shader_parameter(&"season", pulse.song().season())

## +1 when it blows right, -1 left.
func direction() -> float:
	return _direction

func _physics_process(delta: float) -> void:
	var radius := pulse.radius()
	var phase := pulse.phase()
	var strength := contracting if phase == PulseTimeline.Phase.CONTRACT else 1.0
	_wind.radius = radius
	_wind.speed = speed * strength
	if phase == PulseTimeline.Phase.CONTRACT or radius <= eye:
		return
	_debt += Vector3(gusts_per_second, dashes_per_second, leaves_per_second) * delta
	while _debt.x >= 1.0:
		_debt.x -= 1.0
		_spawn(gust, 0.9, _tint, 0.0)
	while _debt.y >= 1.0:
		_debt.y -= 1.0
		_spawn(dash, 1.5, _tint, 0.0)
	while _debt.z >= 1.0:
		_debt.z -= 1.0
		_spawn(leaf, 0.7, Color.WHITE, 30.0)

## A burst somewhere on screen (or just upwind of it) where the gale blows
## hard enough to carry it, flying with the air at `pace` of its speed.
func _spawn(strip: SpriteStrip, pace: float, color: Color, flutter: float) -> void:
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	view = view.grow_side(SIDE_LEFT if _direction > 0.0 else SIDE_RIGHT, upwind_margin)
	var point := view.position + Vector2(randf(), randf()) * view.size
	var air := _wind.wind_at(point)
	if absf(air.x) < speed * 0.2:
		return
	var velocity := air * pace + Vector2(0.0, randf_range(-flutter, flutter))
	_bursts.spawn(strip, point, velocity, color, _direction < 0.0)
