class_name SpriteStrip extends Resource

## A short-lived sprite a SpriteBursts pool draws: a strip of equal frames side
## by side, played once across its life (or looped at `fps`), anchored at a
## point of the frame. A splash, a gust, a tumbling leaf.

@export var texture: Texture2D
@export var frames := 1
## Seconds it lives.
@export var life := 0.3
## Frames per second when it loops (a tumbling leaf); 0 plays the strip once
## across its life.
@export var fps := 0.0
## Where in the frame its position is, 0..1 (bottom-centre for a splash).
@export var anchor := Vector2(0.5, 1.0)
## The last part of its life it fades over, 0..1, in whole steps.
@export_range(0.0, 1.0) var fade := 0.0

func frame_size() -> Vector2:
	return Vector2(texture.get_width() / float(frames), texture.get_height())
