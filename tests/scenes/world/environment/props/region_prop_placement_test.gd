class_name RegionPropPlacementTest extends GdUnitTestSuite

## Every grounded prop placed in a guardian region stands on the top of a ground cell, with open air in the cell above its
## origin, so no prop floats and none is drawn inside the ground it should stand on (WORLD-15..17;
## bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere).

const REGIONS := ["frozen_lake", "wind_orchards", "summer_caldera"]
const ROOMS_DIR := "res://scenes/world/rooms"
const PROPS_DIR := "res://scenes/world/environment/props/"
const ENVIRONMENT_DIR := "res://scenes/world/environment/"
## Props whose origin is not a foot on a ground cell, by scene path below PROPS_DIR (an inhabitant below
## ENVIRONMENT_DIR), each with where it is set.
const NOT_ON_GROUND := {
	"frozen_lake/frost_moss": "grows on a wall face",
	"frozen_lake/pier_post": "stands in the lake, its origin at the waterline",
	"frozen_lake/border_cairn": "covers the seam on the two wall tops, its foot behind their top tiles",
	"wind_orchards/ivy": "grows on a wall face",
	"wind_orchards/well_head": "spans orchard_mill_town's shaft, its drum's two ends on the lips",
	"summer_caldera/sun_tablet": "set in the back wall",
	"summer_caldera/sun_relief": "set in the back wall",
}


func _contents_scenes() -> Array[String]:
	var found: Array[String] = []
	for region: String in REGIONS:
		var dir := ROOMS_DIR.path_join(region).path_join("contents")
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with("_contents.tscn"):
				found.append(dir.path_join(file))
	return found


func test_every_grounded_prop_stands_on_a_ground_cell_top() -> void:
	var problems := PackedStringArray()
	var checked := 0
	for path: String in _contents_scenes():
		var contents := (load(path) as PackedScene).instantiate()
		var props := contents.get_node_or_null(^"Props")
		var map := (contents.get_node(^"RoomMap") as RoomMapNode).map
		if props != null:
			for prop: Node in props.get_children():
				var key := prop.scene_file_path.trim_prefix(PROPS_DIR).trim_prefix(ENVIRONMENT_DIR).get_basename()
				if not prop is Sprite2D or prop.scene_file_path.is_empty():
					continue
				if key in PropGroundingTest.HUNG or key in NOT_ON_GROUND:
					continue
				var at := (prop as Sprite2D).position
				var cell := Vector2i(floori(at.x / RoomMap.CELL_PX), floori(at.y / RoomMap.CELL_PX))
				var room := path.get_file().trim_suffix("_contents.tscn")
				if fmod(at.y, RoomMap.CELL_PX) != 0.0:
					problems.append("%s %s: y %s is not on a cell's top" % [room, prop.name, at.y])
				elif not (map.is_solid(cell) or map.is_platform(cell)):
					problems.append("%s %s: nothing under its foot at cell %s" % [room, prop.name, cell])
				elif map.is_solid(cell + Vector2i.UP):
					problems.append("%s %s: its foot is inside the ground at cell %s" % [room, prop.name, cell + Vector2i.UP])
				checked += 1
		contents.free()
	assert_int(checked).is_greater(0)
	assert_array(Array(problems)).is_empty()
