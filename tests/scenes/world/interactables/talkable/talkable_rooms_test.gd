class_name TalkableRoomsTest extends GdUnitTestSuite

## Every talk placed in a room file (legend `t`, systems/dialogue): its zone keeps more than Ivo's body width from every
## door zone on its row, and an auto talk is wide enough to start while Ivo runs through it.

const ROOMS_DIR := "res://scenes/world/rooms"
## Px: Ivo's body (capsule radius 11) is 22 px wide.
const BODY_WIDTH := 22.0
## Px: the narrowest auto zone that starts at a run (192 px/s, `auto_delay` 0.4 s) is about 72 px; 8 px of margin.
const MIN_AUTO_WIDTH := 80.0


## A door beside a talk wins: only one Up prompt shows at a time
## (bugs/the-boys-talk-prompt-shows-over-the-bell-tower-door-and-up-enters-the-tower).
func test_no_talk_stands_within_a_body_of_a_door() -> void:
	var checked := 0
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), RoomLegend.load_default(), path).map
		var doors: Array[Vector2i] = []
		var talks: Array[Dictionary] = []
		for placed: Dictionary in map.entities:
			if placed.symbol == "E":
				doors.append(placed.cell)
			elif placed.symbol == "t":
				talks.append(placed)
		for talk: Dictionary in talks:
			checked += 1
			var zone := zone_of(talk)
			for door: Vector2i in doors:
				if door.y != (talk.cell as Vector2i).y:
					continue
				var door_left := float(door.x * RoomMap.CELL_PX)
				var gap := maxf(door_left - zone.y, zone.x - (door_left + RoomMap.CELL_PX))
				assert_float(gap).override_failure_message("%s: talk at %s, door at %s" % [path.get_file(), talk.cell, door]).is_greater(BODY_WIDTH)
	assert_int(checked).is_greater(10)

## (bugs/the-daughters-song-talk-needs-ivo-inside-her-and-a-run-past-never-starts-it)
func test_every_auto_talk_is_wide_enough_to_start_at_a_run() -> void:
	var checked := 0
	for path: String in _room_files(ROOMS_DIR):
		var map := RoomMapParser.parse(FileAccess.get_file_as_string(path), RoomLegend.load_default(), path).map
		for placed: Dictionary in map.entities:
			if placed.symbol != "t" or not bool(placed.params.get("auto_start", false)):
				continue
			checked += 1
			var zone := zone_of(placed)
			assert_float(zone.y - zone.x).override_failure_message("%s: auto talk at %s" % [path.get_file(), placed.cell]).is_greater_equal(MIN_AUTO_WIDTH)
	assert_int(checked).is_greater(3)

## X range (from, to) of a placed talk's zone in room px.
static func zone_of(placed: Dictionary) -> Vector2:
	var speaker := ((placed.cell as Vector2i).x + 0.5) * RoomMap.CELL_PX + float(placed.params.get("speaker_offset", 0.0))
	return Vector2(speaker - float(placed.params.get("reach_west", Talkable.REACH)), speaker + float(placed.params.get("reach_east", Talkable.REACH)))

func _room_files(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_room_files(dir.path_join(sub)))
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "room":
			found.append(dir.path_join(file))
	return found
