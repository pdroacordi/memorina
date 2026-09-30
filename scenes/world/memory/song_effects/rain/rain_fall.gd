class_name RainFall extends PulseEffect

## Chuva (Enums.Song.RAIN): it rains inside the pulse (design 02 section 7.1).
## The drops fall from the top of the disc, drawn with seasonal_particles so
## they exist only where the pulse has redrawn the world (inside it, and
## nowhere else), and where they land on water they dent it. What the rain
## FILLS is the world's answer, not the effect's: a RainBasin hears the song.
##
## Looks like a SONG and not the spring drizzle (design 03 section 5.3): it
## falls only in the pulse, and stops as the grey takes the pulse back.

## Drops landing on water per second, across the whole disc.
@export var drips_per_second := 30.0
## How deep a drop dents the water, px.
@export var drip_depth := 1.2

var _debt := 0.0

@onready var _rain: CPUParticles2D = $Rain

func _physics_process(delta: float) -> void:
	var radius := pulse.radius()
	var raining := pulse.phase() != PulseTimeline.Phase.CONTRACT and radius > 8.0
	_rain.emitting = raining
	_rain.position = Vector2(0.0, -radius)
	_rain.emission_rect_extents = Vector2(maxf(radius, 1.0), 4.0)
	if raining:
		_drip(delta, radius)

func _drip(delta: float, radius: float) -> void:
	_debt += delta * drips_per_second
	while _debt >= 1.0:
		_debt -= 1.0
		var x := global_position.x + randf_range(-radius, radius)
		for member: Node in get_tree().get_nodes_in_group(WaterBody.GROUP):
			var water := member as WaterBody
			var point := Vector2(x, water.surface_rest_y())
			if water.contains_x(x) and pulse.contains(point) and not _sheltered(point):
				water.drip(x, drip_depth)

## Under a Redoma's shell it does not rain (design 02 section 7.4).
func _sheltered(point: Vector2) -> bool:
	for shell: ColorPulse in ColorPulse.lit(self, Enums.Song.BELL_JAR):
		if shell.contains(point):
			return true
	return false
