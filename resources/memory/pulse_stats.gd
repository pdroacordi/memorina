class_name PulseStats extends Resource

## Shape of a colour pulse in time: it opens fast, holds while the player
## solves something, then the grey reconquers the space. See
## docs/design/03_mundo_e_ambiente.md section 3.1.
##
## Every song points at one shared instance today; a song that needs its own
## feel gets its own .tres without touching any code (Strategy).

@export var max_radius: float = 160.0
## The opening. Fast, because it is the player's read of how far the effect reaches.
@export var attack_time: float = 0.25
## The hold. This is the puzzle-solving window.
@export var sustain_time: float = 3.0
## The reconquest, at full regional memory. Accelerates rather than fading out.
@export var contract_time: float = 1.5
## How much of contract_time is left at memory 0: a pulse lit in a badly
## corroded area dies sooner, which makes the danger of a region legible in
## the very light the player switched on.
@export_range(0.05, 1.0) var contract_min_factor: float = 0.4
