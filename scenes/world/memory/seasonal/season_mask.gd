class_name SeasonMask extends SubViewport

## Renders the season mask: one byte per game pixel saying which pulse season
## owns it (see season_mask.gdshader), for every seasonal material to read.
##
## A SubViewport for the same reason CreatureMask is one: a texture is the
## only thing a world material can consume as a global uniform, and rendering
## the field once here is far cheaper than evaluating 32 sources inside every
## tile and background sprite. Unlike CreatureMask it does NOT share the world;
## it draws exactly one full-rect ColorRect carrying the mask material, at the
## game resolution, and nothing else.
##
## GreyhushRenderer pushes the field uniforms into `mask_material()` alongside
## the two colour passes and publishes `get_texture()` as the
## `greyhush_season_mask` global. This node knows nothing about either.

## The one child this viewport draws. Update mode, opacity and mouse filter
## are the scene's business (season_mask.tscn), not this script's.
@onready var _surface: ColorRect = $Surface

func _process(_delta: float) -> void:
	# Follows the game resolution the same way CreatureMask does, so a pixel
	# here is a pixel in the greyhush pass.
	size = Vector2i(get_tree().root.get_visible_rect().size)
	_surface.size = Vector2(size)

## The material the renderer feeds. Null until the scene is ready.
func mask_material() -> ShaderMaterial:
	return _surface.material as ShaderMaterial
