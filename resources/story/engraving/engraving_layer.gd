class_name EngravingLayer
extends Resource
## One picture layer of an engraved still: grey paper and key ink (#FF00FF), or ink alone (systems/cutscenes).

@export var texture: Texture2D
## 0..1: the fraction of the frame's pan this layer follows; below 1 it lags, which reads as depth.
@export_range(0.0, 1.0) var depth: float = 1.0
## Only the key ink draws; every other texel is transparent.
@export var ink_only: bool = false
## Art px/s the ink scrolls inside its tileable canvas; ink-only layers only, because the grey never moves.
@export var drift: Vector2 = Vector2.ZERO
## Cells laid side by side in `texture`, played as a loop at `fps`; ink-only layers only.
@export_range(1, 16) var hframes: int = 1
## Cells per scaled second; 0 holds the first.
@export var fps: float = 0.0
