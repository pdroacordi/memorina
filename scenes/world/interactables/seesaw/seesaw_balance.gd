class_name SeesawBalance extends RefCounted

## Which way a seesaw leans for the weights on it: each weight turns it by its
## mass times its signed distance from the pivot (right is positive), and the
## plank settles at an angle proportional to the net turn, up to its limit.
## Pure, so a puzzle built on it can be checked.

## `loads`: pairs of (signed distance from the pivot in px, mass in Ivos).
static func torque(loads: Array[Vector2]) -> float:
	var sum := 0.0
	for load: Vector2 in loads:
		sum += load.x * load.y
	return sum

## The angle (radians, positive = right side down) the plank settles at.
static func settle_angle(loads: Array[Vector2], degrees_per_torque: float, max_degrees: float) -> float:
	return deg_to_rad(clampf(torque(loads) * degrees_per_torque, -max_degrees, max_degrees))
