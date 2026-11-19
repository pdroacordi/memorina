class_name GuardianBodyContact
extends RefCounted
## When a guardian's body may hurt on touch after a move that left its own box as its only hit: never on an Ivo the
## move carried it onto, until he has left the body or a short grace has run out; pure, used by Guardian
## (bugs/the-frost-charge-skids-onto-ivo-harmlessly-and-its-body-hurts-the-instant-its-recovery-ends).

## Scaled s the body stays harmless to an Ivo still inside it; walking out of the widest body (the Sun lion's 132 px,
## 77 px at 192 px/s) takes 0.4 s of it.
const GRACE := 0.6
## Px a recovery skid stops short of Ivo's body.
const SKID_GAP := 4.0

var _left: float = 0.0


## A move with `body_contact` false ended its string: hold the contact while Ivo is inside the body.
func begin() -> void:
	_left = GRACE

## Ends the hold: a new string begins.
func clear() -> void:
	_left = 0.0

## Advances the hold by `delta` scaled s; it ends at once when Ivo is clear of the body.
func tick(delta: float, overlapping: bool) -> void:
	if not overlapping:
		_left = 0.0
		return
	_left = maxf(_left - delta, 0.0)

func holds() -> bool:
	return _left > 0.0

## Whether a skid moving `velocity_x` px/s stops: it heads for an Ivo `dx` px away (signed), whose body meets the
## guardian's at `bodies` px.
static func skid_stops(dx: float, velocity_x: float, bodies: float) -> bool:
	if is_zero_approx(velocity_x) or signf(velocity_x) != signf(dx):
		return false
	return absf(dx) <= bodies + SKID_GAP
