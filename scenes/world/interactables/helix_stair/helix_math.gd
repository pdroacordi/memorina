class_name HelixMath extends RefCounted

## The rider's path up a helix stair, pure (architecture/walkable-helix-stair, Revision).
## Positions are px from the axis base; progress `u` runs 0..`head_u()` and the tower is turned by u while he rides.


static func head_u(shape: HelixStairShape) -> float:
	return shape.turns * TAU

## The axis height at progress `u`, rising linearly: the camera frames it.
static func feet(shape: HelixStairShape, u: float) -> Vector2:
	return Vector2(0.0, -shape.pitch * u / TAU)

## Where the feet stand at progress `u`: on the tread under the axis, the floor at the foot, the gallery at the head.
## Each riser is climbed in the step the next tread passes under him.
static func stand(shape: HelixStairShape, u: float) -> Vector2:
	if u <= 0.0:
		return Vector2.ZERO
	if u >= head_u(shape):
		return Vector2(0.0, -shape.head_rise())
	return Vector2(0.0, -tread_rise(shape, step_at(shape, u)))

## The point under the feet in the tower: x right, y up the axis, z toward the viewer; px.
static func point_3d(shape: HelixStairShape, u: float) -> Vector3:
	return Vector3(0.0, shape.pitch * u / TAU, shape.walk_radius)

## Radians per second that pass the front tread under the feet at `run_speed` (px/s) times the shape's speed_scale.
static func angular_speed(shape: HelixStairShape, run_speed: float) -> float:
	return run_speed * shape.speed_scale / shape.walk_radius

## The step spanning progress `u`; step i spans u in [i, i + 1) times TAU / steps_per_turn.
static func step_at(shape: HelixStairShape, u: float) -> int:
	return clampi(floori(u / TAU * shape.steps_per_turn), 0, shape.step_count() - 1)

## Px from the base up to step `index`'s tread top: half a riser above its foot.
static func tread_rise(shape: HelixStairShape, index: int) -> float:
	return (index + 0.5) * shape.riser()
