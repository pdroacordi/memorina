class_name PropGroundingTest extends GdUnitTestSuite

## Every grounded village and interior prop stands on its origin with no gap ("Many things on the game seem to just be
## flaoting", user, 2026-10-11), and each prop's drawn size matches its size table entry (systems/props).

const PROPS_DIR := "res://scenes/world/environment/props"
const GROUPS := ["village", "interiors"]
const VILLAGE_SIZES := "res://tools/art/village_prop_sizes.json"
const INTERIOR_SIZES := "res://tools/art/interior_prop_sizes.json"
## Art px a drawn size may differ from its table entry (a trimmed fringe or a PixelLab redraw).
const SIZE_TOLERANCE := 2
## Props whose origin is not a foot, each with what it hangs from: placement must keep that thing touching it.
const HUNG := {
	"village/bakery_lights": "the bakery front's panes",
	"village/elder_house_lights": "the elder's front's panes",
	"village/ivo_house_lights": "Ivo's front's panes",
	"village/mill_house_lights": "the mill front's panes",
	"village/notes_house_lights": "the house of notes' panes",
	"village/tavern_lights": "the tavern front's panes",
	"village/chimney_smoke": "a chimney top",
	"village/bunting": "hooked to the bell tower's stone and tied to the bunting pole",
	"village/flag": "its pole, planted on the tavern's ridge",
	"village/tavern_sign": "its chains, from the tavern front's iron bracket",
	"village/wall_lantern": "its bracket, on the tavern's stone wall",
	"village/water_wheel": "its hub, on the mill house's axle stub, foot in the river",
	"interiors/bakery/herb_rail": "the bakery wall",
	"interiors/bakery/wall_shelf_bowls": "the bakery wall",
	"interiors/elder_house/dried_flowers": "the elder's wall",
	"interiors/empty_house/cobweb_a": "a wall corner",
	"interiors/tavern_cellar/lantern": "the cellar wall",
	"interiors/tavern_cellar/wall_roots": "the cellar wall",
	"interiors/farmhouse/wall_shelf": "its legs, on the farmhouse wall",
	"interiors/farmhouse/window": "set in the wall",
	"interiors/mill_house/axle": "the east wall, the wheel's shaft through it",
	"interiors/mill_house/gear": "its hub, on the axle",
	"interiors/mill_house/hook_rope": "the ceiling",
	"interiors/mill_house/lantern": "its chain, on the hoist rope's hook",
	"interiors/mill_house/peg_rail": "the wall; the tools hang from its pegs",
	"interiors/notes_house/dog_lead": "its peg board's knob, on the wall",
	"interiors/notes_house/mirror": "its cord, on a nail",
	"interiors/notes_house/peg_rail": "the wall; the herbs and the bag hang from its pegs",
	"interiors/notes_house/note_cup": "pinned to the wall",
	"interiors/notes_house/note_dog": "pinned to the wall",
	"interiors/notes_house/note_heart": "pinned to the cupboard",
	"interiors/notes_house/note_key": "pinned to the wall",
	"interiors/notes_house/note_sun": "pinned to the chimney breast",
	"interiors/notes_house/note_tree": "pinned to the window frame",
	"interiors/notes_house/recipe": "its string, on a nail",
	"interiors/notes_house/tally_calendar": "its string, on a nail",
	"interiors/notes_house/wall_shelf": "its brackets, on the wall",
	"interiors/notes_house/window": "set in the wall",
}
## Placed hung props whose support is another sprite: [contents scene, hung node, support node] under `Props`. Their
## opaque pixels must overlap or touch (bugs/the-square-bunting-hangs-in-the-air-short-of-the-bell-tower).
const SUPPORTED := [
	["res://scenes/world/rooms/home_village/contents/village_square_contents.tscn", "Bunting", "BellTowerFacade"],
	["res://scenes/world/rooms/home_village/contents/village_square_contents.tscn", "Bunting", "BuntingPole"],
	["res://scenes/world/rooms/home_village/contents/village_square_contents.tscn", "TavernSign", "TavernFacade"],
	["res://scenes/world/rooms/home_village/contents/village_square_contents.tscn", "WallLantern", "TavernFacade"],
	["res://scenes/world/rooms/home_village/contents/village_square_contents.tscn", "Flag", "TavernFacade"],
	["res://scenes/world/rooms/home_village/contents/village_mill_contents.tscn", "WaterWheel", "MillHouseFacade"],
	["res://scenes/world/rooms/home_village/contents/village_mill_house_contents.tscn", "Lantern", "HookRope"],
	["res://scenes/world/rooms/home_village/contents/village_mill_house_contents.tscn", "Gear", "Axle"],
]
## Props stretched to the ceiling after their cut (tools/art/stretch_prop.py): only their width keeps the table's size.
const STRETCHED := ["interiors/mill_house/hook_rope"]
## Known misfits, each with its reason.
const SIZE_EXCEPTIONS := {
	"interiors/bakery/chalkboard": "the cut lost its hanging cord: 8 drawn art px under its h11 box (found by WORLD-11)",
}


## Prop scene paths under `dir`, keyed by their path below PROPS_DIR without the extension.
func _scenes(dir: String, found: Dictionary) -> Dictionary:
	for sub: String in DirAccess.get_directories_at(dir):
		_scenes(dir.path_join(sub), found)
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "tscn":
			var path := dir.path_join(file)
			found[path.trim_prefix(PROPS_DIR + "/").get_basename()] = path
	return found

func _all() -> Dictionary:
	var found := {}
	for group: String in GROUPS:
		_scenes(PROPS_DIR.path_join(group), found)
	return found

## Frame 0 of band 0 of the sprite's texture.
func _frame(sprite: Sprite2D) -> Image:
	var image := sprite.texture.get_image()
	var size := Vector2i(image.get_width() / sprite.hframes, image.get_height() / sprite.vframes)
	return image.get_region(Rect2i(Vector2i.ZERO, size))

func test_every_grounded_prop_stands_on_its_origin() -> void:
	var problems := PackedStringArray()
	var checked := 0
	var all := _all()
	for key: String in all:
		if key in HUNG:
			continue
		var sprite := (load(all[key]) as PackedScene).instantiate() as Sprite2D
		var frame := _frame(sprite)
		var bottom := frame.get_height() - 1
		var touches := false
		for x: int in frame.get_width():
			if frame.get_pixel(x, bottom).a > 0.5:
				touches = true
				break
		if not touches:
			problems.append("%s: its bottom row is empty, so it floats" % key)
		if sprite.offset.y + frame.get_height() != 0.0:
			problems.append("%s: offset.y %s does not put its bottom row on the origin" % [key, sprite.offset.y])
		if sprite.offset.x > 0.0 or sprite.offset.x < -frame.get_width():
			problems.append("%s: offset.x %s leaves the origin outside the sprite" % [key, sprite.offset.x])
		checked += 1
		sprite.free()
	assert_int(checked).is_greater(0)
	assert_array(Array(problems)).is_empty()

func test_every_hung_prop_exists() -> void:
	var all := _all()
	for key: String in HUNG:
		assert_bool(all.has(key)).override_failure_message("%s is listed as hung but has no scene" % key).is_true()

func test_every_sized_prop_matches_its_table() -> void:
	var problems := PackedStringArray()
	var checked := 0
	var all := _all()
	for table: Array in [[VILLAGE_SIZES, "village/%s"], [INTERIOR_SIZES, "interiors/%s/%s"]]:
		var sheets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(table[0]))
		for sheet: String in sheets:
			if sheet == "about" or sheet.ends_with("_ratio"):
				continue
			for entry: String in (sheets[sheet] as String).split(","):
				var parts := entry.split(":")
				var key: String = table[1] % parts[0] if table[0] == VILLAGE_SIZES else table[1] % [sheet, parts[0]]
				if not all.has(key):
					problems.append("%s: in %s but has no scene" % [key, table[0]])
					continue
				if (parts[1].begins_with("h") and key in STRETCHED) or SIZE_EXCEPTIONS.has(key):
					continue
				var sprite := (load(all[key]) as PackedScene).instantiate() as Sprite2D
				var drawn := _frame(sprite).get_used_rect()
				sprite.free()
				var art := (drawn.size.y if parts[1].begins_with("h") else drawn.size.x) / 2
				var wanted := parts[1].substr(1).to_int()
				if absi(art - wanted) > SIZE_TOLERANCE:
					problems.append("%s: %s art px, its table says %s" % [key, art, parts[1]])
				checked += 1
	assert_int(checked).is_greater(0)
	assert_array(Array(problems)).is_empty()

## World px of the sprite's opaque pixels in frame 0 of band 0, as a set.
func _opaque(sprite: Sprite2D) -> Dictionary:
	var frame := _frame(sprite)
	var left := sprite.position + sprite.offset
	var found := {}
	for y: int in frame.get_height():
		for x: int in frame.get_width():
			if frame.get_pixel(x, y).a > 0.5:
				var column := frame.get_width() - 1 - x if sprite.flip_h else x
				found[Vector2i(int(left.x) + column, int(left.y) + y)] = true
	return found

func test_every_supported_prop_touches_its_support() -> void:
	var problems := PackedStringArray()
	for pair: Array in SUPPORTED:
		var contents := (load(pair[0]) as PackedScene).instantiate()
		var hung := contents.get_node("Props/%s" % pair[1]) as Sprite2D
		var support := contents.get_node("Props/%s" % pair[2]) as Sprite2D
		var held := _opaque(support)
		var touches := false
		for at: Vector2i in _opaque(hung):
			for step: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if held.has(at + step):
					touches = true
					break
			if touches:
				break
		if not touches:
			problems.append("%s: %s does not touch %s" % [pair[0].get_file(), pair[1], pair[2]])
		contents.free()
	assert_array(Array(problems)).is_empty()
