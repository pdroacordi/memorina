class_name HelixProjection extends RefCounted

## Projects the turning tower onto the screen, pure (architecture/walkable-helix-stair, Revision).
## View space: x right, y down (px from the axis base, as the screen), z toward the eye; the eye sits at
## (0, eye, eye_distance) and Ivo's plane, z = walk_radius, maps 1:1.


## The view-space point of tower angle `theta`, radius `r`, height `y` (px, down positive) with the tower turned by `phi`.
static func view_point(hand: int, theta: float, r: float, y: float, phi: float) -> Vector3:
	var beta := theta - phi
	return Vector3(hand * r * sin(beta), y, r * cos(beta))

## The scale a point at depth `z` is drawn at: 1 in Ivo's plane.
static func scale_at(shape: HelixStairShape, z: float) -> float:
	return (shape.eye_distance - shape.walk_radius) / (shape.eye_distance - z)

## Where view-space `point` falls on the screen, px from the axis base, for the eye at height `eye`.
static func project(shape: HelixStairShape, point: Vector3, eye: float) -> Vector2:
	var k := scale_at(shape, point.z)
	return Vector2(point.x * k, eye + (point.y - eye) * k)

## The screen point of tower angle `theta`, radius `r`, height `y`.
static func project_polar(shape: HelixStairShape, hand: int, theta: float, r: float, y: float, phi: float, eye: float) -> Vector2:
	return project(shape, view_point(hand, theta, r, y, phi), eye)

## Px from the axis to the wall's silhouette on screen: where the shell's inner faces stand.
static func silhouette(shape: HelixStairShape) -> float:
	var d := shape.eye_distance
	var r := shape.wall_radius
	return r * (d - shape.walk_radius) / sqrt(d * d - r * r)

## The view-space eye.
static func eye_point(shape: HelixStairShape, eye: float) -> Vector3:
	return Vector3(0.0, eye, shape.eye_distance)
