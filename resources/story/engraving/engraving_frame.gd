class_name EngravingFrame
extends Resource
## One engraved still of a bearer fragment: its layers, its captions and its slow pan (systems/cutscenes).

## Drawn in order, the first at the back; the base layer is opaque.
@export var layers: Array[EngravingLayer] = []
## Translation keys shown in the bottom bar: together (1-2), or one at a time with `caption_turns`.
@export var captions: Array[StringName] = []
## Shows the captions one at a time in equal shares of the frame after its entry.
@export var caption_turns: bool = false
## Scaled seconds the frame is on screen, its reveal or dissolve included.
@export var seconds: float = 6.5
## Art px: the view window's top-left on the canvas at the frame's start and end.
@export var pan_from: Vector2 = Vector2.ZERO
@export var pan_to: Vector2 = Vector2.ZERO
## Scaled seconds the frame takes to dither in from bare paper (the first frame).
@export var reveal_seconds: float = 1.5
## Scaled seconds the frame takes to dither in over the frame before it.
@export var dissolve_seconds: float = 1.0
## Art px the rows of its ink-only layers shift by at most, stepping with its mixed ink; 0 holds them still.
@export var tremble: float = 0.0
