class_name GuardianAttack
extends Resource
## Guardian attack tuning; `duration` must match the strike clip (architecture/grd-12-guardian-fight-engine).

## Strike slot, `attack_1..10` (GuardianAnimationResolver.ATTACK_CLIPS).
@export_range(0, 9) var clip_index: int = 0
## Wind-up slot played through `telegraph`; -1 plays IDLE.
@export_range(-1, 9) var windup_index: int = -1
@export var duration: float = 1.0
## Telegraph duration in seconds.
@export var telegraph: float = 0.4
## Attack range in px.
@export var attack_range: float = 64.0
## Vertical attack range in px; combined with `attack_range` as an axis-aligned box.
@export var attack_height: float = 96.0
@export var cooldown: float = 1.5
## Seconds standing after the string's last link, facing kept: the punish window.
@export var recovery: float = 0.0
## Recovery slot; -1 plays IDLE.
@export_range(-1, 9) var recovery_index: int = -1
## The cure stage at which the move joins the set (GuardianRepertoire.available).
@export var from_stage: int = 0
## The strike clip keys a hit window; false is a pure reposition or spawn move.
@export var strikes: bool = true
## Horizontal lunge speed in px/s, in the facing direction; ignored when `motion` is set.
@export var lunge_speed: float = 0.0
## Seconds into the swing before the lunge starts; a move without body contact starts it as its box opens.
@export var lunge_delay: float = 0.0
## Upward impulse in px/s; tune so airtime matches the attack clip. Ignored when `motion` is set.
@export var leap_impulse: float = 0.0
## Relative selection weight; recall attacks use GuardianStats.recall_after_attacks.
@export var weight: float = 1.0
## False keeps the move from being chosen right after a string it ended (a dash never follows a dash).
@export var repeats: bool = true
## The body hurts on touch during this move; false leaves the move's own box as its only hit (GRD-10).
@export var body_contact: bool = true
## Its dodge crosses the floor (a walk out of a shadow, a back-off): not chosen while the guardian's own floor patches
## burn (GuardianSpawner.floor_burning).
@export var waits_for_floor: bool = false
## Px past Ivo's live position the lunge stops, so a charge he rolled through ends near him; 0 runs to the clip's end.
@export var lunge_past: float = 0.0
## Thrown as a link against a wall, it winds up facing away from the wall, not Ivo (the Sun charge's bounce).
@export var turns_from_wall: bool = false
## String links, tried in order at the strike's end.
@export var follow_ups: Array[GuardianFollowUp] = []
## A reposition solved to fit `duration`; null keeps lunge_speed, lunge_delay and leap_impulse.
@export var motion: GuardianMotion
## Attacks fired during the strike.
@export var spawns: Array[GuardianSpawn] = []

@export_group("Hitbox")
@export var damage: int = 1
@export var knockback_strength: float = 420.0
## Upward knockback in px/s.
@export var knockback_lift: float = 120.0

@export_group("Gust")
## Px/s the move carries Ivo along the floor, away from the guardian, while it swings; 0 for none (GuardianGust).
@export var push_speed: float = 0.0
## Px above the guardian's feet the push reaches; past a jump's apex (144), so a body jumping at the wall stays pressed
## to it.
@export var push_height: float = 240.0

@export_group("Recall")
## Opens recall only while the player lacks this skill; the teaching attack is unavoidable.
@export var recall: AbilityRecallStats
## Scaled s before the lunge brings the box within `recall_reach` of Ivo at which the recall opens; 0 leaves it to
## the recall's own cue. Long enough to react, short enough that a press's grace covers the blow.
@export var recall_lead: float = 0.0
## Px from the guardian's centre at which the lunging box first touches Ivo; read with `recall_lead`.
@export var recall_reach: float = 0.0
## Pick weight once the recall's skill is owned: the move leaves the recall cadence; negative keeps it on the cadence.
@export var owned_weight: float = -1.0
## Damage once the recall's skill is owned; negative keeps `damage`.
@export var owned_damage: int = -1


## Whether the move leaves the recall cadence once its skill is owned.
func leaves_cadence_when_owned() -> bool:
	return recall != null and owned_weight >= 0.0

## Pick weight; `owned` says whether the player owns the recall's skill.
func weight_for(owned: bool) -> float:
	return owned_weight if owned and leaves_cadence_when_owned() else weight

## Scaled s until the lunge brings the box within `recall_reach` of an Ivo `distance` px away, `elapsed` s into the
## strike; 0 once it has.
func seconds_to_blow(elapsed: float, distance: float) -> float:
	var wait := maxf(lunge_delay - elapsed, 0.0)
	return wait + maxf(distance - recall_reach, 0.0) / maxf(lunge_speed, 1.0)

## Hit damage; `owned` says whether the player owns the recall's skill.
func damage_for(owned: bool) -> int:
	return owned_damage if owned and recall != null and owned_damage >= 0 else damage
