class_name ReachReport extends RefCounted

## What ReachAudit found: the surfaces, which of them each tier reaches, and the findings.

## What holds a surface up.
enum Support {
	## Ground touching a room's edge, or a facade's roof.
	GROUND,
	## Only one-way ledges and islands (solid groups touching no room edge).
	PLATFORM,
	## Only floors a song makes, or in water a song holds back: never flagged.
	SONG,
}

var surfaces: Array[Surface] = []
## Per ReachLattice.Tier, 1 for each surface the start reaches.
var reached: Array[PackedByteArray] = []
var findings: Array[ReachFinding] = []

func count(kind: ReachFinding.Kind, error: bool) -> int:
	var total := 0
	for finding: ReachFinding in findings:
		if finding.kind == kind and finding.error == error:
			total += 1
	return total

func errors() -> Array[ReachFinding]:
	var found: Array[ReachFinding] = []
	for finding: ReachFinding in findings:
		if finding.error:
			found.append(finding)
	return found

## A maximal run of feet cells Ivo stands on, in one row.
class Surface:
	## Left to right, world cells.
	var cells: Array[Vector2i] = []
	var support: Support = Support.GROUND
	## Holds the start, a door, content or a secret.
	var anchor := false
	var room: StringName
