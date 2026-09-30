class_name DiscShelter extends AirflowShelter

## A round place the air cannot reach, `radius` around this node: Redoma's
## shell (design 02 section 7.1: it shelters from the wind, Vendaval and the
## weather). At 0 it covers nothing.

var radius := 0.0

func covers(global_point: Vector2) -> bool:
	return radius > 0.0 and global_point.distance_to(global_position) < radius
