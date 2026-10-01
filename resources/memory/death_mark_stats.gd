class_name DeathMarkStats extends Resource

## How Ivo's deaths become marks of forgetting in a region (design 03, section
## 4.3, and the user's decisions of 2026-10-01). A mark is only a small
## negative MemorySource: the greyhush draws it as a grey disc with a dithered
## edge, which IS "um pequeno símbolo do cinzesquecimento". Deaths close
## together merge into one mark that deepens instead of multiplying.

## Deaths within this many pixels of a mark deepen it rather than leave their own.
@export var merge_distance: float = 48.0
## The most marks one region shows; past it a death deepens the nearest.
@export var max_marks: int = 6
## A mark of one death, and how much each further death adds, up to the cap.
@export var radius: float = 20.0
@export var radius_per_death: float = 4.0
@export var max_radius: float = 40.0
## How far the edge fades, outward from the core.
@export var feather: float = 24.0
## How much memory one death takes away (positive), deepening up to the cap.
## Small on purpose: never a mechanical punishment, only a corner that feels worse.
@export_range(0.0, 1.0) var strength: float = 0.3
@export_range(0.0, 1.0) var strength_per_death: float = 0.1
@export_range(0.0, 1.0) var max_strength: float = 0.6


func radius_for(deaths: int) -> float:
	return minf(radius + radius_per_death * (deaths - 1), max_radius)

func strength_for(deaths: int) -> float:
	return minf(strength + strength_per_death * (deaths - 1), max_strength)
