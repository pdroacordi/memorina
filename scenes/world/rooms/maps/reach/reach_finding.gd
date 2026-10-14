class_name ReachFinding extends RefCounted

## One surface, or group of surfaces, the reachability audit flags (architecture/room-reachability-audit).

enum Kind {
	## A surface the start cannot reach with the full kit; an error on a platform.
	UNREACHABLE,
	## A reached platform that holds nothing and that no way to anything needs.
	LEADS_NOWHERE,
	## LEADS_NOWHERE, but the last of parallel routes: removing it would cut an anchor off.
	REDUNDANT_ROUTE,
	## Ground, in a group of reached surfaces, that holds nothing and that no way to anything needs.
	DEAD_END_POCKET,
	## A reached surface the same kit cannot return to the start from.
	NO_WAY_BACK,
	## A door whose link no other door of its region shares, or that two others share.
	UNPAIRED_DOOR,
	## A footprint that stands with its feet outside every room, in a sky band; never allowlisted.
	OUTSIDE_ROOM,
	## Side or bottom edge cells Ivo's body can fill that open onto an invisible wall.
	OPEN_EDGE,
	## Surfaces a milestone kit reaches from the start and cannot return from with that kit (ReachAudit.run_kit).
	KIT_TRAP,
}

## The board mark per kind, drawn on a surface's feet row. Never a legend symbol (reach_grid_test).
const MARKS := {
	Kind.UNREACHABLE: "!",
	Kind.LEADS_NOWHERE: "*",
	Kind.REDUNDANT_ROUTE: "+",
	Kind.DEAD_END_POCKET: ":",
	Kind.NO_WAY_BACK: "&",
	Kind.UNPAIRED_DOOR: "?",
	Kind.OUTSIDE_ROOM: "x",
	Kind.OPEN_EDGE: "|",
	Kind.KIT_TRAP: ">",
}

var kind: Kind
var error: bool
## The room holding `cell`, its scene file name.
var room: StringName
## The ReachKit id a KIT_TRAP was found for; empty for every other kind.
var kit: StringName
## The feet cell at the surface's left end, world cells.
var cell: Vector2i
## `cell` from the room's top-left: the column and row in its `.room` file.
var local: Vector2i
## Every feet cell flagged, world cells.
var cells: Array[Vector2i] = []

func _init(p_kind: Kind, p_error: bool, p_room: StringName, p_cell: Vector2i, p_local: Vector2i, p_cells: Array[Vector2i]) -> void:
	kind = p_kind
	error = p_error
	room = p_room
	cell = p_cell
	local = p_local
	cells = p_cells

func kind_name() -> String:
	return Kind.keys()[kind]

func _to_string() -> String:
	var by := "" if kit.is_empty() else " for kit %s" % kit
	return "%s%s %s at %s,%s (%s)" % [kind_name(), by, room, local.x, local.y, "error" if error else "warning"]
