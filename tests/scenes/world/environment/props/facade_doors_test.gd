class_name FacadeDoorsTest extends GdUnitTestSuite

## A facade stands on a door, every door whose look needs one stands in a facade, and every roof cell lies on a
## facade's roof line (systems/props, Facades; systems/rooms, Doors).

const ROOMS_DIR := "res://scenes/world/rooms"
## Debug-only test beds (CLAUDE.md, Song trials): their doors test the door, not the world.
const TRIALS_PREFIX := "trials_"
## Doorways that make sense without a building around them.
const ALONE_LOOKS := ["passage", "stairwell", "hatch_up", "hatch_down"]
## Doorways that belong inside a facade outdoors: a building's door, or a breach whose hole the facade draws.
const FACADE_LOOKS := ["door", "breach"]
## Px a roof cell's top may sit off the facade's top edge above it.
const ROOF_TOLERANCE := 8


func _contents_scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found

## The Room trigger scene beside `<region>/contents/<room>_contents.tscn`.
func _is_interior(contents_path: String) -> bool:
	var region_dir := contents_path.get_base_dir().get_base_dir()
	var room_path := region_dir.path_join(contents_path.get_file().trim_suffix("_contents.tscn") + ".tscn")
	var room := (load(room_path) as PackedScene).instantiate()
	var interior: bool = room.get("interior")
	room.free()
	return interior

func _is_trial(contents_path: String) -> bool:
	return contents_path.trim_prefix(ROOMS_DIR + "/").begins_with(TRIALS_PREFIX)

# Each `E` with its feet in the contents' space (the bottom centre of its cell; a cell already counts the room's origin).
func _doors(contents: Node) -> Array[Dictionary]:
	var doors: Array[Dictionary] = []
	var map: RoomMap = contents.get_node("RoomMap").map
	for placed: Dictionary in map.entities:
		if placed.symbol == "E":
			var cell: Vector2i = placed.cell
			var feet := Vector2((cell.x + 0.5) * RoomMap.CELL_PX, (cell.y + 1) * RoomMap.CELL_PX)
			doors.append({"feet": feet, "look": (placed.params as Dictionary).get("look", "door")})
	return doors

func _facades(contents: Node) -> Array[Sprite2D]:
	var facades: Array[Sprite2D] = []
	var props := contents.get_node_or_null("Props")
	if props != null:
		for prop: Node in props.get_children():
			if prop.scene_file_path.ends_with("_facade.tscn"):
				facades.append(prop as Sprite2D)
	return facades

func _feet(facades: Array[Sprite2D]) -> Array[Vector2]:
	var feet: Array[Vector2] = []
	for facade: Sprite2D in facades:
		feet.append(facade.position)
	return feet

## The facade's top opaque pixel at contents-space `x`, or INF where it draws nothing.
func _top_at(facade: Sprite2D, image: Image, x: float) -> float:
	var left := facade.position + facade.offset
	var column := int(x - left.x)
	if column < 0 or column >= image.get_width():
		return INF
	for row: int in image.get_height():
		if image.get_pixel(column, row).a > 0.5:
			return left.y + row
	return INF

func test_every_facade_stands_on_a_door() -> void:
	var problems := PackedStringArray()
	for path: String in _contents_scenes(ROOMS_DIR):
		var contents := (load(path) as PackedScene).instantiate()
		var feet: Array[Vector2] = []
		for door: Dictionary in _doors(contents):
			feet.append(door.feet)
		for facade: Vector2 in _feet(_facades(contents)):
			if not facade in feet:
				problems.append("%s: a facade at %s has no door" % [path, facade])
		contents.free()
	assert_array(Array(problems)).is_empty()

## An outdoor door never stands alone: its building's front surrounds it, unless it is a passage, a stairwell or a hatch.
func test_every_outdoor_facade_look_stands_in_a_facade() -> void:
	var problems := PackedStringArray()
	var outdoor := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		if _is_trial(path) or _is_interior(path):
			continue
		var contents := (load(path) as PackedScene).instantiate()
		var facades := _feet(_facades(contents))
		for door: Dictionary in _doors(contents):
			outdoor += 1
			if door.look in FACADE_LOOKS and not door.feet in facades:
				problems.append("%s: the %s at %s stands in no facade" % [path, door.look, door.feet])
		contents.free()
	assert_int(outdoor).is_greater(0)
	assert_array(Array(problems)).is_empty()

## A breach's art is clear, so the hole is the facade's: in every room, interiors and trials included, a breach stands
## in a facade.
func test_every_breach_stands_in_a_facade_everywhere() -> void:
	var problems := PackedStringArray()
	var breaches := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		var contents := (load(path) as PackedScene).instantiate()
		var facades := _feet(_facades(contents))
		for door: Dictionary in _doors(contents):
			if door.look != "breach":
				continue
			breaches += 1
			if not door.feet in facades:
				problems.append("%s: the breach at %s stands in no facade" % [path, door.feet])
		contents.free()
	assert_int(breaches).is_greater(0)
	assert_array(Array(problems)).is_empty()

## Each look either stands alone or needs a facade outdoors, so a new look must say which.
func test_every_look_is_alone_or_in_a_facade() -> void:
	for look: String in Door.LOOKS:
		assert_bool((look in ALONE_LOOKS) != (look in FACADE_LOOKS)) \
			.override_failure_message("look '%s' is in neither or both of ALONE_LOOKS and FACADE_LOOKS" % look).is_true()

func test_every_door_look_is_known() -> void:
	var problems := PackedStringArray()
	for path: String in _contents_scenes(ROOMS_DIR):
		var contents := (load(path) as PackedScene).instantiate()
		for door: Dictionary in _doors(contents):
			if not Door.LOOKS.has(door.look):
				problems.append("%s: unknown door look '%s'" % [path, door.look])
		contents.free()
	assert_array(Array(problems)).is_empty()

## A roof has no art of its own: each run of roof cells lies over a facade, with both ends on its top edge (a dovecote
## may stand on the roof between them).
func test_every_roof_lies_on_a_facade_roof() -> void:
	var problems := PackedStringArray()
	var roofs := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		var contents := (load(path) as PackedScene).instantiate()
		var map: RoomMap = contents.get_node("RoomMap").map
		var facades := _facades(contents)
		var images: Array[Image] = []
		for facade: Sprite2D in facades:
			images.append(facade.texture.get_image())
		for y: int in map.size.y:
			var run: Array[Vector2i] = []
			for x: int in map.size.x + 1:
				var index := y * map.size.x + x
				if x < map.size.x and map.platform[index] == 1 and map.looks[index] == RoomMap.NO_LOOK:
					run.append(map.origin + Vector2i(x, y))
					continue
				if run.is_empty():
					continue
				roofs += run.size()
				for cell: Vector2i in run:
					if _roof_gap(facades, images, cell) < -ROOF_TOLERANCE:
						problems.append("%s: roof cell %s lies over no facade" % [path, cell])
				for end: Vector2i in [run[0], run[-1]]:
					if absf(_roof_gap(facades, images, end)) > ROOF_TOLERANCE:
						problems.append("%s: roof cell %s is off its facade's roof line" % [path, end])
				run.clear()
		contents.free()
	assert_int(roofs).is_greater(0)
	assert_array(Array(problems)).is_empty()

## Px from the cell's top up to the highest facade top above its centre: 0 on a roof line, positive under a taller part,
## -INF over no facade.
func _roof_gap(facades: Array[Sprite2D], images: Array[Image], cell: Vector2i) -> float:
	var top := float(cell.y * RoomMap.CELL_PX)
	var centre := (cell.x + 0.5) * RoomMap.CELL_PX
	var best := -INF
	for i: int in facades.size():
		var drawn := _top_at(facades[i], images[i], centre)
		if drawn != INF:
			var gap := top - drawn
			if absf(gap) < absf(best) or best == -INF:
				best = gap
	return best
