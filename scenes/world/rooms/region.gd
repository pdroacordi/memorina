class_name Region extends Node2D

## The composition scene that places a region's rooms. Owns what belongs to
## the region rather than to any single room: how much of it is still
## remembered, and which season its art is drawn in.
##
## A value, not a switch, deliberately - see
## docs/design/03_mundo_e_ambiente.md section 4.1. The home village opens at
## 0.8 (alive, but already thinning), is revisited lower, and returns to 1.0.

@export_range(0.0, 1.0) var memory_baseline: float = 0.8
## The region's native season (docs/design/03_mundo_e_ambiente.md section
## 4.2). Every seasonal sheet in its rooms shows this season's band unless a
## pulse paints another over it.
@export var season: Enums.Season = Enums.Season.SPRING
## Whether a guardian keeps this region, and which. Restoring it lifts the
## region's memory to 1.0 for good (section 4.1, "estacao de repouso
## permanente"); the flag exists because an enum has no "none".
@export var has_guardian: bool = false
@export var guardian: Enums.Guardian = Enums.Guardian.FROST

## The baseline as it stands now: the authored value until the region's
## guardian has been restored, then full memory.
func current_baseline() -> float:
	if has_guardian and SaveSystem.is_guardian_restored(guardian):
		return 1.0
	return memory_baseline
