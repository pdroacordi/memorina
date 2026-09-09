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
