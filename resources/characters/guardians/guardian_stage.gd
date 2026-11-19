class_name GuardianStage
extends Resource
## A guardian's tuning at one cure stage, indexed by good answers (GuardianStats.stages; GuardianFight.stage_tuning).

## Moves in one string when a guardian has no stage table.
const DEFAULT_MAX_LINKS := 3

## Multiplier on every cooldown, on top of the aggression's.
@export var cooldown_scale: float = 1.0
## Multiplier on every link's chance.
@export var chain_scale: float = 1.0
## Moves in one string, the first included; capped by GuardianRepertoire.MAX_LINKS.
@export_range(1, 4) var max_links: int = DEFAULT_MAX_LINKS
## Multiplier on the walk toward Ivo for a move (not the pacing between moves).
@export var walk_scale: float = 1.0
## Multiplier on every recovery: the punish window after a string, shorter at a late stage.
@export var recovery_scale: float = 1.0
