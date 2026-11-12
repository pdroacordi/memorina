class_name GardenTwinTest extends GdUnitTestSuite

## garden_past is village_garden's twin (architecture/story-05-playable-flashbacks, "Twin rule"): the same ground, water
## and dressing, and a backdrop whose every layer draws the same room-relative pixel from the same room-relative camera.

const PRESENT_REGION := "res://scenes/world/rooms/home_village.tscn"
const PAST_REGION := "res://scenes/world/rooms/past.tscn"
const PRESENT_MAP := "res://scenes/world/rooms/home_village/contents/village_garden.room"
const PAST_MAP := "res://scenes/world/rooms/past/contents/garden_past.room"
## Room-relative camera centres and pixels sampled, px: the corners of the view's travel and a few odd points.
const CAMERAS: Array[Vector2] = [Vector2(320, 180), Vector2(960, 588), Vector2(640, 384), Vector2(333, -97)]
const PIXELS: Array[Vector2] = [Vector2(0, 0), Vector2(17, 767), Vector2(641, 200), Vector2(1279, -150), Vector2(905, 477)]
## World px two positions may differ by and still pick the same texel (float32 at x 1e5).
const TOLERANCE := 0.05
## The room-relative camera centre on the bank at zoom 1 (the view's bottom on the room's bottom), px.
const BANK_CAMERA := Vector2(640, 588)
## px the near layer stands under its authored pose at the bank camera (waterfall_garden_*.tres).
const NEAR_DROP := 62.0

var _present: Region
var _past: Region


func before() -> void:
	_present = (load(PRESENT_REGION) as PackedScene).instantiate() as Region
	_past = (load(PAST_REGION) as PackedScene).instantiate() as Region

func after() -> void:
	_present.free()
	_past.free()

func _room(region: Region, room_name: String) -> Room:
	return region.get_node(room_name) as Room

func _grid_and_water(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	return text.substr(text.find("
[grid]"))

func test_the_ground_and_water_are_the_same() -> void:
	assert_str(_grid_and_water(PAST_MAP)).is_equal(_grid_and_water(PRESENT_MAP))
	var legend := RoomLegend.load_default()
	for path: String in [PRESENT_MAP, PAST_MAP]:
		var result := RoomMapParser.parse(FileAccess.get_file_as_string(path), legend, path)
		assert_array(Array(result.errors)).override_failure_message("%s: %s" % [path, result.errors]).is_empty()
		assert_str(result.map.tileset).is_equal("village")

func test_the_rooms_are_the_same_size() -> void:
	var present := _room(_present, "VillageGarden")
	var past := _room(_past, "GardenPast")
	var size_of := func(room: Room) -> Vector2:
		return ((room.get_node("CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size
	assert_vector(size_of.call(past)).is_equal(size_of.call(present))
	assert_bool(past.interior).is_true()
	assert_bool(past.is_past()).is_true()
	assert_bool(present.is_past()).is_false()

func test_the_dressing_stands_in_the_same_place() -> void:
	var present := _room(_present, "VillageGarden").contents_scene.instantiate() as Node2D
	var past := _room(_past, "GardenPast").contents_scene.instantiate() as Node2D
	for group: String in ["Props", "Marks", "Falls"]:
		var placed := {}
		for child: Node in present.get_node(group).get_children():
			placed[child.name] = (child as Node2D).position
		for child: Node in past.get_node(group).get_children():
			assert_bool(placed.has(child.name)).override_failure_message("%s/%s is not in the present" % [group, child.name]).is_true()
			assert_vector((child as Node2D).position).is_equal(placed.get(child.name, Vector2.INF))
		assert_int(past.get_node(group).get_child_count()).is_equal(placed.size())
	present.free()
	past.free()

## Where a layer's texel stands relative to the pixel, for a room-relative camera and pixel, as Backdrop places it.
func _layer_pos(region: Region, room: Room, shown: BackdropSet, layer: BackdropLayer, camera: Vector2, pixel: Vector2) -> Vector2:
	var anchor := Vector2(room.position.x, region.position.y + region.horizon_y)
	var layer_anchor := BackdropMath.layer_anchor(anchor, layer.repeat_x, layer.repeats_y())
	var ref := BackdropMath.reference_centre(layer_anchor, shown.horizon_screen_y, Backdrop.HALF_VIEW)
	var at := BackdropMath.anchor_position(layer_anchor, ref, room.position + camera, layer.scroll_scale)
	return BackdropMath.pixel_centre(room.position + pixel) - at

func _shown(region: Region, room: Room) -> BackdropSet:
	var contents := room.contents_scene.instantiate() as Node2D
	var own := (contents.get_node("Backdrop") as Backdrop).backdrop_set
	contents.free()
	return Backdrop.shown_set(own, region)

func test_every_backdrop_layer_draws_the_same_room_relative_pixel() -> void:
	var present := _room(_present, "VillageGarden")
	var past := _room(_past, "GardenPast")
	var shown := _shown(_present, present)
	assert_object(_shown(_past, past)).is_same(shown)
	assert_object(_past.backdrop_set).is_same(_present.backdrop_set)
	for layer: BackdropLayer in shown.layers:
		var width := float(layer.strip_size().x)
		for camera: Vector2 in CAMERAS:
			for pixel: Vector2 in PIXELS:
				var a := _layer_pos(_present, present, shown, layer, camera, pixel)
				var b := _layer_pos(_past, past, shown, layer, camera, pixel)
				var dx := a.x - b.x
				if layer.repeat_x:
					dx = fposmod(dx + width * 0.5, width) - width * 0.5
				var message := "%s camera %s pixel %s: %s vs %s" % [layer.texture.resource_path.get_file(), camera, pixel, a, b]
				assert_float(absf(dx)).override_failure_message(message).is_less(TOLERANCE)
				assert_float(absf(a.y - b.y)).override_failure_message(message).is_less(TOLERANCE)

## The hidden swap (flashback 5): the past's grass hashes at the present garden's columns, and the colour the song brings
## wears the region's season as the past does, so neither the blades nor the grade change at the swap.
func test_the_grass_and_the_grade_are_the_same() -> void:
	var present := _room(_present, "VillageGarden")
	var past := _room(_past, "GardenPast")
	assert_float(past.position.x + _past.twin_shift.x).is_equal(present.position.x)
	assert_vector(_present.twin_shift).is_equal(Vector2.ZERO)
	assert_int(_past.season).is_equal(_present.season)
	var catalog := load("res://resources/songs/song_catalog.tres") as SongCatalog
	var contents := present.contents_scene.instantiate()
	var bloom := contents.get_node("Flashbacks/Bloom5") as MemoryBloom
	assert_that(bloom.tint).is_equal(catalog.palette_for(_present.season).tint)
	contents.free()

## The lake's waterline lies the same px over its painted top in both gardens, so the bank shows one thin earth line.
func test_the_lake_rises_the_same_over_the_bank() -> void:
	var present := _room(_present, "VillageGarden").contents_scene.instantiate() as Node2D
	var past := _room(_past, "GardenPast").contents_scene.instantiate() as Node2D
	var rise := (present.get_node("RoomMap") as RoomMapNode).lake_rise
	assert_int(rise).is_greater(0)
	assert_int((past.get_node("RoomMap") as RoomMapNode).lake_rise).is_equal(rise)
	present.free()
	past.free()

## At the bank camera every garden layer stands in its authored pose against the sky, the near layer NEAR_DROP px lower
## so only its crowns show over the bank: no layer's flat fill shows between the mesas and the bank, at zoom 1 or in
## flashback 5's widest frame (playtests/2026-11-12-story05-garden-fixes).
func test_the_garden_layers_stand_in_their_pose_at_the_bank() -> void:
	var room := _room(_present, "VillageGarden")
	var anchor := Vector2(room.position.x, _present.position.y + _present.horizon_y)
	for time: String in ["morning", "day", "afternoon", "night", "twilight"]:
		var shown := load("res://resources/world/backdrops/waterfall_garden_%s.tres" % time) as BackdropSet
		var tops := PackedFloat32Array()
		for layer: BackdropLayer in shown.layers:
			var ref := BackdropMath.reference_centre(anchor, shown.horizon_screen_y, Backdrop.HALF_VIEW)
			var at := BackdropMath.anchor_position(anchor, ref, room.position + BANK_CAMERA, layer.scroll_scale)
			tops.append(at.y - layer.horizon_row)
		var expected := [0.0, 0.0, 0.0, NEAR_DROP]
		for i: int in tops.size():
			assert_float(tops[i] - tops[0]).override_failure_message("%s layer %d: art row 0 at %.1f px from the sky's" % [time, i, tops[i] - tops[0]]).is_equal_approx(expected[i], 1.0)
