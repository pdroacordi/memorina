extends Node

## Writes each room's reachability board, `<room>.txt` and `<room>.png`, into `--out <dir>` (default
## user://reach_boards); a scene because entity scenes need the autoloads (architecture/room-reachability-audit).
## Run: "<godot>" --headless --path . res://tools/maps/reach_boards.tscn -- --out <dir>

const DEFAULT_OUT := "user://reach_boards"
## Image px per cell.
const PX := 8
## Which mark wins on a cell two findings share, first wins.
const MARK_ORDER := ["x", "|", "?", "!", "&", "*", "+", ":"]
const MARK_COLOURS := {
	"x": Color(1.0, 0.0, 0.0),
	"|": Color(0.0, 0.9, 0.9),
	"?": Color(1.0, 1.0, 1.0),
	"!": Color(0.9, 0.15, 0.15),
	"&": Color(0.85, 0.2, 0.75),
	"*": Color(1.0, 0.55, 0.1),
	"+": Color(0.95, 0.85, 0.2),
	":": Color(0.55, 0.45, 0.95),
}
const AIR := Color(0.1, 0.1, 0.12)
const SOLID := Color(0.45, 0.42, 0.38)
const ONE_WAY := Color(0.75, 0.65, 0.45)
const SONG_FLOOR := Color(0.6, 0.85, 1.0)
const HAZARD := Color(0.12, 0.2, 0.55)
const CLIMB := Color(0.3, 0.55, 0.25)
const CURRENT := Color(0.3, 0.3, 0.45)

func _ready() -> void:
	var out := ProjectSettings.globalize_path(_out_dir())
	DirAccess.make_dir_recursive_absolute(out)
	var started := Time.get_ticks_msec()
	var loaded := ReachWorldLoader.load_world()
	for problem: String in loaded.problems:
		push_error(problem)
	var report := ReachAudit.run(loaded.grid, ReachWorldLoader.ivo_lattice())
	var marks: Dictionary[Vector2i, String] = {}
	var by_room: Dictionary[StringName, Array] = {}
	for finding: ReachFinding in report.findings:
		if not by_room.has(finding.room):
			by_room[finding.room] = []
		by_room[finding.room].append(finding)
		var mark: String = ReachFinding.MARKS[finding.kind]
		for cell: Vector2i in finding.cells:
			if not marks.has(cell) or MARK_ORDER.find(mark) < MARK_ORDER.find(marks[cell]):
				marks[cell] = mark
	for i: int in loaded.grid.room_count():
		var id := loaded.grid.room_id(i)
		var findings: Array = by_room.get(id, [])
		_write_text(out.path_join("%s.txt" % id), loaded.maps[id], loaded.grid.room_rect(i), findings, marks)
		_write_image(out.path_join("%s.png" % id), loaded.grid, loaded.grid.room_rect(i), marks)
	var summary := _summary(report, by_room, Time.get_ticks_msec() - started)
	var file := FileAccess.open(out.path_join("summary.txt"), FileAccess.WRITE)
	file.store_string(summary)
	file.close()
	print(summary)
	print("Boards written to %s" % out)
	get_tree().quit()

func _out_dir() -> String:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	return args[at + 1] if at >= 0 and at + 1 < args.size() else DEFAULT_OUT

func _write_text(path: String, map: RoomMap, rect: Rect2i, findings: Array, marks: Dictionary[Vector2i, String]) -> void:
	var lines := PackedStringArray(["; %s: ! unreachable, * leads nowhere, + redundant route, : dead-end pocket, & no way back, ? unpaired door, | open edge; x outside a room (feet in the sky band, listed below)" % path.get_file().get_basename()])
	for finding: ReachFinding in findings:
		lines.append("; %s at %d,%d (%s, %d cells)" % [finding.kind_name(), finding.local.x, finding.local.y, "error" if finding.error else "warning", finding.cells.size()])
	for y: int in map.size.y:
		var row := map.rows[y]
		for x: int in map.size.x:
			var mark: String = marks.get(rect.position + Vector2i(x, y), "")
			if not mark.is_empty():
				row[x] = mark
		lines.append(row)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()

func _write_image(path: String, grid: ReachGrid, rect: Rect2i, marks: Dictionary[Vector2i, String]) -> void:
	var image := Image.create_empty(rect.size.x * PX, rect.size.y * PX, false, Image.FORMAT_RGBA8)
	for y: int in rect.size.y:
		for x: int in rect.size.x:
			var cell := rect.position + Vector2i(x, y)
			var area := Rect2i(x * PX, y * PX, PX, PX)
			image.fill_rect(area, _colour(grid.flags(cell)))
			if marks.has(cell):
				image.fill_rect(area.grow(-1), MARK_COLOURS[marks[cell]])
	image.save_png(path)

func _colour(flags: int) -> Color:
	if flags & ReachGrid.SOLID != 0:
		return SOLID
	if flags & ReachGrid.ONE_WAY != 0:
		return ONE_WAY
	if flags & ReachGrid.HAZARD != 0:
		return HAZARD
	if flags & ReachGrid.SONG_FLOOR != 0:
		return SONG_FLOOR
	if flags & ReachGrid.CLIMB != 0:
		return CLIMB
	if flags & ReachGrid.CURRENT != 0:
		return CURRENT
	return AIR

func _summary(report: ReachReport, by_room: Dictionary[StringName, Array], elapsed: int) -> String:
	var lines := PackedStringArray(["Reachability audit: %d surfaces, %d findings, %d ms" % [report.surfaces.size(), report.findings.size(), elapsed]])
	for kind: int in ReachFinding.Kind.size():
		for error: bool in [true, false]:
			var total := report.count(kind, error)
			if total > 0:
				lines.append("  %s %s: %d" % [ReachFinding.Kind.keys()[kind], "error" if error else "warning", total])
	var rooms := PackedStringArray()
	for room: StringName in by_room:
		if by_room[room].any(func(finding: ReachFinding) -> bool: return finding.error):
			rooms.append(String(room))
	rooms.sort()
	lines.append("Rooms with errors (%d): %s" % [rooms.size(), ", ".join(rooms)])
	return "\n".join(lines) + "\n"
