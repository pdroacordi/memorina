class_name SwingSway
extends Node2D
## A rope swing hung from this node's origin (the branch): a push swings it out east, and it dies down by itself on the
## pausable, scaled clock (flashback 3, systems/story). It writes only its own rotation; hidden, it rests.

## Seconds of one swing out and back.
@export var period: float = 2.4
## Degrees one push adds to the swing.
@export var kick_degrees: float = 10.0
## Degrees the swing never passes.
@export var max_degrees: float = 16.0
## Seconds for the swing to fall to 37 % while pushed.
@export var decay: float = 6.0
## Seconds for the swing to fall to 37 % once let go.
@export var let_go_decay: float = 1.4
## Degrees under which it rests.
@export var rest_degrees: float = 0.3

## Degrees of the current swing.
var _amplitude: float = 0.0
## Radians into the current swing; 0 is the bottom, moving east.
var _phase: float = 0.0
var _tau: float = 0.0


func _ready() -> void:
	_tau = decay
	visibility_changed.connect(_on_visibility_changed)

func _process(delta: float) -> void:
	if _amplitude <= 0.0:
		return
	_phase = fmod(_phase + TAU * delta / period, TAU)
	_amplitude *= exp(-delta / _tau)
	if _amplitude < rest_degrees and _near_bottom():
		_rest()
		return
	# Negative: the seat hangs below the origin, so a clockwise turn would send it west.
	rotation = -deg_to_rad(_amplitude * sin(_phase))

## Swings it out east (or further, if it swings already) and keeps it swinging slowly.
func push() -> void:
	_tau = decay
	if _amplitude <= 0.0:
		_phase = 0.0
	_amplitude = minf(_amplitude + kick_degrees, max_degrees)

## No one pushes any more: it dies down by itself.
func let_go() -> void:
	_tau = let_go_decay

func is_swinging() -> bool:
	return _amplitude > 0.0

## Degrees of the current swing.
func amplitude() -> float:
	return _amplitude

func _near_bottom() -> bool:
	return absf(sin(_phase)) < 0.2

func _rest() -> void:
	_amplitude = 0.0
	_phase = 0.0
	_tau = decay
	rotation = 0.0

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_rest()
