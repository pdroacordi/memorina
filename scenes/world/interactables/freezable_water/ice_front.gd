class_name IceFront extends RefCounted

## The life of the ice FREEZE lays over a body of water, as pure logic: two
## fronts growing out from where the song was played, each column setting
## behind them, and a thaw front following. Tested without a scene.
##
## GROWTH NEEDS LIVING WATER (design 03 §6.3). The fronts and the setting both
## run at the memory under them, so ice crawls over grey water and stops dead
## where nothing is remembered. No special rule makes that work: the pulse that
## carried the song is what wakes the water, and the ice follows it.
##
## THE THAW IGNORES MEMORY. Once made, the ice keeps its own clock - otherwise
## FREEZE played in a dead place would leave a permanent bridge as soon as the
## pulse contracted, and the timed crossing (design 02, Combinado 1: "começa a
## descongelar assim que criada") would not exist.
##
## Three thresholds, read in order as a column sets:
##   hold      - the surface stops answering (harden_at)
##   solidity  - the ice is drawn solid and carries weight (solid_at)
## so a front visibly calms the water before it looks like ice.

var _profile: IceProfile
var _column_width: float
var _ice := PackedFloat32Array()
var _reached := PackedByteArray()
var _thawed := PackedByteArray()
var _origin := -1
var _left := 0.0
var _right := 0.0
var _elapsed := 0.0

func _init(column_count: int, column_width: int, profile: IceProfile) -> void:
	assert(column_count > 0, "Ice needs at least one column")
	_profile = profile
	_column_width = float(column_width)
	_ice.resize(column_count)
	_reached.resize(column_count)
	_thawed.resize(column_count)

func column_count() -> int:
	return _ice.size()

## Starts (or restarts) the ice at `column`, clamped onto the water - a song
## played from the bank freezes from the nearest edge. Ice already standing is
## kept; only the fronts and the thaw start over.
func freeze_from(column: int) -> void:
	_origin = clampi(column, 0, _ice.size() - 1)
	_left = float(_origin)
	_right = float(_origin)
	_elapsed = 0.0
	_reached.fill(0)
	_thawed.fill(0)
	_reached[_origin] = 1

func is_active() -> bool:
	if _origin < 0:
		return false
	for i in _ice.size():
		if _ice[i] > 0.0 or (_reached[i] == 1 and _thawed[i] == 0):
			return true
	return false

## Advances everything by `delta` seconds. `rates[i]` is the memory over column
## i (0..1, no threshold).
func advance(delta: float, rates: PackedFloat32Array) -> void:
	assert(rates.size() == _ice.size(), "One rate per column")
	if _origin < 0 or delta <= 0.0:
		return
	_elapsed += delta
	_grow_fronts(delta, rates)
	_mark_thawed()
	for i in _ice.size():
		if _thawed[i] == 1:
			_ice[i] = maxf(_ice[i] - delta / _profile.melt_time, 0.0)
		elif _reached[i] == 1:
			_ice[i] = minf(_ice[i] + delta * rates[i] / _profile.crystallise_time, 1.0)

## 0..1: how far the surface has stopped answering. 1 = locked flat.
func hold(column: int) -> float:
	return clampf(_ice[column] / _profile.harden_at, 0.0, 1.0)

## 0..1: how solid the ice looks. 1 = drawn solid and walkable.
func solidity(column: int) -> float:
	return clampf(_ice[column] / _profile.solid_at, 0.0, 1.0)

func is_solid(column: int) -> bool:
	return _ice[column] >= _profile.solid_at

## One byte per collision segment of `columns_per_segment` columns: 1 only while
## EVERY column in it is solid. Conservative on purpose - collision that reaches
## past the ice you can see reads as a bug; ice that drops you a pixel early
## reads as ice.
func solid_segments(columns_per_segment: int) -> PackedByteArray:
	var count := ceili(float(_ice.size()) / float(columns_per_segment))
	var out := PackedByteArray()
	out.resize(count)
	for segment in count:
		var solid := true
		var start := segment * columns_per_segment
		for i in range(start, mini(start + columns_per_segment, _ice.size())):
			if not is_solid(i):
				solid = false
				break
		out[segment] = 1 if solid else 0
	return out

func _grow_fronts(delta: float, rates: PackedFloat32Array) -> void:
	# Each front moves at the memory of the column it is crossing, so a dead
	# column stops it exactly at its edge.
	var step := _profile.grow_speed / _column_width * delta
	var crossing_left := int(ceil(_left)) - 1
	if crossing_left >= 0:
		_left = maxf(_left - step * rates[crossing_left], 0.0)
	var crossing_right := int(floor(_right)) + 1
	if crossing_right < _ice.size():
		_right = minf(_right + step * rates[crossing_right], float(_ice.size() - 1))
	for i in range(int(ceil(_left)), int(floor(_right)) + 1):
		if _thawed[i] == 0:
			_reached[i] = 1

func _mark_thawed() -> void:
	var reach := (_elapsed - _profile.thaw_delay) * _profile.thaw_speed / _column_width
	if reach < 0.0:
		return
	var last := _ice.size() - 1
	for i in _ice.size():
		var distance: float
		if _profile.thaw_origin == IceProfile.ThawOrigin.FROM_ORIGIN:
			distance = absf(float(i - _origin))
		else:
			distance = float(mini(i, last - i))
		if distance <= reach:
			_thawed[i] = 1
