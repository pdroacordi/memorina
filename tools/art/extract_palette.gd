extends SceneTree

## Extracts a ranked, merged palette from world art for process_image.gd.

const SOURCES: Array[String] = [
	"res://assets/sprites/world/tilesets/floor_tiles.png",
	"res://assets/sprites/world/background/seasonal/background_layer_1.png",
	"res://assets/sprites/world/background/seasonal/background_layer_2.png",
	"res://assets/sprites/world/background/seasonal/background_layer_3.png",
	"res://assets/sprites/world/background/seasonal/background_layer_4.png",
	"res://assets/sprites/world/background/seasonal/background_layer_5.png",
]
const OUTPUT := "res://tools/art/palette.json"
## Maximum number of colours retained.
const SIZE := 64
## ImageOps distance below which colours are merged.
const MERGE := 0.035

func _init() -> void:
	var counts := {}
	for path: String in SOURCES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		image.convert(Image.FORMAT_RGBA8)
		for y: int in image.get_height():
			for x: int in image.get_width():
				var c := image.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var key := Color(c.r, c.g, c.b).to_html(false)
				counts[key] = counts.get(key, 0) + 1
	var ranked := counts.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool: return counts[a] > counts[b])
	var palette := PackedColorArray()
	for key: String in ranked:
		var color := Color.html(key)
		var merged := false
		for kept: Color in palette:
			if ImageOps._distance(color, kept) < MERGE:
				merged = true
				break
		if not merged:
			palette.append(color)
		if palette.size() >= SIZE:
			break
	var hex: Array[String] = []
	for color: Color in palette:
		hex.append("#" + color.to_html(false))
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(hex, "  ") + "\n")
	file.close()
	print("Wrote %d colours to %s" % [hex.size(), OUTPUT])
	quit()
