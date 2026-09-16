extends SceneTree

## Builds the stacked seasonal background sheets the game draws from.
##
## Art is authored one season per file under
## assets/sprites/world/background/<season>/<season>_background_layer_N.png.
## The seasonal_art shader wants one sheet per layer with the seasons stacked
## vertically in equal bands, so this script blits them together into
## assets/sprites/world/background/seasonal/background_layer_N.png.
##
## Band order is spring, autumn, winter - the same order floor_tiles.png uses -
## and is declared to the shader by each background_layer_N_material.tres in
## scenes/world/memory/seasonal/. A season
## whose file is missing falls back to spring, so the pipeline runs before the
## art lands; the console says which ones were stood in for.
##
## Run from the project root:
##   "<godot>" --headless --path . -s res://tools/stack_seasonal_sheets.gd

const SOURCE_DIR := "res://assets/sprites/world/background"
const OUTPUT_DIR := "res://assets/sprites/world/background/seasonal"
const LAYERS := 5
## Top to bottom. Must agree with band_of_season in every
## background_layer_N_material.tres.
const BANDS: Array[String] = ["spring", "autumn", "winter"]
const FALLBACK := "spring"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	for layer: int in range(1, LAYERS + 1):
		_stack_layer(layer)
	quit()

func _stack_layer(layer: int) -> void:
	var images: Array[Image] = []
	for band: String in BANDS:
		var path := _source_path(band, layer)
		if not FileAccess.file_exists(path):
			print("  layer %d: no %s art yet, standing in with %s" % [layer, band, FALLBACK])
			path = _source_path(FALLBACK, layer)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert(image != null, "Could not load %s" % path)
		images.append(image)

	var width := images[0].get_width()
	var height := images[0].get_height()
	for image: Image in images:
		assert(image.get_width() == width and image.get_height() == height,
			"Every season of layer %d must be the same size; the shader divides the sheet into equal bands." % layer)

	var sheet := Image.create_empty(width, height * images.size(), false, Image.FORMAT_RGBA8)
	for i: int in images.size():
		var image: Image = images[i]
		image.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(image, Rect2i(0, 0, width, height), Vector2i(0, i * height))

	var out := "%s/background_layer_%d.png" % [OUTPUT_DIR, layer]
	var err := sheet.save_png(ProjectSettings.globalize_path(out))
	assert(err == OK, "Could not write %s" % out)
	print("wrote %s (%dx%d)" % [out, width, height * images.size()])

func _source_path(season: String, layer: int) -> String:
	return "%s/%s/%s_background_layer_%d.png" % [SOURCE_DIR, season, season, layer]
