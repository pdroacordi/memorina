class_name WaterLook extends Resource

## How a body of water LOOKS: its palette, its reflection and the texture of
## its light. How it moves is a WaterProfile. A clear pond and the dark
## foreground strip that mirrors the whole scene are two of these .tres files
## over the same shader (Strategy). See docs/design/03_mundo_e_ambiente.md §6.6:
## the water must look hand-drawn even though it is computed, so every colour
## the water makes itself comes from a LUT painted in the scene's palette, and
## every gradient is a Bayer stipple between two of its entries.

@export_group("Palette")
## One texel per depth band, top to bottom: rgb is the water's own colour, alpha
## how opaque that band is over whatever lies behind it.
@export var body_ramp: Texture2D
## One texel per depth band: what shows THROUGH the water is multiplied by it.
## Also what the veil multiplies a submerged creature by.
@export var transmit_ramp: Texture2D
## One texel per depth band: rgb darkens and cools the reflection, alpha is how
## strongly the reflection shows at that depth.
@export var reflection_ramp: Texture2D
## Ice, top of the band to its bottom.
@export var ice_ramp: Texture2D
## The one lighter pixel line along the top - drawn even when the water is
## forgotten ("uma chapa cinza com uma linha mais clara no topo").
@export var top_line_color := Color(0.78, 0.88, 0.9)
## What an agitated waterline stipples toward.
@export var foam_color := Color(0.94, 0.97, 0.98)
## World pixels per depth band.
@export var depth_band_px: float = 6.0

@export_group("Reflection")
## How strongly the world shows in the water at full memory. It fades with the
## memory at the water's own pixel: forgotten water does not reflect.
@export_range(0.0, 1.0) var reflection_strength: float = 0.85
## Levels the authored strength (reflection_strength x the ramp's alpha) is
## posterised to. Posterised, not dithered: a band's interior is one flat level.
@export_range(2, 8) var reflect_levels: int = 4
## Memory at which the reflection starts to stipple in, and at which it is
## whole. Between the two it dissolves - the water forgetting what is above it.
@export_range(0.0, 1.0) var reflect_memory_low: float = 0.15
@export_range(0.0, 1.0) var reflect_memory_high: float = 0.6
## Rows per horizontal band of the reflection. Each band slides sideways by
## whole pixels, never bends.
@export_range(1, 8) var band_height: int = 2
## Largest sideways slide of a band, in world pixels.
@export_range(0, 4) var band_shift_max: int = 1
## How fast the bands slide, in radians per second of the water's clock.
@export var band_speed: float = 1.3
## Width of the stipple that dissolves the reflection into the water's colour
## where it would read past the edge of the screen, in game pixels.
@export var edge_fade_px: float = 12.0

@export_group("Caustics")
## How far below the waterline caustics reach, in world pixels. 0 disables them.
@export var caustic_depth: float = 10.0
## Width of one caustic band, in world pixels: coarse bands, not diffuse light.
@export_range(1, 8) var caustic_band_px: int = 3
## Re-rolls per second of the water's clock.
@export var caustic_rate: float = 1.5
## Share of bands lit at any moment.
@export_range(0.0, 1.0) var caustic_density: float = 0.3
## How far a lit band lifts toward the top line colour.
@export_range(0.0, 1.0) var caustic_strength: float = 0.35
