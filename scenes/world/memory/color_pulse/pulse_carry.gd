class_name PulseCarry extends RefCounted

## A weather pulse that held Ivo as he left an interior, opened again outside the door (SONG-21; systems/songs-and-the-memorina).

# Weak: the pulse can end behind the door's cover.
var _pulse: WeakRef
var _distance: float

## The acting weather pulses whose clean disc holds `point`.
static func held_at(tree: SceneTree, point: Vector2) -> Array[PulseCarry]:
	var found: Array[PulseCarry] = []
	for member: Node in tree.get_nodes_in_group(ColorPulse.GROUP):
		var pulse := member as ColorPulse
		if pulse and pulse.acts() and pulse.song() and pulse.song().weather and pulse.contains(point):
			found.append(PulseCarry.new(pulse, point.distance_to(pulse.global_position)))
	return found

## Reach left to a pulse of `max_radius` px carried from `distance` px off its centre.
static func reach_left(max_radius: float, distance: float) -> float:
	return maxf(max_radius - distance, 0.0)

func _init(pulse: ColorPulse, distance: float) -> void:
	_pulse = weakref(pulse)
	_distance = distance

## Opens the carried pulse at `at`; null when it ended behind the cover or has no reach left.
func open_at(at: Vector2) -> ColorPulse:
	var pulse := _pulse.get_ref() as ColorPulse
	if pulse == null or pulse.is_queued_for_deletion() or pulse.phase() == PulseTimeline.Phase.DONE:
		return null
	var reach := reach_left(pulse.max_radius(), _distance)
	if reach <= 0.0:
		return null
	return pulse.carried(at, reach)
