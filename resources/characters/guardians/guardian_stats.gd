class_name GuardianStats
extends Resource
## Guardian-specific fight parameters; see docs/design/02_mecanicas.md section 3.

@export var id: Enums.Guardian = Enums.Guardian.FROST
## Song taught when this guardian is restored.
@export var song: Song
@export var attacks: Array[GuardianAttack] = []

@export_group("Lucidity")
## Hits in the pressure phase before lucidity opens.
@export var hits_to_open: int = 5
## Good answers needed to restore the guardian.
@export var cycles_to_restore: int = 2
## Seconds before pressure resumes after an answer; failed answers use GuardianFight.FAILED_RELAPSE_SCALE.
@export var relapse_time: float = 1.4
## Seconds between lucidity opening and the first call note.
@export var call_lead_in: float = 0.7
## Extra answer time in seconds beyond the call length.
@export var window: float = 3.0
## Number of call notes shown on the sheet; fewer notes leave the tail to ear.
@export_range(0, 6) var revealed_notes: int = 6

@export_group("Recall")
## Ordinary attacks between recalls; a recall also occurs as soon as the pressure threshold is met.
@export var recall_after_attacks: int = 3

@export_group("Movement")
## Desired spacing in world pixels during cooldown; 0 disables pacing.
@export var comfort_distance: float = 140.0
## Seconds a pacing direction lasts before it changes.
@export var pace_time: float = 0.9
## Fraction of walking speed used while pacing (0..1).
@export_range(0.0, 1.0) var pace_speed: float = 0.5
## Walking speed multiplier while stepping away from an overlapping player.
@export var step_out_speed: float = 1.7

@export_group("Counter")
## Consecutive hits before an immediate counter; 0 disables counters.
@export var counter_after_hits: int = 3

@export_group("Aggression")
## Hits added to the next window threshold per failed answer.
@export var extra_hits_per_failure: int = 1
## Next answer-window duration multiplier per failed answer (0.1..1.0).
@export_range(0.1, 1.0) var window_scale_per_failure: float = 0.8
## Attack-cooldown multiplier per failed answer (0.1..1.0).
@export_range(0.1, 1.0) var cooldown_scale_per_failure: float = 0.8
## Maximum failures that increase aggression.
@export var max_aggression: int = 3

@export_group("Shield")
## Corrupted shield amount (0..1); approaches 1 as the cure advances.
@export_range(0.0, 1.0) var corrupted_shield_amount: float = 0.3
## Tremble frequency in Hz while the answer window is open.
@export var tremble_hz: float = 2.0
