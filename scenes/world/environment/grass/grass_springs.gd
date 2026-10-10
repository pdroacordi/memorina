class_name GrassSprings
extends RefCounted
## One bending spring per segment of a grass run, advanced on its memory clock; at rate 0 its state holds exactly, so a
## blade caught in the grey resumes from that pose (architecture/generated-grass).

## World px of one segment: finer than Ivo's body, so a contact bends a few blades, not a block.
const SEGMENT_PX := 4
## Largest integration step, in clock seconds.
const MAX_SUBSTEP := 1.0 / 120.0
## Bend and velocity below this count as at rest.
const REST_EPSILON := 0.001

var bend := PackedFloat32Array()
var velocity := PackedFloat32Array()
## What each segment is pushed toward: -1..1, 0 upright.
var target := PackedFloat32Array()


func _init(count: int) -> void:
	bend.resize(count)
	velocity.resize(count)
	target.resize(count)

func count() -> int:
	return bend.size()

## Advances each segment by `delta * rates[i]` (rate 0 holds it); true when anything moved.
func step(delta: float, rates: PackedFloat32Array, profile: GrassProfile) -> bool:
	var moved := false
	for i: int in bend.size():
		var clock := delta * rates[i]
		if clock <= 0.0:
			continue
		var steps := ceili(clock / MAX_SUBSTEP)
		var dt := clock / steps
		for s: int in steps:
			var accel := -profile.stiffness * (bend[i] - target[i]) - profile.damping * velocity[i]
			velocity[i] += accel * dt
			bend[i] += velocity[i] * dt
		moved = true
	return moved

func is_resting() -> bool:
	for i: int in bend.size():
		if absf(bend[i] - target[i]) > REST_EPSILON or absf(velocity[i]) > REST_EPSILON or absf(target[i]) > 0.0:
			return false
	return true
