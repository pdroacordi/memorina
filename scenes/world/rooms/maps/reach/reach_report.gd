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
	## Ground at most ReachAudit.SHELF_CELLS wide, mostly over air within SHELF_DEPTH rows: a ledge out of a wall,
	## judged as a platform for LEADS_NOWHERE.
	SHELF,
}

var surfaces: Array[Surface] = []
## Per ReachLattice.Tier, 1 for each surface the start reaches; empty for a kit run (`reach`).
var reached: Array[PackedByteArray] = []
var findings: Array[ReachFinding] = []
## A kit run's ReachKit id; empty for the union run.
var kit: StringName
## A kit run: 1 for each surface the kit reaches, and for each it can return from (to the start or an exit).
var reach := PackedByteArray()
var home := PackedByteArray()
## A kit run: each group of surfaces it reaches and cannot return from, with the ways in.
var pockets: Array[Pocket] = []
## A kit run: the rooms of the exits it reached (a later kit's milestone room that kit gets home from).
var exits: Array[StringName] = []
## A kit run: every room a surface or hold it reaches has a cell in, in first-reached node order.
var rooms: Array[StringName] = []

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

## Surfaces a kit reaches and cannot return from, joined by its jumps and falls, and its KIT_TRAP finding.
class Pocket:
	var finding: ReachFinding
	## Every room a surface or hold of the pocket is in.
	var rooms: Array[StringName] = []
	## Each way in: "<room> <col>,<row> -> <room> <col>,<row>", from the side the kit returns from.
	var entrances := PackedStringArray()
	## Whether a bench stands in it, so a death respawns Ivo inside.
	var bench := false

## A maximal run of feet cells Ivo stands on, in one row.
class Surface:
	## Left to right, world cells.
	var cells: Array[Vector2i] = []
	var support: Support = Support.GROUND
	## Holds the start, a door, content or a secret.
	var anchor := false
	var room: StringName
