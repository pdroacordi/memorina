class_name HeldDiscs extends RefCounted

## Discs Redoma's shells hold water out of, as Vector3(centre x, centre y, radius) (docs/knowledge/architecture/the-shell-displaces-water-into-the-reach.md).

## Whether `point` is inside any disc. Must match wc_held() in water_common.gdshaderinc.
static func contains(point: Vector2, discs: Array) -> bool:
	for disc: Vector3 in discs:
		if point.distance_to(Vector2(disc.x, disc.y)) < disc.z:
			return true
	return false

## Area of water, px², the discs keep out between the waterline at `line_y` and each column's floor (world y in `floors`).
static func held_area(left: float, column_width: float, line_y: float, floors: PackedFloat32Array, discs: Array) -> float:
	var area := 0.0
	for column in floors.size():
		var x := left + (column + 0.5) * column_width
		var top := INF
		var bottom := -INF
		for disc: Vector3 in discs:
			var dx := x - disc.x
			if absf(dx) < disc.z:
				var h := sqrt(disc.z * disc.z - dx * dx)
				top = minf(top, disc.y - h)
				bottom = maxf(bottom, disc.y + h)
		var overlap := minf(bottom, floors[column]) - maxf(top, line_y)
		if overlap > 0.0:
			area += overlap * column_width
	return area

## How far the water held out of the discs raises a pool resting at `rest_y`, px, no higher than `cap`: its volume spread over the width left wet.
static func displaced_rise(left: float, column_width: float, rest_y: float, floors: PackedFloat32Array, discs: Array, cap: float) -> float:
	if discs.is_empty() or cap <= 0.0:
		return 0.0
	var area := held_area(left, column_width, rest_y, floors, discs)
	var rise := 0.0
	# The held volume is fixed at the rest line; the wet width shrinks as the line rises into the discs: a few rounds settle it.
	for i in 4:
		var line := rest_y - rise
		var wet := 0.0
		for column in floors.size():
			var point := Vector2(left + (column + 0.5) * column_width, line)
			if floors[column] > line and not contains(point, discs):
				wet += column_width
		if wet <= 0.0:
			return cap
		rise = minf(area / wet, cap)
	return rise
