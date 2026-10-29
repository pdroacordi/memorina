class_name ReachKits extends Resource

## The journey's milestone kits, which room_kit_test checks one by one: the user's seven stages (2026-10-14, TECH-08),
## and, as orchestrator calls, the other orders design 04 section 2 allows: the Orchards before the Lake (woods_orchards,
## woods_orchards_caldera) and the Caldera before the Orchards (lake_caldera, both_caldera).

const DEFAULT_PATH := "res://resources/world/maps/reach_kits.tres"

@export var kits: Array[ReachKit] = []

static func load_default() -> ReachKits:
	return load(DEFAULT_PATH) as ReachKits

## The listed kit holding `kit`'s milestones, `milestone`, and beyond them only half milestones (a region's halves
## ride along with its guardian's milestone), or null.
func next(kit: ReachKit, milestone: ReachMilestone) -> ReachKit:
	if milestone.is_half():
		return null
	for other: ReachKit in kits:
		if not other.has(milestone) or not kit.milestones.all(func(held: ReachMilestone) -> bool: return other.has(held)):
			continue
		var extra := other.milestones.filter(func(held: ReachMilestone) -> bool: return held != milestone and not kit.has(held))
		if extra.all(func(held: ReachMilestone) -> bool: return held.is_half()):
			return other
	return null

## Every milestone some kit holds, in first-held order.
func milestones() -> Array[ReachMilestone]:
	var found: Array[ReachMilestone] = []
	for kit: ReachKit in kits:
		for milestone: ReachMilestone in kit.milestones:
			if not milestone in found:
				found.append(milestone)
	return found
