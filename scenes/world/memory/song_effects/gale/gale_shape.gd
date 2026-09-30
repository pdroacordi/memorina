class_name GaleShape extends RefCounted

## The shape of Vendaval's wind across its pulse (design 02 section 7.1): it
## blows OUTWARD from where the song was played, still in an eye around the
## player ("parado no olho, nao e arrastado ate sair dele"), strongest a
## little way out, and gone at the pulse's clean edge. Pure, so the numbers a
## puzzle is sized against are tested.

## Where across the ring from the eye to the edge the wind is strongest, 0..1.
const PEAK_AT := 0.35
## How much of the outward push points up or down. The gale is played on the
## ground and blows ACROSS it: fully radial, a body jumping near the origin
## is pushed ever more upward the higher it goes, and was measured launched
## off the top of the frame.
const VERTICAL_SHARE := 0.2

## 0..1 at `distance` from the origin, for a gale of `radius` with a still
## `eye`.
static func strength(distance: float, radius: float, eye: float) -> float:
	if radius <= eye or distance <= eye or distance >= radius:
		return 0.0
	var t := (distance - eye) / (radius - eye)
	if t < PEAK_AT:
		return smoothstep(0.0, 1.0, t / PEAK_AT)
	return 1.0 - smoothstep(0.0, 1.0, (t - PEAK_AT) / (1.0 - PEAK_AT))

## The gale's air at `point`, in px/s: outward from `origin`, mostly along
## the ground (VERTICAL_SHARE).
static func wind(origin: Vector2, point: Vector2, radius: float, eye: float, speed: float) -> Vector2:
	var offset := point - origin
	var distance := offset.length()
	if distance <= 0.0:
		return Vector2.ZERO
	var outward := Vector2(offset.x, offset.y * VERTICAL_SHARE).normalized()
	return outward * speed * strength(distance, radius, eye)
