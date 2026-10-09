@tool
class_name BackdropSet
extends Resource
## A biome's backdrop: its layers far to near, and the eye level the far ones keep (architecture/vertical-backdrops).

## Far to near, in draw order; `scroll_scale.x` never decreases.
@export var layers: Array[BackdropLayer] = []
## Game px from the frame top where a layer with vertical scroll 0 draws its horizon.
@export var horizon_screen_y: float = 180.0


## Developer diagnostics; empty when the set is usable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	var last_x := 0.0
	for i: int in layers.size():
		var layer := layers[i]
		if layer == null:
			found.append("layer %d is empty" % i)
			continue
		for problem: String in layer.problems():
			found.append("layer %d: %s" % [i, problem])
		if layer.scroll_scale.x < last_x:
			found.append("layer %d scrolls slower than the layer behind it" % i)
		last_x = layer.scroll_scale.x
	return found
