class_name PulseStats extends Resource

## Timing and reach parameters for a colour pulse (docs/design/03_mundo_e_ambiente.md section 3.1).

@export var max_radius: float = 160.0
## Expansion time, in seconds.
@export var attack_time: float = 0.25
## Sustain duration, in seconds.
@export var sustain_time: float = 3.0
## Contraction time at memory 1, in seconds.
@export var contract_time: float = 1.5
## Fraction of contraction time retained at memory 0.
@export_range(0.05, 1.0) var contract_min_factor: float = 0.4
