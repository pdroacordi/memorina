class_name SpawnArt
extends Resource
## A spawned attack's drawn strip: frames side by side, one texture px per game px (2x art), feet on the bottom row.
## A kind reads it as rise stages (`stage`) or as a loop (`loop_frame`); systems/guardians, GRD-18.

@export var texture: Texture2D
@export var frames: int = 1
## Frames per scaled s when the strip loops (a pod's spin); 0 holds frame 0.
@export var fps: float = 0.0


## The frame for a rise of `fraction` (0..1) through `count` stages, the last only when whole; -1 shows nothing.
static func stage_of(fraction: float, count: int) -> int:
	if fraction <= 0.0 or count <= 0:
		return -1
	return clampi(ceili(fraction * count) - 1, 0, count - 1)

## Px, one frame.
func frame_size() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(float(texture.get_width()) / maxi(frames, 1), float(texture.get_height()))

func stage(fraction: float) -> int:
	return stage_of(fraction, frames)

## The looping frame `t` scaled s in.
func loop_frame(t: float) -> int:
	if frames <= 1 or fps <= 0.0:
		return 0
	return posmod(floori(t * fps), frames)

## Where `frame` lands with its bottom-centre on `foot`, on the 2 px art grid; a negative width mirrors it.
func frame_rect(foot: Vector2, flip: bool) -> Rect2:
	var size := frame_size()
	var at := ((foot - Vector2(size.x * 0.5, size.y)) / 2.0).round() * 2.0
	if flip:
		return Rect2(at + Vector2(size.x, 0.0), Vector2(-size.x, size.y))
	return Rect2(at, size)

## Draws `frame` on `canvas` with its bottom-centre on `foot`; nothing for a negative frame.
func draw_frame(canvas: CanvasItem, frame: int, foot: Vector2, flip: bool = false) -> void:
	if texture == null or frame < 0:
		return
	var size := frame_size()
	canvas.draw_texture_rect_region(texture, frame_rect(foot, flip), Rect2(Vector2(size.x * frame, 0.0), size))
