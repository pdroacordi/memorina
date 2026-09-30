class_name SolsticeAura extends PulseEffect

## Solstice (Enums.Song.SOLSTICE): the longest day. It acts on MEMORY, not on
## the world (design 02 section 7.1): every other pulse that overlaps it lasts
## longer and reaches farther - once (ColorPulse.stretch) - so the shadow holds
## the door to the end of the corridor, the root bridge reaches farther and the
## ice lasts the crossing, with no rule in any of them. Alone it holds colour in
## a dead place longer: its own stats sustain long and contract at the same
## pace whatever the memory.
##
## Looks like a low sun: warm rays turning slowly on the disc's edge.

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
