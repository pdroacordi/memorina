class_name GuardianAttack
extends Resource
## One move in a guardian's pressure-phase repertoire. Which clip plays it,
## how long it holds the guardian, when it is chosen and whether it is the
## unavoidable one that opens the ability recall. `duration` must equal the
## clip's length; Guardian asserts it at startup.

## Which of the resolver's attack clips plays this move (0 = ATTACK_1).
@export_range(0, 2) var clip_index: int = 0
@export var duration: float = 1.0
## Distance to the player at which the guardian starts the swing.
@export var attack_range: float = 64.0
@export var cooldown: float = 1.5
## Horizontal speed held for the whole swing, in the facing direction. Zero
## for a standing swing; a charge sets it high.
@export var lunge_speed: float = 0.0
## Relative likelihood of this move being picked next.
@export var weight: float = 1.0
## Non-null marks the attack that cannot be dodged without the skill it
## teaches: while the player lacks that skill, starting this attack opens the
## recall instead of simply landing.
@export var recall: AbilityRecallStats
