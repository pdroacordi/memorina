class_name WaterLook extends Resource

## Defines water colours and reflection; computed colours use the scene palette and Bayer stippling (docs/design/03_mundo_e_ambiente.md §6.6).

@export_group("Palette")
## One texel per depth band; RGB is water colour and alpha is its opacity.
@export var body_ramp: Texture2D
## One texel per depth band; multiplies the view through water and submerged creatures.
@export var transmit_ramp: Texture2D
## One texel per depth band; RGB tints the reflection and alpha controls its strength.
@export var reflection_ramp: Texture2D
## Ice colours from the top of the band to its bottom.
@export var ice_ramp: Texture2D
## Colour of the top line, including when water is forgotten.
@export var top_line_color := Color(0.78, 0.88, 0.9)
## What an agitated waterline stipples toward.
@export var foam_color := Color(0.94, 0.97, 0.98)
## World pixels per depth band.
@export var depth_band_px: float = 6.0

@export_group("Reflection")
## Reflection strength at full memory; reflection fades with memory.
@export_range(0.0, 1.0) var reflection_strength: float = 0.85
## Number of flat posterisation levels for reflection strength.
@export_range(2, 8) var reflect_levels: int = 4
## Memory range over which the reflection stipples in, from absent to full.
@export_range(0.0, 1.0) var reflect_memory_low: float = 0.15
@export_range(0.0, 1.0) var reflect_memory_high: float = 0.6
## Rows per reflection band; each band shifts sideways by whole pixels.
@export_range(1, 8) var band_height: int = 2
## Largest sideways slide of a band, in world pixels.
@export_range(0, 4) var band_shift_max: int = 1
## Band slide rate, in radians per second of the water clock.
@export var band_speed: float = 1.3
## Width of the stipple that dissolves the reflection into the water's colour
## where it would read past the edge of the screen, in game pixels.
@export var edge_fade_px: float = 12.0

@export_group("Caustics")
## Caustic depth below the waterline, in world pixels; 0 disables caustics.
@export var caustic_depth: float = 10.0
## Width of one caustic band, in world pixels: coarse bands, not diffuse light.
@export_range(1, 8) var caustic_band_px: int = 3
## Caustic rerolls per second of the water clock.
@export var caustic_rate: float = 1.5
## Share of bands lit at any moment.
@export_range(0.0, 1.0) var caustic_density: float = 0.3
## Strength with which lit bands approach the top line colour.
@export_range(0.0, 1.0) var caustic_strength: float = 0.35

@export_group("Lake")
## Distance in world pixels over which reflection bands grow toward the viewer.
@export var perspective_px: float = 48.0
## Rows per reflection band nearest the viewer.
@export_range(1, 16) var band_height_near: int = 6
## Largest sideways slide of a band nearest the viewer, in world pixels.
@export_range(0, 8) var band_shift_near: int = 3
## Extra reflection reach is `d + stretch * d^2` world pixels below the far shore; it is 1:1 at the shore.
@export_range(0.0, 0.1, 0.001) var reflection_stretch: float = 0.0
## Fraction of ripple segments lit at the far shore; glints thin toward the viewer.
@export_range(0.0, 1.0) var glint_density: float = 0.12
## Longest glint, in world pixels. Each is 1 px tall.
@export_range(2, 24) var glint_length: int = 10
## Re-rolls per second of the water's clock.
@export var glint_rate: float = 0.8
## A glint's colour; alpha is how far the water lifts toward it.
@export var glint_color := Color(0.85, 0.92, 0.98, 0.7)
