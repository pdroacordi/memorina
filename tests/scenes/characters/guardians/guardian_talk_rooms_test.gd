class_name GuardianTalkRoomsTest extends GdUnitTestSuite

## A guardian's talk zone rides its body, so it can stand at its spawn or anywhere its leap lands (the arena inside
## `lucidity_leap_margin`): from all of those it keeps more than Ivo's body width from every door zone on its row
## (systems/dialogue, "Ivo and the Talkable"; systems/guardians, "Talks").

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
			# The mentor's lantern has its hatch in the middle of the floor; his talk is staged by the restoration scene,
			# which stands him away from it (GRD-06 follow-up in the roadmap).
			if guardian == null or guardian.stats.finale != null:
				continue
			checked += 1
			var talk := guardian.get_node(^"Talkable") as Talkable
			var arena := guardian.get_node(guardian.arena_path) as Arena
			var shape := arena.get_node(^"CollisionShape2D") as CollisionShape2D
			var size := (shape.shape as RectangleShape2D).size
			var centre := arena.position + shape.position
			var low := minf(guardian.position.x, centre.x - size.x * 0.5 + guardian.lucidity_leap_margin)
			var high := maxf(guardian.position.x, centre.x + size.x * 0.5 - guardian.lucidity_leap_margin)
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
	assert_int(checked).is_greater_equal(2)

func _contents_scenes(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_contents_scenes(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with("_contents.tscn"):
			found.append(dir.path_join(file))
	return found
