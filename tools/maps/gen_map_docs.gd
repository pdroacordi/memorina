extends Node

## Rewrites the generated sections of docs/maps/README.md (the legend, every
## entity's params, Ivo's reach) from the code. Run it after changing the
## legend, an entity's exports or Ivo's jump tuning; map_guide_test.gd fails
## until you do. A scene rather than a SceneTree script so the autoloads the
## entity scenes reference exist:
##   "<godot>" --headless --path . res://tools/maps/gen_map_docs.tscn

func _ready() -> void:
	var readme := FileAccess.get_file_as_string(MapGuide.README)
	var rendered := MapGuide.render(readme, RoomLegend.load_default())
	if rendered == readme:
		print("%s is up to date" % MapGuide.README)
	else:
		var file := FileAccess.open(MapGuide.README, FileAccess.WRITE)
		file.store_string(rendered)
		file.close()
		print("Rewrote the generated sections of %s" % MapGuide.README)
	get_tree().quit()
