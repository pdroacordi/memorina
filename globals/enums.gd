class_name Enums

## WALL_CLIMB gates WallMobilityComponent, which covers both wall sliding and
## jumping away from a wall, not just climbing.
##
## Member ORDER is load-bearing: PlayerData stores unlocked skills as an
## Array[bool] indexed by this enum, persisted in the save file. Members must
## only ever be appended at the end, never reordered or removed, or saved
## unlock flags will silently point at the wrong skill.
enum PlayerSkill {
	DOUBLE_JUMP,
	WALL_CLIMB,
	ROLL
}

## Possessions, as opposed to PlayerSkill's permanent unlocks: an item can be
## granted and later taken away, so unlike skills this array's values are NOT
## expected to be monotonic. Member order is still append-only for the same
## reason as PlayerSkill - it indexes PlayerData.owned_items in the save file.
enum PlayerItem {
	SWORD
}
