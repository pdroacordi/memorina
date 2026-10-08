class_name RainBasin extends Node

## Raises a painted WaterBody from its rest to its painted reach under a RAIN pulse; frozen, it only drains (docs/design/02_mecanicas.md section 7.1; docs/design/03_mundo_e_ambiente.md section 6.5).

## Seconds to rise from rest to the reach at memory 1.
@export var fill_time := 3.0
## Seconds to sink from the reach to rest at memory 1.
@export var drain_time := 4.0

var _full_y := 0.0
var _rest_y := 0.0
var _level := 0.0
var _target := 0.0

@onready var _water: WaterBody = $"../Water"
@onready var _freezable: FreezableWater = get_parent() as FreezableWater
@onready var _receiver: SongReceiver = $"../RainReceiver"
@onready var _receiver_shape: CollisionShape2D = $"../RainReceiver/CollisionShape2D"

func _ready() -> void:
	_full_y = _water.level_range().x
	_rest_y = _water.rest_level()
	# Sized to the full basin before it sinks: the rain must find it at rest.
	_water.fit_area(_receiver_shape, -FreezableWater.RECEIVER_HEADROOM)
	_receiver.song_entered.connect(func(_song: Song, _origin: Vector2) -> void: _target = 1.0)
	_receiver.song_left.connect(func(_song: Song) -> void:
		if not _receiver.is_lit():
			_target = 0.0)
	# Deferred: the FreezableWater above sizes its own receiver from the full
	# water in its _ready, which runs after this one.
	_water.set_level.call_deferred(_rest_y)

## Requires shelter across the whole waterline because exposed sections still receive rain.
func _sheltered() -> bool:
	var airflow := Airflow.find_in(self)
	if airflow == null:
		return false
	var half := _water.size.x * 0.5 - 1.0
	for dx: float in [-half, 0.0, half]:
		if not airflow.is_sheltered(Vector2(_water.global_position.x + dx, _full_y)):
			return false
	return true

## Returns fill from 0 (rest) to 1 (the painted reach).
func level() -> float:
	return _level

func _physics_process(delta: float) -> void:
	# Shelter forces the rain target to zero, draining the basin.
	var target := 0.0 if _sheltered() else _target
	# Ice is a lid: a frozen basin keeps draining under it but never rises.
	if is_equal_approx(_level, target) or (target > _level and _freezable and _freezable.is_frozen()):
		return
	var rates := _water.column_rates()
	var rate := 0.0
	for r: float in rates:
		rate += r
	rate /= maxf(rates.size(), 1.0)
	var time := fill_time if target > _level else drain_time
	_level = move_toward(_level, target, delta * rate / maxf(time, 0.001))
	_water.set_level(lerpf(_rest_y, _full_y, smoothstep(0.0, 1.0, _level)))
