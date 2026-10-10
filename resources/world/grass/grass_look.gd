@tool
class_name GrassLook
extends Resource
## A look's generated grass: its palette and, per season band, how dense and tall its blades are (architecture/generated-grass).

## Tallest blade in art px; the shader's loop bound: must match MAX_BLADE_ART in grass_blades.gdshader.
const MAX_BLADE_ART := 8

## Shades dark to lit across, one row per band (spring, autumn, winter); written by tools/art/assemble_tile_sheet.gd.
@export var palette: Texture2D
## Band per Enums.Season (WINTER, SUMMER, AUTUMN, SPRING).
@export var band_of_season: Vector4i = Vector4i(2, 0, 1, 0)
## Share of art columns (0..1) that root a blade, per band (spring, autumn, winter).
@export var density: Vector3 = Vector3(0.7, 0.45, 0.0)
## Blade height in art px per band, min and max.
@export var height_min: Vector3i = Vector3i(3, 2, 0)
@export var height_max: Vector3i = Vector3i(7, 5, 0)
## Share of blades (0..1) drawn in front of the characters; 0 draws none.
@export_range(0.0, 1.0) var front_share: float = 0.25
## Height of a front blade relative to its back height (0..1).
@export_range(0.0, 1.0) var front_height: float = 0.6
## Art px at an open run end kept bare, so the rounded corner shows.
@export var corner_free: int = 2
@export var profile: GrassProfile


## Developer diagnostics; empty when the look is usable.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if palette == null:
		found.append("no palette")
	elif palette.get_height() != 3:
		found.append("palette has %d rows, not 3 (one per band)" % palette.get_height())
	if profile == null:
		found.append("no profile")
	elif profile.lean * float(maxi(height_max.x, height_max.y)) > MAX_BLADE_ART:
		found.append("a bent blade leans %.1f art px, past MAX_BLADE_ART" % (profile.lean * float(maxi(height_max.x, height_max.y))))
	for band: int in 3:
		if height_max[band] > MAX_BLADE_ART or height_min[band] > height_max[band]:
			found.append("band %d heights %d..%d are off 0..%d" % [band, height_min[band], height_max[band], MAX_BLADE_ART])
	return found
