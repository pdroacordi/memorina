class_name DeathMarkClusters extends RefCounted

## Groups a region's deaths into the marks it shows: a death near a mark
## deepens it, a death far from every mark starts a new one, and once the
## region shows `max_marks` every further death deepens the nearest. Greedy,
## in the order the deaths happened, so the same save always draws the same
## marks. Pure; RegionMemory mounts the result.

## Returns one {"centre": Vector2, "deaths": int} per mark. A mark's centre is
## the mean of its deaths, so a corner died in again and again keeps its mark
## where the deaths actually are.
static func cluster(points: PackedVector2Array, merge_distance: float, max_marks: int) -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	for point: Vector2 in points:
		var nearest := _nearest(marks, point)
		var near_enough := nearest >= 0 and (marks[nearest]["centre"] as Vector2).distance_to(point) <= merge_distance
		if near_enough or (nearest >= 0 and marks.size() >= max_marks):
			var mark := marks[nearest]
			var deaths: int = mark["deaths"]
			mark["centre"] = ((mark["centre"] as Vector2) * deaths + point) / (deaths + 1)
			mark["deaths"] = deaths + 1
		else:
			marks.append({"centre": point, "deaths": 1})
	return marks

static func _nearest(marks: Array[Dictionary], point: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for i: int in marks.size():
		var distance := (marks[i]["centre"] as Vector2).distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best
