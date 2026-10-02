class_name SolsticeAura extends PulseEffect

## Solstice stretches overlapping non-Solstice pulses (docs/design/02_mecanicas.md section 7.1).

@export var reach := 1.4
@export var duration := 2.5
@export var ray_color := Color(1.0, 0.82, 0.45, 0.9)
@export var rays := 18

var _clock := 0.0

func _physics_process(delta: float) -> void:
	_clock += delta
	var radius := pulse.radius()
	if radius > 0.0:
		for member: Node in get_tree().get_nodes_in_group(ColorPulse.GROUP):
			var other := member as ColorPulse
			if other == null or other == pulse or other.song() == null or other.song().id == Enums.Song.SOLSTICE:
				continue
			if other.global_position.distance_to(pulse.global_position) < other.radius() + radius:
				other.stretch(reach, duration)
	queue_redraw()

func _draw() -> void:
	var radius := pulse.radius()
	if radius < 8.0:
		return
	for i in rays:
		var angle := TAU * i / rays + _clock * 0.08
		var along := Vector2.from_angle(angle)
		draw_line((along * (radius - 10.0)).round(), (along * (radius + 4.0)).round(), ray_color, 2.0, false)
