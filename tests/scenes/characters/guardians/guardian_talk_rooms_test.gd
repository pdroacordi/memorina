class_name GuardianTalkRoomsTest extends GdUnitTestSuite

## A guardian's talk zone rides its body, so it can stand at its spawn or anywhere its leap lands (the arena inside
## `lucidity_leap_margin`): from all of those it keeps more than Ivo's body width from every door zone on its row
## (systems/dialogue, "Ivo and the Talkable"; systems/guardians, "Talks"). The mentor talks only at his spawn.

const ROOMS_DIR := "res://scenes/world/rooms"
const GUARDIANS_DIR := "res://scenes/characters/guardians/"
## Px: Ivo's body (capsule radius 11) is 22 px wide.
const BODY_WIDTH := 22.0


func test_no_guardian_talk_can_stand_within_a_body_of_a_door() -> void:
	var checked := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		if not FileAccess.get_file_as_string(path).contains(GUARDIANS_DIR):
			continue
		var contents := auto_free((load(path) as PackedScene).instantiate()) as Node2D
		var room_path := path.trim_suffix("_contents.tscn") + ".room"
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(room_path), RoomLegend.load_default(), room_path).map
		for child: Node in contents.get_children():
			var guardian := child as Guardian
			if guardian == null:
				continue
			checked += 1
			var talk := guardian.get_node(^"Talkable") as Talkable
			var arena := guardian.get_node(guardian.arena_path) as Arena
			var shape := arena.get_node(^"CollisionShape2D") as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			var centre := arena.position + shape.position
			var low := minf(guardian.position.x, centre.x - size.x * 0.5 + guardian.lucidity_leap_margin)
			var high := maxf(guardian.position.x, centre.x + size.x * 0.5 - guardian.lucidity_leap_margin)
			# The mentor talks only once restored, and his restoration scene stands him on a mark at his spawn.
			if guardian.stats.finale != null:
				assert_bool(_has_mark_at(contents, guardian.position)).override_failure_message(
						"%s: no cutscene mark at %s's spawn" % [path.get_file(), guardian.name]).is_true()
				low = guardian.position.x
				high = guardian.position.x
			# The widest the zone can sweep, from its westmost to its eastmost stand.
			var zone := Vector2(low - talk.reach_west, high + talk.reach_east)
			var row := floori((guardian.position.y - 1.0) / RoomMap.CELL_PX)
			for placed: Dictionary in map.entities:
				var cell := placed.cell as Vector2i
				if placed.symbol != "E" or cell.y != row:
					continue
				var door_left := float(cell.x * RoomMap.CELL_PX)
				var gap := maxf(door_left - zone.y, zone.x - (door_left + RoomMap.CELL_PX))
				assert_float(gap).override_failure_message("%s: %s's talk sweeps %s, door at %s" % [
						path.get_file(), guardian.name, zone, cell]).is_greater(BODY_WIDTH)
	assert_int(checked).is_greater_equal(5)

## No leap lands a guardian's body on or past a FightWall on its floor row (STORY-38: the lantern's wall at col 35 stands
## east of the trimmed arena's landings).
func test_no_leap_lands_on_a_fight_wall() -> void:
	var walls := 0
	for path: String in _contents_scenes(ROOMS_DIR):
		if not FileAccess.get_file_as_string(path).contains(GUARDIANS_DIR):
			continue
		var contents := auto_free((load(path) as PackedScene).instantiate()) as Node2D
		var room_path := path.trim_suffix("_contents.tscn") + ".room"
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(room_path), RoomLegend.load_default(), room_path).map
		for child: Node in contents.get_children():
			var guardian := child as Guardian
			if guardian == null:
				continue
			var arena := guardian.get_node(guardian.arena_path) as Arena
			var shape := arena.get_node(^"CollisionShape2D") as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			var centre := arena.position + shape.position
			var half := (guardian.get_node(^"CollisionShape2D") as CollisionShape2D).shape.get_rect().size.x * 0.5
			var low := centre.x - size.x * 0.5 + guardian.lucidity_leap_margin - half
			var high := centre.x + size.x * 0.5 - guardian.lucidity_leap_margin + half
			var row := floori((guardian.position.y - 1.0) / RoomMap.CELL_PX)
			for placed: Dictionary in map.entities:
				var cell := placed.cell as Vector2i
				if placed.symbol != "I" or cell.y != row:
					continue
				walls += 1
				var across := int((placed.params as Dictionary).get("across", 1))
				var wall_left := float(cell.x * RoomMap.CELL_PX)
				var wall_right := wall_left + across * RoomMap.CELL_PX
				assert_bool(high <= wall_left or low >= wall_right).override_failure_message(
						"%s: %s lands over x %.0f..%.0f, wall at %s" % [path.get_file(), guardian.name, low, high, cell]
						).is_true()
	assert_int(walls).is_greater_equal(1)

func _has_mark_at(contents: Node, point: Vector2) -> bool:
	for node: Node in contents.find_children("*", "Marker2D", true, false):
		if node is CutsceneMark and (node as CutsceneMark).position.is_equal_approx(point):
			return true
	return false

func _contents_scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found
