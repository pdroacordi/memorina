class_name DiscShelter extends AirflowShelter

## A round place the air cannot reach, `radius` around this node: Redoma's
## shell (design 02 section 7.1: it shelters from the wind, Vendaval and the
## weather), which drives the radius as it shrinks, and a bench (design 03
## section 5.4, item 4: every bench is full shelter), which authors it.
## At 0 it covers nothing.

@export var radius := 0.0

func covers(global_point: Vector2) -> bool:
	return radius > 0.0 and global_point.distance_to(global_position) < radius
