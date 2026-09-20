class_name GuardianStats
extends Resource
## Everything that makes one guardian's fight different from another's:
## which song it teaches, how it attacks, how much pressure opens a lucidity
## window and how many good answers restore it. See
## docs/design/02_mecanicas.md section 3.

@export var id: Enums.Guardian = Enums.Guardian.FROST
## The phrase it calls in a lucidity window is this song's sequence, and
## restoring it teaches this song.
@export var song: Song
@export var attacks: Array[GuardianAttack] = []

@export_group("Lucidity")
## Hits taken in the pressure phase before a lucidity window opens.
@export var hits_to_open: int = 5
## Good answers needed to restore the guardian.
@export var cycles_to_restore: int = 2
## Seconds of slack the player has to answer beyond the phrase's own length:
## the window is the time the call took to sound, plus this.
@export var window: float = 3.0
## How many of the phrase's notes are drawn on the sheet as the call sounds.
## The full count is a literal call; fewer is the fragmented call of a more
## corrupted guardian, whose tail must be caught by ear.
@export_range(0, 6) var revealed_notes: int = 6

@export_group("Recall")
## How many ordinary attacks the guardian makes before its unavoidable move
## comes: the recall is a phase of the fight, not a roll of the dice. It keeps
## coming at this cadence until the skill is remembered.
@export var recall_after_attacks: int = 3

@export_group("Aggression")
## Every failed answer adds this many hits to the next window's threshold...
@export var extra_hits_per_failure: int = 1
## ...shrinks the next window by this factor...
@export_range(0.1, 1.0) var window_scale_per_failure: float = 0.8
## ...and shortens attack cooldowns by this factor.
@export_range(0.1, 1.0) var cooldown_scale_per_failure: float = 0.8
## Failures past this many stop making things worse.
@export var max_aggression: int = 3

@export_group("Shield")
## How much colour the corrupted guardian still holds (GreyhushShield.amount).
## It climbs toward 1.0 as the cure advances and flickers to 1.0 while lucid.
@export_range(0.0, 1.0) var corrupted_shield_amount: float = 0.3
## Flicker rate of the corrupted<->lucid tremble in a lucidity window.
@export var tremble_hz: float = 6.0
