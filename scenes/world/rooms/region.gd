class_name Region extends Node2D

## The composition scene that places a region's rooms. Owns the one thing that
## belongs to the region rather than to any single room: how much of it is
## still remembered.
##
## A value, not a switch, deliberately - see
## docs/design/03_mundo_e_ambiente.md section 4.1. The home village opens at
## 0.8 (alive, but already thinning), is revisited lower, and returns to 1.0.

@export_range(0.0, 1.0) var memory_baseline: float = 0.8
