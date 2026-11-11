class_name WeatherGust extends RefCounted

## One region's gust clock: runs at the memory given, eases down in a guardian fight and restarts in a calm
## (architecture/regional-weather-push).

var profile: WeatherProfile

## Profile seconds into the gust cycle.
var _time: float = 0.0
## The fight's multiplier on strength, 0..1.
var _fight_level: float = 1.0
var _fighting: bool = false


func _init(p_profile: WeatherProfile) -> void:
	profile = p_profile

## Back to the start of the calm.
func restart() -> void:
	_time = 0.0

## Advances the clock by `delta` scaled by `memory` (0..1); a fight that ends restarts it.
func step(delta: float, memory: float, fighting: bool) -> void:
	if profile == null:
		return
	_time += delta * clampf(memory, 0.0, 1.0)
	if _fighting and not fighting:
		restart()
	_fighting = fighting
	var target := profile.fight_scale if fighting else 1.0
	if profile.fight_ease <= 0.0:
		_fight_level = target
	else:
		_fight_level = move_toward(_fight_level, target, (1.0 - profile.fight_scale) / profile.fight_ease * delta)

## The gust strength now, fight included, 0..1.
func strength() -> float:
	if profile == null or profile.gusts == null:
		return 0.0
	return profile.gusts.strength(_time) * _fight_level

## Signed air speed along x for `direction` (-1 or 1) and `intensity` (0..1), px/s before memory.
func air(direction: int, intensity: float) -> float:
	if profile == null:
		return 0.0
	return signf(direction) * profile.speed * strength() * clampf(intensity, 0.0, 1.0)
