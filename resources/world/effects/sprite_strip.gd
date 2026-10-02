class_name SpriteStrip extends Resource

## SpriteBursts animation strip with equal-width frames.

@export var texture: Texture2D
@export var frames := 1
## Lifetime in seconds.
@export var life := 0.3
## Loop rate in frames/s; 0 plays once over the lifetime.
@export var fps := 0.0
## Position anchor within the frame, 0..1.
@export var anchor := Vector2(0.5, 1.0)
## Fraction of its lifetime used for fading, 0..1.
@export_range(0.0, 1.0) var fade := 0.0

func frame_size() -> Vector2:
	return Vector2(texture.get_width() / float(frames), texture.get_height())
