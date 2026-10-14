class_name RoomKitTest extends GdUnitTestSuite

## Runs the kit check on the whole world: every KIT_TRAP must be in the allowlist with its kit and a reason, and no
## entry may be stale (systems/rooms, "Kit check"). Boards: res://tools/maps/reach_boards.tscn (kits/<kit>/).

var _loaded: ReachWorldLoader.Loaded
var _grid: ReachGrid
var _kits: ReachKits
var _reports: Array[ReachReport] = []
var _allowlist: ReachAllowlist

func before() -> void:
	var started := Time.get_ticks_msec()
	_loaded = ReachWorldLoader.load_world()
	_grid = _loaded.grid
	_kits = ReachKits.load_default()
	_reports = ReachKitCheck.run(_grid, ReachFixture.ivo(), _kits)
	_allowlist = ReachAllowlist.load_default()
	print("room_kit_test: world loaded and %d kits checked in %d ms" % [_kits.kits.size(), Time.get_ticks_msec() - started])

func _report(id: StringName) -> ReachReport:
	for report: ReachReport in _reports:
		if report.kit == id:
			return report
	return null

func _findings() -> Array[ReachFinding]:
	var found: Array[ReachFinding] = []
	for report: ReachReport in _reports:
		found.append_array(report.findings)
	return found

func test_every_kit_trap_is_allowed() -> void:
	var unexpected: Array[String] = []
	for report: ReachReport in _reports:
		for pocket: ReachReport.Pocket in report.pockets:
			if not _allowlist.allows(pocket.finding):
				unexpected.append("%s; rooms %s%s; ways in:\n    %s" % [pocket.finding, ", ".join(PackedStringArray(pocket.rooms)), "; holds a bench" if pocket.bench else "", "\n    ".join(pocket.entrances)])
	assert_array(unexpected) \
		.override_failure_message("Kit traps not in %s (boards: res://tools/maps/reach_boards.tscn, kits/<kit>/):\n%s" % [ReachAllowlist.DEFAULT_PATH, "\n".join(unexpected)]) \
		.is_empty()

func test_no_kit_trap_entry_is_stale() -> void:
	var stale: Array[String] = []
	for entry: ReachAllowlistEntry in _allowlist.entries:
		if entry.kind == ReachFinding.Kind.KIT_TRAP and not _findings().any(func(finding: ReachFinding) -> bool: return entry.matches(finding)):
			stale.append("KIT_TRAP for kit %s %s %s,%s" % [entry.kit, entry.room, entry.cell.x, entry.cell.y])
	assert_array(stale).override_failure_message("Kit trap entries that match no trap any more: remove them\n%s" % "\n".join(stale)).is_empty()

func test_only_kit_traps_name_a_kit() -> void:
	var wrong: Array[String] = []
	for entry: ReachAllowlistEntry in _allowlist.entries:
		if (entry.kind == ReachFinding.Kind.KIT_TRAP) == entry.kit.is_empty() or (not entry.kit.is_empty() and _report(entry.kit) == null):
			wrong.append("%s %s %s,%s kit '%s'" % [ReachFinding.Kind.keys()[entry.kind], entry.room, entry.cell.x, entry.cell.y, entry.kit])
	assert_array(wrong).is_empty()

func test_the_start_stands_on_a_surface_for_every_kit() -> void:
	for report: ReachReport in _reports:
		assert_int(Array(report.reach).count(1)).override_failure_message("kit %s reaches nothing" % report.kit).is_greater(0)

## Abilities, songs and opened gates only add ways, so a kit reaches every room an earlier kit it grew from reaches.
func test_a_kit_reaches_every_room_its_earlier_kits_reach() -> void:
	var lost: Array[String] = []
	for i: int in _kits.kits.size():
		for j: int in _kits.kits.size():
			var earlier := _kits.kits[j]
			var later := _kits.kits[i]
			if i == j or not earlier.milestones.all(func(held: ReachMilestone) -> bool: return later.has(held)):
				continue
			for room: StringName in _reports[j].rooms:
				if not room in _reports[i].rooms:
					lost.append("%s reaches %s, %s does not" % [earlier.id, room, later.id])
	assert_array(lost).is_empty()

## The fences open with the Memorina (design 04 section 2): the base kit stays on the opening road.
func test_the_base_kit_stays_behind_the_fences() -> void:
	var rooms := _report(&"base").rooms
	assert_bool(rooms.has(&"lighthouse_interior")).is_true()
	assert_bool(rooms.has(&"woods_edge")).is_false()
	assert_bool(rooms.has(&"lake_waterfall_path")).is_false()
	assert_bool(_report(&"memorina").rooms.has(&"woods_edge")).is_true()
	assert_bool(_report(&"memorina").rooms.has(&"lake_waterfall_path")).is_true()

## The orchard arena's bramble barrier opens with wall climb, so the woods kit never drops into the chimney.
func test_the_chimney_waits_for_wall_climb() -> void:
	assert_bool(_report(&"woods").rooms.has(&"orchard_arena")).is_true()
	assert_bool(_report(&"woods").rooms.has(&"orchard_cliff_chimney")).is_false()

## bugs/the-woods-deep-pit-shaft-traps-a-kit-without-the-double-jump: the root wall before woods_deep's hole opens with
## Enraizar, so Redoma alone never drops into the root caves (user, 2026-10-14: "Root wall that opens with Enraizar").
func test_the_root_wall_keeps_redoma_out_of_the_root_caves() -> void:
	assert_bool(_report(&"lake").rooms.has(&"woods_root_caves")).is_false()
	assert_bool(_report(&"woods").rooms.has(&"woods_root_caves")).is_true()

## bugs/a-redoma-first-player-is-trapped-in-the-summer-caldera: the lake kit gets into the Caldera and back out on its
## own, not through caldera_arena's guardian (not built, GRD-04).
func test_the_lake_kit_gets_out_of_the_caldera() -> void:
	var lake := _report(&"lake")
	assert_bool(lake.rooms.has(&"caldera_open_crater")).is_true()
	assert_bool(lake.exits.any(func(room: StringName) -> bool: return String(room).begins_with("caldera_"))).is_false()
	for pocket: ReachReport.Pocket in lake.pockets:
		for room: StringName in pocket.rooms:
			assert_bool(String(room).begins_with("caldera_")).override_failure_message("lake kit trapped in %s" % room).is_false()

## bugs/the-kit-check-counts-a-guardian-arena-as-an-exit-before-the-guardian-exists: only the arena of a guardian the
## world places is a way out.
func test_every_exit_is_a_placed_guardians_arena() -> void:
	var placed := _grid.guardians.values()
	assert_array(placed).contains_exactly_in_any_order([&"bloom_hollow", &"lake_frost_arena"])
	for report: ReachReport in _reports:
		for room: StringName in report.exits:
			assert_bool(room in placed).override_failure_message("kit %s exits through %s" % [report.kit, room]).is_true()

## Every reward slot stands on a surface some kit reaches: a promised reward the journey can never get to is a map bug
## (architecture/reward-slots-reserve-their-place-in-the-room-text).
func test_every_reward_slot_is_reached_by_some_kit() -> void:
	var unreached: Array[String] = []
	var slots := 0
	for i: int in _grid.room_count():
		var map: RoomMap = _loaded.maps[_grid.room_id(i)]
		for placed: Dictionary in map.entities:
			if placed.symbol != "$":
				continue
			slots += 1
			var world: Vector2i = _grid.room_rect(i).position - map.origin + placed.cell
			var by := _reports.filter(func(report: ReachReport) -> bool: return _reaches(report, world))
			if by.is_empty():
				unreached.append("%s %s (%s)" % [_grid.room_id(i), placed.cell - map.origin, placed.params.get("slot_id", "?")])
	assert_int(slots).is_greater(0)
	assert_array(unreached).override_failure_message("Reward slots no kit reaches:\n%s" % "\n".join(unreached)).is_empty()

# Whether `report`'s kit reaches the surface an anchor at `cell` stands on: the nearest within ReachAudit.ANCHOR_DROP
# rows below, as the audit marks anchors.
func _reaches(report: ReachReport, cell: Vector2i) -> bool:
	var feet: Dictionary[Vector2i, int] = {}
	for i: int in report.surfaces.size():
		for at: Vector2i in report.surfaces[i].cells:
			feet[at] = i
	for dy: int in ReachAudit.ANCHOR_DROP + 1:
		var i: int = feet.get(cell + Vector2i(0, dy), -1)
		if i >= 0:
			return report.reach[i] == 1
	return false
