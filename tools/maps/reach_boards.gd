extends Node

## Writes each room's reachability board, `<room>.txt` and `<room>.png`, into `--out <dir>` (default
## user://reach_boards), the kit check's boards into `kits/<kit>/`, and a summary of both; a scene because entity scenes
## need the autoloads (architecture/room-reachability-audit).
## Run: "<godot>" --headless --path . res://tools/maps/reach_boards.tscn -- --out <dir>

const DEFAULT_OUT := "user://reach_boards"
## Image px per cell.
const PX := 8
## Which mark wins on a cell two findings share, first wins.
const MARK_ORDER := ["x", "|", "?", "!", "&", "*", "+", ":", ">"]
const MARK_COLOURS := {
	">": Color(1.0, 0.25, 0.5),
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
	var lattice := ReachWorldLoader.ivo_lattice()
	var report := ReachAudit.run(loaded.grid, lattice)
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
	summary += _kit_boards(out, loaded, lattice)
	var file := FileAccess.open(out.path_join("summary.txt"), FileAccess.WRITE)
	file.store_string(summary)
	file.close()
	print(summary)
	print("Boards written to %s" % out)
	get_tree().quit()

# Runs the kit check (TECH-08), writes `kits/<kit>/<room>.txt|png` for each room a kit trap touches, and returns the
# summary's per-kit lines.
func _kit_boards(out: String, loaded: ReachWorldLoader.Loaded, lattice: ReachLattice) -> String:
	var started := Time.get_ticks_msec()
	var kits := ReachKits.load_default()
	var reports := ReachKitCheck.run(loaded.grid, lattice, kits)
	var lines := PackedStringArray(["Kit check: %d kits, %d ms" % [kits.kits.size(), Time.get_ticks_msec() - started]])
	for i: int in kits.kits.size():
		var kit := kits.kits[i]
		var report := reports[i]
		var rooms := report.rooms
		var parent := _parent(kit, kits)
		var added := PackedStringArray()
		var lost := PackedStringArray()
		if parent != null:
			var before := reports[kits.kits.find(parent)].rooms
			for room: StringName in rooms:
				if not room in before:
					added.append(String(room))
			for room: StringName in before:
				if not room in rooms:
					lost.append(String(room))
		var milestones := PackedStringArray()
		for milestone: ReachMilestone in kit.milestones:
			milestones.append(String(milestone.id))
		lines.append("  %s [%s]: %d rooms, %d kit traps; exits %s" % [kit.id, ", ".join(milestones), rooms.size(), report.pockets.size(), ", ".join(PackedStringArray(report.exits)) if not report.exits.is_empty() else "none"])
		if parent != null:
			lines.append("    new over %s: %s" % [parent.id, ", ".join(added) if not added.is_empty() else "none"])
			if not lost.is_empty():
				lines.append("    reached by %s but not by this kit: %s" % [parent.id, ", ".join(lost)])
		var marks: Dictionary[Vector2i, String] = {}
		var by_room: Dictionary[StringName, Array] = {}
		for pocket: ReachReport.Pocket in report.pockets:
			lines.append("    %s, %d cells%s; rooms %s" % [pocket.finding, pocket.finding.cells.size(), ", holds a bench" if pocket.bench else "", ", ".join(PackedStringArray(pocket.rooms))])
			for way: String in pocket.entrances:
				lines.append("      in: %s" % way)
			for cell: Vector2i in pocket.finding.cells:
				marks[cell] = ReachFinding.MARKS[ReachFinding.Kind.KIT_TRAP]
			for room: StringName in pocket.rooms:
				if not by_room.has(room):
					by_room[room] = []
				by_room[room].append(pocket.finding)
		if by_room.is_empty():
			continue
		var dir := out.path_join("kits").path_join(kit.id)
		DirAccess.make_dir_recursive_absolute(dir)
		var view := loaded.grid.for_kit(kit)
		for j: int in loaded.grid.room_count():
			var id := loaded.grid.room_id(j)
			if by_room.has(id):
				_write_text(dir.path_join("%s.txt" % id), loaded.maps[id], loaded.grid.room_rect(j), by_room[id], marks)
				_write_image(dir.path_join("%s.png" % id), view, loaded.grid.room_rect(j), marks)
	return "\n".join(lines) + "\n"

# The listed kit with the most milestones that holds only milestones `kit` holds.
func _parent(kit: ReachKit, kits: ReachKits) -> ReachKit:
	var best: ReachKit = null
	for other: ReachKit in kits.kits:
		if other == kit or other.milestones.size() >= kit.milestones.size():
			continue
		if other.milestones.all(func(held: ReachMilestone) -> bool: return kit.has(held)):
			if best == null or other.milestones.size() > best.milestones.size():
				best = other
	return best

func _out_dir() -> String:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--out")
	return args[at + 1] if at >= 0 and at + 1 < args.size() else DEFAULT_OUT

func _write_text(path: String, map: RoomMap, rect: Rect2i, findings: Array, marks: Dictionary[Vector2i, String]) -> void:
	var lines := PackedStringArray(["; %s: ! unreachable, * leads nowhere, + redundant route, : dead-end pocket, & no way back, ? unpaired door, | open edge, > kit trap (kits/<kit>/ only); x outside a room (feet in the sky band, listed below)" % path.get_file().get_basename()])
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
