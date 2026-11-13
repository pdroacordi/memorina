class_name MusicMix
extends RefCounted
## Stem levels moving toward their targets, and the named ducks and muffles of the Music bus, stepped on real time.

## Volume of a silent stem, dB.
const SILENT_DB := -80.0
## How fast a duck moves, dB per real second.
const DUCK_RATE := 30.0
## How fast a muffle moves, amount (0..1) per real second.
const MUFFLE_RATE := 2.0
## The low-pass cutoff with no muffle and at a full one, Hz.
const OPEN_HZ := 20000.0
const MUFFLED_HZ := 400.0

## stem -> current level, 0..1.
var _level: Dictionary[StringName, float] = {}
## stem -> target level, 0..1.
var _target: Dictionary[StringName, float] = {}
## stem -> level change per real second.
var _rate: Dictionary[StringName, float] = {}
## duck id -> dB, 0 or below.
var _ducks: Dictionary[StringName, float] = {}
## duck id -> the instance id of the node it lasts for; absent lasts until unduck.
var _duck_owners: Dictionary[StringName, int] = {}
var _duck_db: float = 0.0
## muffle id -> amount, 0..1.
var _muffles: Dictionary[StringName, float] = {}
## muffle id -> the instance id of the node it lasts for; absent lasts until unmuffle.
var _muffle_owners: Dictionary[StringName, int] = {}
var _muffle: float = 0.0


## Whether the node `owner_id` names still holds what it opened: it exists, is in the tree and is not disabled. A paused
## tree counts as holding, so a pause never closes a duck. An id, since a freed node cannot be passed typed.
static func holds(owner_id: int) -> bool:
	var node := instance_from_id(owner_id) as Node
	if node == null or not node.is_inside_tree():
		return false
	return node.can_process() or node.get_tree().paused


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

## Holds the bus `db` lower (negative) while `id` is open and `owner`, when given, holds; the deepest open duck wins.
func duck(id: StringName, db: float, owner: Node = null) -> void:
	_ducks[id] = minf(db, 0.0)
	_own(_duck_owners, id, owner)

func unduck(id: StringName) -> void:
	_ducks.erase(id)
	_duck_owners.erase(id)

## Low-passes the bus by `amount` (0..1) while `id` is open and `owner`, when given, holds; the strongest open muffle
## wins.
func muffle(id: StringName, amount: float, owner: Node = null) -> void:
	_muffles[id] = clampf(amount, 0.0, 1.0)
	_own(_muffle_owners, id, owner)

func unmuffle(id: StringName) -> void:
	_muffles.erase(id)
	_muffle_owners.erase(id)

## Closes every duck and muffle whose owner no longer holds (MusicMix.holds).
func prune() -> void:
	for id: StringName in _duck_owners.keys():
		if not holds(_duck_owners[id]):
			unduck(id)
	for id: StringName in _muffle_owners.keys():
		if not holds(_muffle_owners[id]):
			unmuffle(id)

## The amount the open muffles ask for, 0..1.
func muffle_target() -> float:
	var strongest := 0.0
	for amount: float in _muffles.values():
		strongest = maxf(strongest, amount)
	return strongest

## The current muffle, 0..1.
func muffle_amount() -> float:
	return _muffle

## The low-pass cutoff for the current muffle, Hz: even steps in pitch from OPEN_HZ to MUFFLED_HZ.
func cutoff_hz() -> float:
	return OPEN_HZ * pow(MUFFLED_HZ / OPEN_HZ, _muffle)

## The dB the open ducks ask for.
func duck_target() -> float:
	var deepest := 0.0
	for db: float in _ducks.values():
		deepest = minf(deepest, db)
	return deepest

## Advances the stem fades, the duck and the muffle by `delta` real seconds.
func step(delta: float) -> void:
	for stem: StringName in _rate.keys():
		_level[stem] = move_toward(_level[stem], _target[stem], _rate[stem] * delta)
		if is_equal_approx(_level[stem], _target[stem]):
			_rate.erase(stem)
	_duck_db = move_toward(_duck_db, duck_target(), DUCK_RATE * delta)
	_muffle = move_toward(_muffle, muffle_target(), MUFFLE_RATE * delta)

func level(stem: StringName) -> float:
	return _level.get(stem, 0.0)

## The stem's volume, dB.
func stem_db(stem: StringName) -> float:
	var at := level(stem)
	return SILENT_DB if at <= 0.0 else maxf(linear_to_db(at), SILENT_DB)

## The current duck, dB, 0 or below.
func duck_db() -> float:
	return _duck_db

func _own(owners: Dictionary[StringName, int], id: StringName, owner: Node) -> void:
	if owner != null:
		owners[id] = owner.get_instance_id()
	else:
		owners.erase(id)
