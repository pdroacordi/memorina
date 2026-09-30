class_name JumpReach extends RefCounted

## How far and how high Ivo can get, computed from his real tuning rather
## than guessed, so a level designer (and the reachability tests) can tell
## whether a gap is a jump, a double jump, or a song. Pure: it steps the same
## gravity curve JumpComponent applies (rise / fall multipliers, the softened
## apex, terminal velocity) at the physics rate, with Ivo running at full
## speed and holding jump the whole way.

const STEP := 1.0 / 60.0
## Long enough for any jump to come back down.
const MAX_STEPS := 600

var gravity: float
var jump: JumpStats
var locomotion: LocomotionStats
## Height of the air jump, or 0 without it.
var double_jump_height: float
## Ivo's collision radius: he may stand with his centre this far past an edge,
## and land this far short of one, so a gap is this much wider than his arc
## twice over.
var body_radius: float
## The air along the way, as Airflow would answer it: a Callable taking a
## point RELATIVE TO THE TAKE-OFF (y up negative) and returning the air's
## velocity there. Empty: still air. Steered toward exactly as
## LocomotionComponent.air_update / lift_update do, so a current or a gale is
## sized with the same numbers the game runs.
var wind := Callable()

func _init(p_gravity: float, p_jump: JumpStats, p_locomotion: LocomotionStats, p_double_jump_height: float = 0.0, p_body_radius: float = 11.0) -> void:
	gravity = p_gravity
	jump = p_jump
	locomotion = p_locomotion
	double_jump_height = p_double_jump_height
	body_radius = p_body_radius

## The highest the jump rises above where it left, in pixels.
func peak(with_double_jump: bool = false) -> float:
	var highest := 0.0
	for point: Vector2 in arc(with_double_jump):
		highest = maxf(highest, -point.y)
	return highest

## The widest gap between two ledges at the SAME height that a running jump
## clears, in pixels, edge to edge.
func gap(with_double_jump: bool = false) -> float:
	return reach_at(0.0, with_double_jump)

## How far across a running jump carries before it comes back down to
## `rise` pixels above where it left (negative: below), plus the body's
## overhang at both edges. 0 when the jump never gets that high.
func reach_at(rise: float, with_double_jump: bool = false) -> float:
	var points := arc(with_double_jump)
	if peak(with_double_jump) < rise:
		return 0.0
	for i: int in range(1, points.size()):
		var falling := points[i].y > points[i - 1].y
		if falling and -points[i].y <= rise:
			return points[i].x + body_radius * 2.0
	return 0.0

## The jump's path from the take-off point, y up being negative, one point
## per physics step, until it has fallen well below where it left.
func arc(with_double_jump: bool = false) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var position := Vector2.ZERO
	var velocity := Vector2(locomotion.move_speed, _launch(jump.jump_height))
	var air_jump_left := with_double_jump and double_jump_height > 0.0
	for i: int in MAX_STEPS:
		# The air jump is pressed at the apex, where it is worth the most.
		if air_jump_left and velocity.y >= 0.0:
			velocity.y = _launch(double_jump_height)
			air_jump_left = false
		var air: Vector2 = wind.call(position) if wind.is_valid() else Vector2.ZERO
		velocity.x = move_toward(velocity.x, locomotion.move_speed + air.x * locomotion.air_wind,
			locomotion.acceleration * locomotion.air_control * STEP)
		velocity.y = minf(velocity.y + gravity * _gravity_mult(velocity.y) * STEP, jump.terminal_velocity)
		velocity.y += air.y * locomotion.wind_lift * STEP
		position += velocity * STEP
		points.append(position)
		if position.y > jump.jump_height * 2.0:
			break
	return points

func _launch(height: float) -> float:
	return -sqrt(gravity * jump.rise_gravity_mult * height * 2.0)

func _gravity_mult(vertical: float) -> float:
	var mult := jump.fall_gravity_mult if vertical >= 0.0 else jump.rise_gravity_mult
	if absf(vertical) < jump.apex_threshold:
		mult *= jump.apex_gravity_mult
	return mult
