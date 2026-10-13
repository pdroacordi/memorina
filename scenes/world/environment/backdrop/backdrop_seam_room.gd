class_name BackdropSeamRoom
extends RefCounted
## A room as `BackdropSeams` sees it: its bounds, the picture its backdrop draws, and the lattice cells that hide a cut.

var id: String
var rect: Rect2
var shown: BackdropSet
## The set it draws over its top: its region's (Backdrop.Part.OVER_TOP), the same as `shown` for an open room.
var over_top: BackdropSet
## The anchor `BackdropMath.layer_anchor` places the set's edges from.
var anchor: Vector2
## Lattice cell -> true for ground, void, a back wall or a lake.
var opaque: Dictionary[Vector2i, bool] = {}


func _init(room_id: String, bounds: Rect2, picture: BackdropSet, horizon_anchor: Vector2, sky: BackdropSet = null) -> void:
	id = room_id
	rect = bounds
	shown = picture
	over_top = sky if sky != null else picture
	anchor = horizon_anchor
