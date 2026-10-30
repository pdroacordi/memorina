class_name GustStream extends Node2D

## Draws the leaves a GuardianGust blows along the floor, in front of its guardian, while it blows. Script-owned, never
## keyed; its flecks move on the pausable scaled clock.

## Px the stream reaches in front of the guardian.
@export var reach: float = 1280.0
## Px of floor band the leaves fly in, above the feet.
@export var band_height: float = 32.0
## Px/s the leaves fly.
@export var speed: float = 900.0
## Leaves in the stream at once.
@export var leaf_count: int = 64
## Light and dark leaves: the stream must read in value alone, since the grey keeps only that (systems/greyhush).
@export var colours: PackedColorArray = PackedColorArray([
	Color("f0d9a0"), Color("5e3219"), Color("e8b860"), Color("8a4022"),
])

## Seconds the stream has blown, on the scaled clock.
var _clock: float = 0.0

@onready var _gust: GuardianGust = $"../GuardianGust"
@onready var _guardian: Guardian = get_parent()


## The band the leaves fill, in world px; what the gust's hit box must stay inside (combat_reach_test).
func drawn_rect() -> Rect2:
	var left := 0.0 if _guardian.facing > 0 else -reach
	return Rect2(global_position + Vector2(left, -band_height), Vector2(reach, band_height))

func _physics_process(delta: float) -> void:
	var blowing := _gust.is_blowing()
	_clock = _clock + delta if blowing else 0.0
	if blowing or visible:
		visible = blowing
		queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var side := float(_guardian.facing)
	for i: int in leaf_count:
		# Each leaf has its own lane and offset, so the stream reads as many leaves, not a line.
		var lane := fposmod(float(i) * 0.618, 1.0)
		# Snapped to the 2 px art grid.
		var x := snappedf(fposmod(float(i) * 97.0 + _clock * speed * (0.7 + 0.3 * lane), reach), 2.0)
		var y := snappedf(-2.0 - lane * (band_height - 6.0) - 2.0 * sin(_clock * 9.0 + float(i)), 2.0)
		var leaf := Rect2(Vector2(side * x - 3.0, y - 2.0), Vector2(6.0, 2.0 + 2.0 * float(i % 2)))
		draw_rect(leaf, colours[i % colours.size()])
