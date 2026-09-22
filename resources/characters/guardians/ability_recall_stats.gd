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
## Presses the memory takes when the moment opens with Ivo's feet on the
## ground. A double jump is jump and then jump AGAIN, so asking for it while
## he stands there is two presses and the moment teaches the whole move; a
## roll is one. Caught already airborne, a memory is always the single press
## that is left to give.
@export_range(1, 3) var grounded_steps: int = 1
## The last press can only be given off the ground - a double jump remembered
## with both feet planted would be nonsense. A press with the feet down is
## simply not counted, and the ordinary jump it also performs is what puts Ivo
## where the memory can land.
@export var airborne_finish: bool = false
## Real seconds put back on the clock by every press but the last. 0 leaves
## whatever the window had left, which is harsh in a chain.
@export var step_window: float = 0.0
## Only open the moment once the body throwing the move is this close, in
## pixels: a charge from across the arena slows the world with nothing to
## dodge yet, and the blow lands at full speed after the window closes. 0
## opens at the swing's start.
@export var trigger_distance: float = 0.0
## Damage taken when the window closes on nothing - the design's "custo
## tatico real". Zero when the attack itself already lands on a miss.
@export var miss_damage: int = 0
