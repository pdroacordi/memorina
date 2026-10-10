class_name GrassContact
extends RefCounted
## How characters push grass: each segment leans away from the nearest body standing on its walk line
## (architecture/generated-grass). Grass reads characters and never writes to them.

## World px above and below the walk line a body's bottom may be and still touch the grass.
const ABOVE := 16.0
const BELOW := 4.0


## Per segment centre in `xs`: the target bend (-1..1) the bodies push it to; the strongest push wins.
static func targets(xs: PackedFloat32Array, walk_y: float, bodies: Array[Rect2], push: float, reach: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(xs.size())
	for body: Rect2 in bodies:
		if not body.has_area() or body.end.y < walk_y - ABOVE or body.end.y > walk_y + BELOW:
			continue
		var centre := body.get_center().x
		var half := body.size.x * 0.5
		for i: int in xs.size():
			var d := xs[i] - centre
			var past := absf(d) - half
			var strength := 1.0 if past <= 0.0 else maxf(0.0, 1.0 - past / reach)
			var value := (1.0 if d >= 0.0 else -1.0) * push * strength
			if absf(value) > absf(out[i]):
				out[i] = value
	return out
