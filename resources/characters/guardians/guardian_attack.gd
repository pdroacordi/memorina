class_name GuardianAttack
extends Resource
## One move in a guardian's pressure-phase repertoire. Which clip plays it,
## how long it holds the guardian, how it is telegraphed, what its hitbox
## does, when it is chosen and whether it is the unavoidable one that opens
## the ability recall. `duration` must equal the clip's length; Guardian
## asserts it at startup.

## Which of the resolver's attack clips plays this move (0 = ATTACK_1).
@export_range(0, 2) var clip_index: int = 0
@export var duration: float = 1.0
## Seconds the guardian holds still and flashes before the swing begins, so
## the player can read it coming. The fair-fight knob: 0 is a sucker punch.
@export var telegraph: float = 0.4
## Horizontal distance to the player at which the guardian starts the swing.
@export var attack_range: float = 64.0
## How far above or below its own feet this move can still catch someone: a
## ground swing is not thrown at a player hovering overhead, but a move that
## answers one (a burst that launches) reaches high. Together with
## attack_range it is a BOX, not a radius - a melee swing landing on someone
## 60px up because the hypotenuse was short is how a boss looks silly.
@export var attack_height: float = 96.0
@export var cooldown: float = 1.5
## Horizontal speed held for the whole swing, in the facing direction. Zero
## for a standing swing; a charge sets it high.
@export var lunge_speed: float = 0.0
## Upward impulse at the start of the swing, in px/s. With lunge_speed this
## is a LEAP: the guardian jumps at the player and lands past them, which is
## how a light, animal guardian changes sides. A heavy one leaves it at 0 -
## not every boss should jump. Tune it against the clip: the swing and the
## airtime (2 * impulse / gravity) should end together.
@export var leap_impulse: float = 0.0
## Relative likelihood of this move being picked next. Ignored for the
## recall move, which is scheduled (GuardianStats.recall_after_attacks).
@export var weight: float = 1.0

@export_group("Hitbox")
@export var damage: int = 1
@export var knockback_strength: float = 420.0
## Upward push. A launch (large lift, no damage) is how a move puts Ivo in
## the air for a recall that only makes sense airborne.
@export var knockback_lift: float = 120.0

@export_group("Recall")
## Non-null marks the attack that cannot be dodged without the skill it
## teaches: while the player lacks that skill, starting this attack opens the
## recall instead of simply landing.
@export var recall: AbilityRecallStats
