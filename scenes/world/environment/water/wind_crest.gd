class_name WindCrest extends RefCounted

## Water piled against a pool's downwind bank, as one signed height a wedge is drawn from (docs/knowledge/architecture/wind-piles-a-bounded-crest.md).

var _profile: WaterProfile
var _cap := 0.0
var _height := 0.0
# How high the ground stands above the rest line beside each end, px: water never piles over its bank.
var _bank_left := INF
var _bank_right := INF

## `width_px` is the pool's width, which limits how high the wind can pile it.
func _init(profile: WaterProfile, width_px: float) -> void:
	_profile = profile
	_cap = minf(profile.crest_height, profile.crest_per_fetch * width_px)

## Signed crest height, px above the rest line: positive piles at the right end, negative at the left.
func height() -> float:
	return _height

func cap() -> float:
	return _cap

## The ground's height above the rest line at the left and right ends, px; the crest piles no higher than the bank it leans on.
func set_banks(left: float, right: float) -> void:
	_bank_left = maxf(left, 0.0)
	_bank_right = maxf(right, 0.0)

## Advances by `delta` seconds under `wind` (mean px/s over the pool, positive to the right) at memory `rate` 0..1.
func step(delta: float, wind: float, rate: float) -> void:
	if _cap <= 0.0 or rate <= 0.0 or delta <= 0.0:
		return
	var span := maxf(_profile.crest_full_wind - _profile.crest_min_wind, 0.001)
	var drive := signf(wind) * clampf((absf(wind) - _profile.crest_min_wind) / span, 0.0, 1.0)
	var target := drive * minf(_cap, _bank_right if drive > 0.0 else _bank_left)
	# Building toward a crest the wind holds is slow; falling back is quicker.
	var building := absf(target) > absf(_height) and (signf(target) == signf(_height) or is_zero_approx(_height))
	var time := _profile.crest_rise_time if building else _profile.crest_settle_time
	_height = move_toward(_height, target, _cap / maxf(time, 0.001) * rate * delta)

## The crest's offset over `column` of `count` columns `column_width` px wide: a wedge from the downwind end, 0 beyond `crest_length`.
func offset(column: int, count: int, column_width: float) -> float:
	if is_zero_approx(_height):
		return 0.0
	var centre := (column + 0.5) * column_width
	var distance := count * column_width - centre if _height > 0.0 else centre
	return absf(_height) * maxf(0.0, 1.0 - distance / _profile.crest_length)
