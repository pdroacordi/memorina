class_name AbilityRecallStats
extends Resource
## Recall QTE tuning for the Guardian attack (docs/design/02_mecanicas.md section 4).

@export var skill: Enums.PlayerSkill = Enums.PlayerSkill.ROLL
## InputMap action that recalls and performs the skill; it must match the skill component's action.
@export var action: StringName = &"roll"
## Real seconds available after the moment slows.
@export var window: float = 1.2
## Invulnerability duration on success, in seconds.
@export var grace_time: float = 0.6
## Press count when recall starts grounded; airborne recall always requires one press.
@export_range(1, 3) var grounded_steps: int = 1
## Whether the last press requires Ivo to be airborne; grounded presses are not counted.
@export var airborne_finish: bool = false
## Real seconds added to the clock by each non-final press.
@export var step_window: float = 0.0
## Maximum attack distance in pixels for opening recall; 0 opens at swing start.
@export var trigger_distance: float = 0.0
## Damage taken when recall expires without an ability (design section 4).
@export var miss_damage: int = 0
