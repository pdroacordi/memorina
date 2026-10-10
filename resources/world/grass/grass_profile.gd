@tool
class_name GrassProfile
extends Resource
## How grass moves, shared across biomes, as WaterProfile beside WaterLook (architecture/generated-grass).

## Pull of a blade back to its target, per second squared.
@export var stiffness: float = 160.0
## Velocity lost per second.
@export var damping: float = 10.0
## Bend (0..1) a body standing over a blade pushes it to.
@export_range(0.0, 1.0) var push: float = 0.85
## World px past a body's half width where its push fades to 0.
@export var reach: float = 8.0
## Sideways offset of a fully bent blade's tip, in blade heights.
@export var lean: float = 0.9
## Height lost by a fully bent blade (0..1).
@export_range(0.0, 1.0) var shorten: float = 0.35
## Bend of the idle sway, -amplitude..amplitude.
@export var sway_amplitude: float = 0.12
## Two sway frequencies, cycles per clock second.
@export var sway_hz: Vector2 = Vector2(0.31, 0.77)
