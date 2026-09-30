class_name RainBasin extends Node

## A basin Chuva (Enums.Song.RAIN) fills (design 02 section 7.1, 03 section
## 6.5). It is painted up to where the rain brings the water - the level is
## authored, never computed - and is dry until it rains: while a RAIN pulse
## covers it the water rises to that level, and when the last one has gone it
## sinks back to dry. It rises and sinks at the memory under it, like all water
## (a basin in the grey fills slowly, in a dead place not at all), and holds
## its level while it is frozen - Chuva then Congelar is ice where there was no
## water.
##
## Glue beside the FreezableWater it rides on: the water is a WaterBody, the
## level is WaterBody.set_level, the ice is the FreezableWater's.

## Seconds to rise from dry to full at memory 1.
@export var fill_time := 3.0
## Seconds to sink from full to dry at memory 1.
@export var drain_time := 4.0

var _full_y := 0.0
var _dry_y := 0.0
var _level := 0.0
var _target := 0.0

@onready var _water: WaterBody = $"../Water"
@onready var _freezable: FreezableWater = get_parent() as FreezableWater
@onready var _receiver: SongReceiver = $"../RainReceiver"
@onready var _receiver_shape: CollisionShape2D = $"../RainReceiver/CollisionShape2D"

func _ready() -> void:
	var levels := _water.level_range()
	_full_y = levels.x
	_dry_y = levels.y
	# Sized to the full basin before it dries: the rain must find it empty.
	_water.fit_area(_receiver_shape, -FreezableWater.RECEIVER_HEADROOM)
	_receiver.song_entered.connect(func(_song: Song, _origin: Vector2) -> void: _target = 1.0)
	_receiver.song_left.connect(func(_song: Song) -> void:
		if not _receiver.is_lit():
			_target = 0.0)
	# Deferred: the FreezableWater above sizes its own receiver from the full
	# water in its _ready, which runs after this one.
	_water.set_level.call_deferred(_dry_y)

## How full it is: 0 dry, 1 at its painted level.
func level() -> float:
	return _level

func _physics_process(delta: float) -> void:
	if is_equal_approx(_level, _target) or (_freezable and _freezable.is_frozen()):
		return
	var rates := _water.column_rates()
	var rate := 0.0
	for r: float in rates:
		rate += r
	rate /= maxf(rates.size(), 1.0)
	var time := fill_time if _target > _level else drain_time
	_level = move_toward(_level, _target, delta * rate / maxf(time, 0.001))
	_water.set_level(lerpf(_dry_y, _full_y, smoothstep(0.0, 1.0, _level)))
