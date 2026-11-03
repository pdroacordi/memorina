class_name MusicMix
extends RefCounted
## Stem levels moving toward their targets and the named ducks of the Music bus, stepped on real time.

## Volume of a silent stem, dB.
const SILENT_DB := -80.0
## How fast a duck moves, dB per real second.
const DUCK_RATE := 30.0

## stem -> current level, 0..1.
var _level: Dictionary[StringName, float] = {}
## stem -> target level, 0..1.
var _target: Dictionary[StringName, float] = {}
## stem -> level change per real second.
var _rate: Dictionary[StringName, float] = {}
## duck id -> dB, 0 or below.
var _ducks: Dictionary[StringName, float] = {}
var _duck_db: float = 0.0


## Starts a cue's stems at their starting levels.
func reset(cue: MusicCue) -> void:
	_level.clear()
	_target.clear()
	_rate.clear()
	for stem: StringName in cue.stems:
		_level[stem] = cue.level(stem)
		_target[stem] = cue.level(stem)

## Moves `stem` to `level` (0..1) over `seconds` real seconds; 0 jumps.
func set_stem(stem: StringName, level: float, seconds: float) -> void:
	if not _level.has(stem):
		return
	_target[stem] = clampf(level, 0.0, 1.0)
	if seconds <= 0.0:
		_level[stem] = _target[stem]
		_rate.erase(stem)
	else:
		_rate[stem] = absf(_target[stem] - _level[stem]) / seconds

## Holds the bus `db` lower (negative) while `id` is open; the deepest open duck wins.
func duck(id: StringName, db: float) -> void:
	_ducks[id] = minf(db, 0.0)

func unduck(id: StringName) -> void:
	_ducks.erase(id)

## The dB the open ducks ask for.
func duck_target() -> float:
	var deepest := 0.0
	for db: float in _ducks.values():
		deepest = minf(deepest, db)
	return deepest

## Advances the stem fades and the duck by `delta` real seconds.
func step(delta: float) -> void:
	for stem: StringName in _rate.keys():
		_level[stem] = move_toward(_level[stem], _target[stem], _rate[stem] * delta)
		if is_equal_approx(_level[stem], _target[stem]):
			_rate.erase(stem)
	_duck_db = move_toward(_duck_db, duck_target(), DUCK_RATE * delta)

func level(stem: StringName) -> float:
	return _level.get(stem, 0.0)

## The stem's volume, dB.
func stem_db(stem: StringName) -> float:
	var at := level(stem)
	return SILENT_DB if at <= 0.0 else maxf(linear_to_db(at), SILENT_DB)

## The current duck, dB, 0 or below.
func duck_db() -> float:
	return _duck_db
