class_name ReachAllowlistEntry extends Resource

## One reachability error accepted for now, and why (architecture/room-reachability-audit).

## The room's id, its scene file name.
@export var room: StringName
## The flagged surface's left feet cell: its column and row in the `.room` file.
@export var cell: Vector2i
@export var kind: ReachFinding.Kind
## Never empty: the design reason or the roadmap item that removes it.
@export var reason := ""

func matches(finding: ReachFinding) -> bool:
	return finding.room == room and finding.local == cell and finding.kind == kind
