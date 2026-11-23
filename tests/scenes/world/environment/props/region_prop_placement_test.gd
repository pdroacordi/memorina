class_name RegionPropPlacementTest extends GdUnitTestSuite

## Every prop placed in a dressed region stands where its art says it does (WORLD-12..17;
## bugs/guardian-region-props-placed-inside-ground-cells-draw-nowhere,
## bugs/the-threshold-field-tree-and-a-wayshrine-snow-heap-overhang-their-step-edges). A grounded prop's whole foot is
## on the top of ground or a ledge; a hung prop touches the drawn ground it hangs from; every other placement is listed in
## PLACED with what holds it. No prop covers an entity or a secret unless COVERS says why.

const REGIONS := ["frozen_lake", "wind_orchards", "summer_caldera", "threshold", "frost_edge", "spring_woods"]
const ROOMS_DIR := "res://scenes/world/rooms"
const PROPS_DIR := "res://scenes/world/environment/props/"
const ENVIRONMENT_DIR := "res://scenes/world/environment/"
## Px a foot pixel may reach past the last one over ground (a trimmed fringe).
const FOOT_TOLERANCE := 2
## Placements that do not stand on their foot, by "<room>/<node>" (`*` matches the rest of a name), with what holds
## them. A reason starting "touch:" is checked: the prop's opaque pixels touch drawn ground (a solid cell, or a
## ledge's drawn plank).
const PLACED := {
	"lake_chasm/BorderCairn": "touch: covers the seam on the two wall tops, its foot behind their top tiles",
	"lake_fishing_village/PierPost*": "stands in the lake, its origin at the waterline",
	"lake_high_wall/FrostMoss*": "touch: grows on a wall face",
	"lake_icefall/FrostMoss*": "touch: grows on a wall face",
	"threshold_icefall_foot/FrostMoss*": "touch: grows on a wall face",
	"frost_cliffs/FrostMoss*": "touch: grows on a wall face",
	"orchard_arena/Ivy*": "touch: grows up a wall face",
	"orchard_crag/Ivy*": "touch: grows up a wall face",
	"orchard_mill_town/WellHead": "touch: spans the shaft, its drum's two ends on the lips",
	"orchard_mill_town/Windmill2Sails": "its hub, on the small mill house's front",
	"orchard_summit/GreatWindmillSails": "its hub, on the great windmill's cap",
	"caldera_arena/SunRelief": "set in the back wall",
	"caldera_seesaw/SunTablet": "set in the back wall",
	"caldera_sun_stair/SunTablet*": "set in the back wall",
	"caldera_temple_gate/SunTablet": "set in the back wall",
	"lake_fisher_hut/DriedFish": "its nail, on the hut's back wall",
	"lake_fisher_hut/JarShelf": "its brackets, on the hut's back wall",
	"lake_fisher_hut/RopePeg": "its peg, on the hut's back wall",
	"lake_fisher_hut/WallNet": "on the hut's back wall",
	"lake_fisher_hut/WallOars": "on the hut's back wall",
	"lake_fisher_hut/Window": "set in the hut's back wall",
	"orchard_inn/HerbsPears": "its nail, on the inn's back wall",
	"orchard_inn/MugShelf": "its brackets, on the inn's back wall",
	"orchard_inn/PearSign": "its chains, on the inn's back wall",
	"orchard_inn/Window*": "set in the inn's back wall",
	"threshold_farmhouse/CoatPeg8": "its peg, on the farmhouse's back wall by the door",
	"threshold_farmhouse/WallShelf1": "its legs, on the farmhouse's back wall",
	"threshold_farmhouse/Window0": "set in the farmhouse's back wall",
	"threshold_fields/CrowPerched": "perches on the scarecrow's arm (PropGroundingTest.SUPPORTED)",
	"threshold_fields/CrowLooking": "perches on a fence post (PropGroundingTest.SUPPORTED)",
	"frost_cliffs/StormLantern": "its nail, on the bench cave's [back] stone",
	"frost_wreck_hold/Lantern3": "its hook, on the hold's planked back wall",
	"woods_hut/AxeRack": "on the hut's back wall",
	"woods_hut/FurCoat": "its peg, on the hut's back wall",
	"woods_hut/JarShelf": "its brackets, on the hut's back wall",
	"woods_hut/Snowshoes": "their peg, on the hut's back wall",
	"woods_edge/TrunkSection": "stands on the trunk base (PropGroundingTest.SUPPORTED) and rises out of the top edge",
	"woods_crown/TrunkSection*": "rises from behind the crown's floor: woods_edge's trunk continued",
	"woods_crown/LeafCluster*": "a leaf mass round the trunk's top or under the branch",
	"woods_deep/ShelfFungus*": "touch: grows on the west wall face",
	"woods_hollow_tree/WoodKnot*": "touch: set in the heartwood under a knot ledge's wall end (WORLD-40)",
	"woods_hollow_tree/ResinStreak*": "touch: runs down the heartwood beside a wall",
}
## Placements whose art covers an entity or a secret cell, with why.
const COVERS := {
	"lake_ice_caves/IceCrack": "the crack is the secret's hint, drawn on it",
	"orchard_counterweights/PearLimb": "its roots stand behind the plate at (2, 20) (WORLD-42); open, found in the WORLD-12..14 review",
	"threshold_farmhouse/MealTable4": "the sword lies on the table (STORY-02)",
	"woods_canopy/Nest": "the nest is the cache's place (board: the nest at the nest slot)",
	"woods_edge/TrunkBase": "its roots pass behind the hut, whose front covers the doorway",
}
## Entities a prop may cover: zones that draw nothing and creatures, which move away.
const UNDRAWN := ["n", "l", "W", "t", "m", "C", "J", "N", "A", "Z", "B"]
## Cells an entity occupies upward from its own.
const TALL := {"E": 2, "X": 3}


func _contents_scenes() -> Array[String]:
	var found: Array[String] = []
	for region: String in REGIONS:
		var dir := ROOMS_DIR.path_join(region).path_join("contents")
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with("_contents.tscn"):
				found.append(dir.path_join(file))
	return found

func _placed(tag: String) -> String:
	for pattern: String in PLACED:
		if tag.match(pattern):
			return PLACED[pattern]
	return ""

## Room px of the sprite's opaque pixels in frame 0 of band 0.
func _opaque(sprite: Sprite2D) -> Array[Vector2i]:
	var image := sprite.texture.get_image()
	var size := Vector2i(image.get_width() / sprite.hframes, image.get_height() / sprite.vframes)
	var frame := image.get_region(Rect2i(Vector2i.ZERO, size))
	var left := sprite.position + sprite.offset - (Vector2(size) / 2.0 if sprite.centered else Vector2.ZERO)
	var found: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			if frame.get_pixel(x, y).a > 0.5:
				var column := size.x - 1 - x if sprite.flip_h else x
				found.append(Vector2i(int(left.x) + column, int(left.y) + y))
	return found

func _cell(at: Vector2i) -> Vector2i:
	return Vector2i(floori(at.x / float(RoomMap.CELL_PX)), floori(at.y / float(RoomMap.CELL_PX)))

func _holds(map: RoomMap, cell: Vector2i) -> bool:
	return map.is_solid(cell) or map.is_platform(cell)

## Px of a one-way ledge cell its art fills from the top (the biome sheet's ledge row); a full cell without art.
func _ledge_depth(map: RoomMap, cell: Vector2i) -> int:
	var look := map.look_at(cell)
	if look == RoomMap.NO_LOOK or map.biome == null or not map.biome.has_look(look as BiomeTileset.Look):
		return RoomMap.CELL_PX
	var image := map.biome.sheet(look as BiomeTileset.Look).get_image()
	var row := Rect2i(0, GroundAutotile.LEDGE_ROW * RoomMap.CELL_PX, image.get_width(), RoomMap.CELL_PX)
	var drawn := image.get_region(row).get_used_rect()
	return drawn.end.y if drawn.has_area() else RoomMap.CELL_PX

## Whether `at` (room px) is drawn ground: anywhere in a solid cell, only the drawn top of a ledge cell.
func _drawn_ground(map: RoomMap, at: Vector2i) -> bool:
	var cell := _cell(at)
	if map.is_solid(cell):
		return true
	return map.is_platform(cell) and at.y - cell.y * RoomMap.CELL_PX < _ledge_depth(map, cell)

## Whether the pixels touch drawn ground, so a prop hung under a ledge hangs from its plank, not the cell's bottom
## (bugs/woods-deep-hanging-moss-floats-under-its-ledge).
func _touches(map: RoomMap, pixels: Array[Vector2i]) -> bool:
	for at: Vector2i in pixels:
		for step: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if _drawn_ground(map, at + step):
				return true
	return false

## Foot pixels standing over neither ground nor a ledge, beyond FOOT_TOLERANCE of one that does.
func _overhang(map: RoomMap, pixels: Array[Vector2i], row: int) -> int:
	var bottom: int = -(1 << 30)
	for at: Vector2i in pixels:
		bottom = maxi(bottom, at.y)
	var held: Array[int] = []
	var loose: Array[int] = []
	for at: Vector2i in pixels:
		if at.y == bottom:
			if _holds(map, Vector2i(floori(at.x / float(RoomMap.CELL_PX)), row)):
				held.append(at.x)
			else:
				loose.append(at.x)
	var count := 0
	for x: int in loose:
		var near := false
		for h: int in held:
			if absi(x - h) <= FOOT_TOLERANCE:
				near = true
				break
		if not near:
			count += 1
	return count

func _covered_cells(map: RoomMap) -> Dictionary:
	var cells := {}
	for placed: Dictionary in map.entities:
		var symbol: String = placed.symbol
		if symbol in UNDRAWN:
			continue
		var tall: int = TALL.get(symbol, 1)
		for up: int in tall:
			cells[(placed.cell as Vector2i) + Vector2i(0, -up)] = symbol
	return cells

func test_every_prop_stands_hangs_or_is_held_where_it_is_placed() -> void:
	var problems := PackedStringArray()
	var checked := 0
	for path: String in _contents_scenes():
		var contents := (load(path) as PackedScene).instantiate()
		var props := contents.get_node_or_null(^"Props")
		var map := (contents.get_node(^"RoomMap") as RoomMapNode).map
		var room := path.get_file().trim_suffix("_contents.tscn")
		if props != null:
			for prop: Node in props.get_children():
				if not prop is Sprite2D or prop.scene_file_path.is_empty():
					continue
				var sprite := prop as Sprite2D
				var key := prop.scene_file_path.trim_prefix(PROPS_DIR).trim_prefix(ENVIRONMENT_DIR).get_basename()
				var tag := "%s/%s" % [room, prop.name]
				var reason := _placed(tag)
				var pixels := _opaque(sprite)
				checked += 1
				if reason.begins_with("touch:") or (reason.is_empty() and key in PropGroundingTest.HUNG):
					if not _touches(map, pixels):
						problems.append("%s: touches no ground or ledge" % tag)
					continue
				if not reason.is_empty():
					continue
				var at := sprite.position
				var cell := Vector2i(floori(at.x / RoomMap.CELL_PX), floori(at.y / RoomMap.CELL_PX))
				if fmod(at.y, RoomMap.CELL_PX) != 0.0:
					problems.append("%s: y %s is not on a cell's top" % [tag, at.y])
				elif not _holds(map, cell):
					problems.append("%s: nothing under its origin at cell %s" % [tag, cell])
				elif map.is_solid(cell + Vector2i.UP):
					problems.append("%s: its foot is inside the ground at cell %s" % [tag, cell + Vector2i.UP])
				else:
					var loose := _overhang(map, pixels, cell.y)
					if loose > 0:
						problems.append("%s: %d foot px stand over air" % [tag, loose])
		contents.free()
	assert_int(checked).is_greater(0)
	assert_array(Array(problems)).is_empty()

func test_no_prop_covers_an_entity_or_a_secret() -> void:
	var problems := PackedStringArray()
	for path: String in _contents_scenes():
		var contents := (load(path) as PackedScene).instantiate()
		var props := contents.get_node_or_null(^"Props")
		var map := (contents.get_node(^"RoomMap") as RoomMapNode).map
		var room := path.get_file().trim_suffix("_contents.tscn")
		var cells := _covered_cells(map)
		if props != null:
			for prop: Node in props.get_children():
				var tag := "%s/%s" % [room, prop.name]
				if not prop is Sprite2D or prop.scene_file_path.is_empty() or tag in COVERS:
					continue
				# A building's front holds its own door.
				if prop.scene_file_path.get_basename().ends_with("_facade"):
					continue
				var hit := {}
				for at: Vector2i in _opaque(prop as Sprite2D):
					var cell := _cell(at)
					if cells.has(cell):
						hit[cells[cell]] = true
					elif map.secret_at(cell) > 0:
						hit["secret"] = true
				if not hit.is_empty():
					problems.append("%s covers %s" % [tag, ", ".join(PackedStringArray(hit.keys()))])
		contents.free()
	assert_array(Array(problems)).is_empty()

func test_every_listed_placement_exists() -> void:
	var tags := PackedStringArray()
	for path: String in _contents_scenes():
		var contents := (load(path) as PackedScene).instantiate()
		var props := contents.get_node_or_null(^"Props")
		if props != null:
			for prop: Node in props.get_children():
				tags.append("%s/%s" % [path.get_file().trim_suffix("_contents.tscn"), prop.name])
		contents.free()
	for pattern: String in PLACED.keys() + COVERS.keys():
		var found := false
		for tag: String in tags:
			if tag.match(pattern):
				found = true
				break
		assert_bool(found).override_failure_message("%s is listed but placed nowhere" % pattern).is_true()
