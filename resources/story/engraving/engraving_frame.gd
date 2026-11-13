class_name EngravingFrame
extends Resource
## One engraved still of a bearer fragment: its layers, its captions and its slow pan (systems/cutscenes).

## Drawn in order, the first at the back; the base layer is opaque.
@export var layers: Array[EngravingLayer] = []
## 1-2 translation keys, shown together in the bottom bar.
@export var captions: Array[StringName] = []
## Scaled seconds the frame is on screen, its reveal or dissolve included.
@export var seconds: float = 6.5
## Art px: the view window's top-left on the canvas at the frame's start and end.
@export var pan_from: Vector2 = Vector2.ZERO
@export var pan_to: Vector2 = Vector2.ZERO
## Scaled seconds the frame takes to dither in from bare paper (the first frame).
@export var reveal_seconds: float = 1.5
## Scaled seconds the frame takes to dither in over the frame before it.
@export var dissolve_seconds: float = 1.0
