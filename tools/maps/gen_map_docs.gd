extends Node

## Regenerates docs/maps/README.md sections from code; entity autoloads require running through the scene.

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
