class_name RootStrands extends RefCounted

## Two roots growing toward each other across a gap `length` px long, one from
## each earth face (design 02 section 7.1). Each grows at the memory under its
## own tip and only while its face is inside the pulse; a face the pulse has
## left withers its root back, so a joined span breaks at its tips first. They
## are JOINED - a floor, something to climb - only while they meet and both
## faces are still held. Pure, so the rule is tested.

var length := 0.0
## How far each root has grown from its face, px.
var a := 0.0
var b := 0.0
var _held_a := false
var _held_b := false

func _init(p_length: float) -> void:
	length = maxf(p_length, 0.0)

## `speed` px/s at memory 1; `rate_*` the memory at each tip; `held_*` whether
## each face is inside the pulse; `wither` px/s a let-go root shrinks back.
func advance(delta: float, speed: float, wither: float, rate_a: float, rate_b: float, held_a: bool, held_b: bool) -> void:
	_held_a = held_a
	_held_b = held_b
	var grow_a := speed * rate_a * delta if held_a else 0.0
	var grow_b := speed * rate_b * delta if held_b else 0.0
	# Both grow at once: when they would pass each other, they share what is
	# left of the gap in proportion to how fast each was growing.
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

