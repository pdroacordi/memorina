class_name RoomReachTest extends GdUnitTestSuite

## Audits the whole world once: every error finding must be in the allowlist, with a reason, and no entry may be stale.
## Warnings never fail (architecture/room-reachability-audit). Boards: res://tools/maps/reach_boards.tscn.

var _loaded: ReachWorldLoader.Loaded
var _report: ReachReport
var _allowlist: ReachAllowlist

func before() -> void:
	var started := Time.get_ticks_msec()
	_loaded = ReachWorldLoader.load_world()
	_report = ReachAudit.run(_loaded.grid, ReachFixture.ivo())
	_allowlist = ReachAllowlist.load_default()
	print("room_reach_test: world loaded and audited in %d ms, %d surfaces, %d findings" % [Time.get_ticks_msec() - started, _report.surfaces.size(), _report.findings.size()])

func test_the_world_loads_without_problems() -> void:
	assert_array(Array(_loaded.problems)).is_empty()
	assert_int(_loaded.grid.room_count()).is_greater(0)

func test_the_start_stands_on_a_surface() -> void:
	assert_bool(ReachFixture.ivo().is_standing(_loaded.grid.start)).is_true()
	assert_int(_report.surfaces.size()).is_greater(0)

func test_every_error_is_allowed() -> void:
	var unexpected: Array[String] = []
	for finding: ReachFinding in _report.errors():
		if not _allowlist.allows(finding):
			unexpected.append(str(finding))
	assert_array(unexpected) \
		.override_failure_message("Reachability errors not in %s (boards: res://tools/maps/reach_boards.tscn):\n%s" % [ReachAllowlist.DEFAULT_PATH, "\n".join(unexpected)]) \
		.is_empty()

func test_every_allowlist_entry_has_a_reason() -> void:
	var bare: Array[String] = []
	for entry: ReachAllowlistEntry in _allowlist.entries:
		if entry.reason.strip_edges().is_empty():
			bare.append("%s %s,%s" % [entry.room, entry.cell.x, entry.cell.y])
	assert_array(bare).is_empty()

func test_no_allowlist_entry_is_stale() -> void:
	var stale: Array[String] = []
	for entry: ReachAllowlistEntry in _allowlist.entries:
		if not _report.errors().any(func(finding: ReachFinding) -> bool: return entry.matches(finding)):
			stale.append("%s %s %s,%s" % [ReachFinding.Kind.keys()[entry.kind], entry.room, entry.cell.x, entry.cell.y])
	assert_array(stale).override_failure_message("Allowlist entries that match no error any more: remove them\n%s" % "\n".join(stale)).is_empty()

func test_every_mover_current_and_stair_answers_its_reach_method() -> void:
	var missing: Array[String] = []
	for entry: RoomLegendEntry in RoomLegend.load_default().entries:
		if entry.reach_role in [RoomLegendEntry.ReachRole.MOVER, RoomLegendEntry.ReachRole.CURRENT]:
			var node := entry.scene.instantiate()
			if not node.has_method(&"reach_cells"):
				missing.append(entry.symbol)
			if entry.reach_role == RoomLegendEntry.ReachRole.CURRENT and not node.has_method(&"reach_exit_cells"):
				missing.append(entry.symbol)
			node.free()
		if entry.reach_role == RoomLegendEntry.ReachRole.STAIR:
			var stair := entry.scene.instantiate()
			if not stair.has_method(&"reach_ends"):
				missing.append(entry.symbol)
			stair.free()
	assert_array(missing).is_empty()
