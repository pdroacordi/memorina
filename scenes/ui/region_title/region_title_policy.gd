class_name RegionTitlePolicy
extends RefCounted
## Decides what a room change does to the region title (systems/region-title).

enum Action { NONE, RECORD, ANNOUNCE }


## RECORD marks the region shown without a title; ANNOUNCE plays it and marks it.
## The first room of a world build only records: a new game, a load and a death rebuild never announce.
static func decide(shows_title: bool, first_of_world: bool, announced: bool) -> Action:
	if not shows_title or announced:
		return Action.NONE
	if first_of_world:
		return Action.RECORD
	return Action.ANNOUNCE
