class_name DiscShelter extends AirflowShelter

## See docs/design/02_mecanicas.md section 7.1 and docs/design/03_mundo_e_ambiente.md section 5.4 item 4.
## Radius is in pixels; zero covers no area.

@export var radius := 0.0

func covers(global_point: Vector2) -> bool:
	return radius > 0.0 and global_point.distance_to(global_position) < radius
