class_name SeasonMask extends SubViewport

## Renders the season ownership mask for seasonal materials in one game-resolution pass (see season_mask.gdshader).

## Surface drawn by this viewport; rendering settings are authored in season_mask.tscn.
@onready var _surface: ColorRect = $Surface

func _process(_delta: float) -> void:
	# Match the greyhush pass resolution so mask pixels align with game pixels.
	size = Vector2i(get_tree().root.get_visible_rect().size)
	_surface.size = Vector2(size)

## The material the renderer feeds. Null until the scene is ready.
func mask_material() -> ShaderMaterial:
	return _surface.material as ShaderMaterial
