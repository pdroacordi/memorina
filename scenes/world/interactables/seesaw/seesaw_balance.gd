class_name SeesawBalance extends RefCounted

## Computes the seesaw's net torque and settled angle.

## Each load is (signed distance from pivot in px, mass in Ivos).
static func torque(loads: Array[Vector2]) -> float:
	var sum := 0.0
	for load: Vector2 in loads:
		sum += load.x * load.y
	return sum

## Settled angle in radians; positive angles lower the right side.
static func settle_angle(loads: Array[Vector2], degrees_per_torque: float, max_degrees: float) -> float:
	return deg_to_rad(clampf(torque(loads) * degrees_per_torque, -max_degrees, max_degrees))
