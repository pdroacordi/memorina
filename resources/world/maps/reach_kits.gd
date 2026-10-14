class_name ReachKits extends Resource

## The journey's milestone kits, which room_kit_test checks one by one: the user's seven stages (2026-10-14, TECH-08),
## and, as orchestrator calls, the other orders design 04 section 2 allows: the Orchards before the Lake (woods_orchards,
## woods_orchards_caldera) and the Caldera before the Orchards (lake_caldera, both_caldera).

const DEFAULT_PATH := "res://resources/world/maps/reach_kits.tres"

@export var kits: Array[ReachKit] = []

static func load_default() -> ReachKits:
	return load(DEFAULT_PATH) as ReachKits

## The listed kit holding exactly `kit`'s milestones and `milestone`, or null.
func next(kit: ReachKit, milestone: ReachMilestone) -> ReachKit:
	for other: ReachKit in kits:
		if other.milestones.size() == kit.milestones.size() + 1 and other.has(milestone) \
				and kit.milestones.all(func(held: ReachMilestone) -> bool: return other.has(held)):
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
