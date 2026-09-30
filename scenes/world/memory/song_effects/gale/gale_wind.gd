class_name GaleWind extends AirflowSource

## Vendaval's air, blowing one way across its pulse, shaped by GaleShape. Its
## owner (the gale) sets the reach, the speed and the way every frame.

var radius := 0.0
var eye := 48.0
var speed := 0.0
## +1 blows right, -1 left.
var direction := 1.0

func wind_at(global_point: Vector2) -> Vector2:
	return GaleShape.wind(global_position, global_point, radius, eye, speed, direction)
