class_name RootStrands extends RefCounted

## Computes opposing root growth across a gap; see docs/design/02_mecanicas.md section 7.1.

var length := 0.0
## Growth distance from each face, in px.
var a := 0.0
var b := 0.0
var _held_a := false
var _held_b := false

func _init(p_length: float) -> void:
	length = maxf(p_length, 0.0)

## `speed` and `wither` are px/s; `rate_*` are memory values at each tip.
func advance(delta: float, speed: float, wither: float, rate_a: float, rate_b: float, held_a: bool, held_b: bool) -> void:
	_held_a = held_a
	_held_b = held_b
	var grow_a := speed * rate_a * delta if held_a else 0.0
	var grow_b := speed * rate_b * delta if held_b else 0.0
	# Scale simultaneous growth proportionally when it exceeds the remaining gap.
	var room := maxf(length - a - b, 0.0)
	if grow_a + grow_b > room:
		var share := room / (grow_a + grow_b)
		grow_a *= share
		grow_b *= share
	a = a + grow_a if held_a else maxf(a - wither * delta, 0.0)
	b = b + grow_b if held_b else maxf(b - wither * delta, 0.0)

func is_joined() -> bool:
	return _held_a and _held_b and a + b >= length - 0.5

func is_bare() -> bool:
	return a <= 0.0 and b <= 0.0
