class_name EngravingMath
extends RefCounted
## Where an engraved still's window, layers, dither and caption stand at a time into the frame; pure, so tests and
## EngravingView share it (architecture/story-04-bearer-fragments, "The look").

## Art px of the view between the bars (640x288 game px at 2x).
const VIEW := Vector2(320.0, 144.0)
## Game px per art px; never a zoom, since a non-integer scale draws uneven pixels.
const ART_SCALE := 2.0
## Scaled seconds the caption takes to appear after the frame has come in.
const CAPTION_IN := 0.5
## Scaled seconds before the frame's end the caption is gone.
const CAPTION_OUT := 0.4


## Scaled seconds the frame takes to come in: from bare paper, or over the frame before it (`dissolve`).
static func entry_seconds(frame: EngravingFrame, dissolve: bool) -> float:
	return maxf(frame.dissolve_seconds if dissolve else frame.reveal_seconds, 0.0)

## Art px: the window's top-left at `t` scaled seconds, eased in-out over the frame and snapped to whole game px.
static func window(frame: EngravingFrame, t: float) -> Vector2:
	var weight := _ease(_fraction(t, frame.seconds))
	return _snap(frame.pan_from.lerp(frame.pan_to, weight))

## Art px: the window's top-left on `layer`'s canvas, which follows `depth` of the pan.
static func layer_window(frame: EngravingFrame, layer: EngravingLayer, t: float) -> Vector2:
	return _snap(frame.pan_from.lerp(window(frame, t), layer.depth))

## Art px the layer's ink has scrolled, whole and wrapped to its cell; zero for a layer with grey.
static func scroll(layer: EngravingLayer, t: float) -> Vector2:
	if not layer.ink_only or layer.drift == Vector2.ZERO:
		return Vector2.ZERO
	var size := cell_size(layer)
	var moved := (layer.drift * maxf(t, 0.0)).floor()
	return Vector2(fposmod(moved.x, size.x), fposmod(moved.y, size.y))

## The loop cell shown at `t`; 0 for a layer with grey.
static func cell(layer: EngravingLayer, t: float) -> int:
	if not layer.ink_only or layer.hframes <= 1 or layer.fps <= 0.0:
		return 0
	return int(floorf(maxf(t, 0.0) * layer.fps)) % layer.hframes

## Art px of one cell of the layer's canvas.
static func cell_size(layer: EngravingLayer) -> Vector2:
	if layer.texture == null:
		return Vector2.ZERO
	var size := layer.texture.get_size()
	return Vector2(size.x / float(maxi(layer.hframes, 1)), size.y)

## 0..1 of the frame dithered in at `t`.
static func shown(frame: EngravingFrame, dissolve: bool, t: float) -> float:
	var entry := entry_seconds(frame, dissolve)
	if entry <= 0.0:
		return 1.0
	return _fraction(t, entry)

## 0..1 of the caption: in over CAPTION_IN once the frame has come in, out over CAPTION_OUT before its end.
static func caption_alpha(frame: EngravingFrame, dissolve: bool, t: float) -> float:
	var start := entry_seconds(frame, dissolve)
	var rise := _fraction(t - start, CAPTION_IN)
	var fall := _fraction(frame.seconds - t, CAPTION_OUT)
	return minf(rise, fall)

## Whether every window the pan passes keeps the view inside every layer's cell.
static func fits(frame: EngravingFrame) -> bool:
	if frame.layers.is_empty():
		return false
	for layer: EngravingLayer in frame.layers:
		var room := cell_size(layer) - VIEW
		# The snapped windows layer_window draws; the eased pan is monotone, so its ends bound it.
		for corner: Vector2 in [layer_window(frame, layer, 0.0), layer_window(frame, layer, frame.seconds)]:
			if corner.x < 0.0 or corner.y < 0.0 or corner.x > room.x or corner.y > room.y:
				return false
	return true

static func _fraction(t: float, span: float) -> float:
	if span <= 0.0:
		return 1.0
	return clampf(t / span, 0.0, 1.0)

static func _ease(x: float) -> float:
	return ease(x, -2.0)

static func _snap(art: Vector2) -> Vector2:
	return (art * ART_SCALE).round() / ART_SCALE
