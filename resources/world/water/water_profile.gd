class_name WaterProfile extends Resource

## How a body of water MOVES: its surface springs, the ambient swell that
## drives it, and how hard a body landing in it splashes. How it LOOKS is a
## WaterLook; a still pond and a mountain stream are two of these .tres files
## over the same scenes (Strategy). See docs/design/03_mundo_e_ambiente.md §6.
##
## Every rate here is at full memory. A column's clock runs at the memory field's
## value over it, with no threshold: grey water moves at the fraction of speed
## the place is still remembered, and is fully still only at exactly zero.

## Width of one simulated column, in world pixels. The waterline is stepped per
## column, so this is also the width of each step.
@export_range(1, 8) var column_width: int = 2

@export_group("Springs")
## Pull of each column back toward the ambient swell, per second squared.
@export var stiffness: float = 25.0
## Energy lost per second. Higher settles a splash sooner.
@export var damping: float = 2.0
## Coupling to the neighbouring columns, per second squared. Ripples travel at
## roughly sqrt(spread) columns per second.
@export var spread: float = 2000.0
## Damping of each column's velocity against its neighbours', per second. It
## leaves a wave alone and kills the alternating column-by-column zig-zag -
## the lattice's highest mode - which otherwise rings as a comb of 1 px teeth.
@export var viscosity: float = 4.0
## Longest single integration step. A frame is split into sub-steps no longer
## than this, which keeps a stiff, fast-spreading surface stable.
@export var max_substep: float = 1.0 / 120.0

@export_group("Swell")
## Height of the ambient swell in world pixels. Keep it small: at this
## resolution a 2 px wave is a big, readable wave.
@export var wave_amplitude: float = 1.0
## Wavelength of the swell's main component, in world pixels.
@export var wave_length: float = 96.0
## How fast the swell's main component travels, in world pixels per second.
@export var wave_speed: float = 24.0

@export_group("Splash")
## Slowest fall into the water that splashes at all, in pixels per second.
@export var splash_min_speed: float = 120.0
## Depth of the dent per pixel-per-second of impact speed.
@export var splash_depth_per_speed: float = 0.012
@export var splash_max_depth: float = 6.0
## Width of the splash, in columns: the dent spans about this many either side
## of the impact and the crest rises just beyond it. Wide and smooth on purpose -
## a dent one column wide is almost all zig-zag and never reads as a mound.
@export_range(1, 8) var splash_half_width: int = 3
## Wake raised per pixel-per-second of a body wading through, per second.
@export var wake_per_speed: float = 0.02
