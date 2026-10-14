class_name ReachKitCheck extends RefCounted

## Runs ReachAudit.run_kit once per milestone kit on the grid that kit opens (architecture/room-reachability-audit,
## TECH-08). A guardian's arena is an exit for the kit one milestone short of the kit it grants, when the world places
## that guardian there and the granted kit gets home from it: a pocket holding the fight is left by winning it.

## One report per kit of `kits`, in its order.
static func run(grid: ReachGrid, lattice: ReachLattice, kits: ReachKits) -> Array[ReachReport]:
	var by_kit: Dictionary[ReachKit, ReachReport] = {}
	for i: int in range(kits.kits.size() - 1, -1, -1):
		var kit := kits.kits[i]
		by_kit[kit] = ReachAudit.run_kit(grid.for_kit(kit), lattice, kit, _exits(grid, kit, kits, by_kit))
	var reports: Array[ReachReport] = []
	for kit: ReachKit in kits.kits:
		reports.append(by_kit[kit])
	return reports

## Whether the world gives `milestone` today: it restores a guardian, and every guardian it restores fights in its room.
## A hand-over with no guardian (the Memorina, STORY-03) or a guardian not yet built (GRD-04) is no way out.
static func given(grid: ReachGrid, milestone: ReachMilestone) -> bool:
	if milestone.restored_guardians.is_empty():
		return false
	for guardian: Enums.Guardian in milestone.restored_guardians:
		if grid.guardians.get(guardian, &"") != milestone.room:
			return false
	return true

# Feet cells, in the room of each milestone `kit` lacks and the world gives, of the surfaces the listed kit holding it
# (already run) gets home from.
static func _exits(grid: ReachGrid, kit: ReachKit, kits: ReachKits, by_kit: Dictionary[ReachKit, ReachReport]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for milestone: ReachMilestone in kits.milestones():
		if kit.has(milestone) or not given(grid, milestone):
			continue
		var next := kits.next(kit, milestone)
		if next == null or not by_kit.has(next):
			continue
		var report := by_kit[next]
		for i: int in report.home.size():
			if report.home[i] == 0:
				continue
			for cell: Vector2i in report.surfaces[i].cells:
				var room := grid.room_at(cell)
				if room >= 0 and grid.room_id(room) == milestone.room:
					cells.append(cell)
	return cells
