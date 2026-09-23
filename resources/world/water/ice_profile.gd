class_name IceProfile extends Resource

## How ice made by FREEZE grows, sets and thaws on a body of water. Numbers are
## still pending prototyping (design 02 §9); a puzzle that needs its own timing
## gets its own .tres (Strategy). See docs/design/03_mundo_e_ambiente.md §6.3-6.4.

enum ThawOrigin {
	## Melts outward from where the song was played: the ice goes BEHIND the
	## player, who must commit forward. The design's default.
	FROM_ORIGIN,
	## Melts inward from both banks, for a crossing that has to be walked back.
	FROM_EDGES,
}

@export_group("Growth")
## Speed of each ice front over living water, in world pixels per second. It is
## scaled by the memory under the front: ice needs moving water, so it crawls
## over grey water and stops dead where nothing is remembered.
@export var grow_speed: float = 160.0
## Seconds for a reached column to crystallise from open water to fully set,
## again at the memory's rate.
@export var crystallise_time: float = 0.35
## Crystallisation at which the surface is fully held - it has stopped answering
## splashes. Lower than solid_at on purpose: it hardens before it looks solid.
@export_range(0.05, 1.0) var harden_at: float = 0.35
## Crystallisation at which the ice is drawn solid AND carries weight.
@export_range(0.05, 1.0) var solid_at: float = 0.8

@export_group("Thaw")
@export var thaw_origin: ThawOrigin = ThawOrigin.FROM_ORIGIN
## Seconds after the song before the thaw front sets off. The design's crossing
## "starts to thaw as soon as it is made", so this is short.
@export var thaw_delay: float = 1.5
## Speed of the thaw front in world pixels per second. Slower than growth, or the
## ice would melt away before it reached the far bank.
@export var thaw_speed: float = 48.0
## Seconds for a column the thaw front has passed to melt back to open water.
## Thaw ignores memory: once made, the ice keeps its own clock.
@export var melt_time: float = 0.5

@export_group("Body")
## Width of one collision segment, in world pixels. A segment carries weight
## only while every column in it is solid.
@export_range(2, 32) var segment_width: int = 8
## How far below the waterline the ice reaches, in world pixels: the collider's
## thickness and the drawn band.
@export_range(1, 16) var thickness: int = 6
