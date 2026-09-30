class_name RadialWind extends AirflowSource

## Air blowing outward from this node, shaped by GaleShape. Its owner (the
## gale) sets the reach and the speed every frame.

var radius := 0.0
var eye := 48.0
var speed := 0.0

func wind_at(global_point: Vector2) -> Vector2:
	return GaleShape.wind(global_position, global_point, radius, eye, speed)
