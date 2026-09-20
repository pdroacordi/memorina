class_name AbilityRecallStats
extends Resource
## The emergency QTE of docs/design/02_mecanicas.md section 4: which skill the
## body remembers, which button remembers it, and how long the slowed moment
## lasts. Attached to the one GuardianAttack that cannot be dodged without it.

@export var skill: Enums.PlayerSkill = Enums.PlayerSkill.ROLL
## The input action the prompt asks for, in the InputMap's names. The same
## press that recalls the skill also performs it, so this must be the action
## the skill's component listens to.
@export var action: StringName = &"roll"
## Seconds of REAL time the player has once the moment slows. Real, not game
## time: the whole point of slowing the world is to give the hand a moment.
@export var window: float = 1.2
## Seconds of invulnerability granted on success, so the attack that forced
## the memory does not land while the body is still finishing the move.
@export var grace_time: float = 0.6
## Only open the moment once Ivo is off the ground: a double jump remembered
## with both feet planted would be nonsense. The attack that carries this
## must launch him (see GuardianAttack.knockback_lift); if he never leaves
## the ground before the attack ends, the moment simply does not come.
@export var requires_airborne: bool = false
## Damage taken when the window closes on nothing - the design's "custo
## tatico real". Zero when the attack itself already lands on a miss.
@export var miss_damage: int = 0
