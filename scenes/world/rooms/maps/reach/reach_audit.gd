class_name ReachAudit extends RefCounted

## Flags the platforms Ivo cannot reach and the places that lead nowhere, over a graph of surfaces joined by
## ReachLattice landings and doors (architecture/room-reachability-audit).

const TIERS: Array[ReachLattice.Tier] = [ReachLattice.Tier.BASE, ReachLattice.Tier.DOUBLE_JUMP, ReachLattice.Tier.WALL_CLIMB]
## Rows under an anchor's cell searched for the surface it stands on.
const ANCHOR_DROP := 3

enum _Node { SURFACE, TRANSIT, GRIP }

var _grid: ReachGrid
var _lattice: ReachLattice
var _report := ReachReport.new()
# Graph nodes: every surface first (ordered as the report's), then roots, currents and wall slides as they are met.
var _kinds := PackedByteArray()
var _cells: Array[Array] = []
var _node_of: Dictionary[Vector2i, int] = {}
# Per tier, per node: the set of nodes one jump or fall lands on.
var _edges: Array[Array] = []
var _start := -1
var _anchors := PackedInt32Array()

static func run(grid: ReachGrid, lattice: ReachLattice) -> ReachReport:
	return ReachAudit.new(grid, lattice)._run()

func _init(grid: ReachGrid, lattice: ReachLattice) -> void:
	_grid = grid
	_lattice = lattice

func _run() -> ReachReport:
	_lattice.bake(_grid)
	_find_surfaces()
	_classify()
	_start = _surface_under(_grid.start)
	if _start < 0:
		push_error("the start %s stands on no surface" % _grid.start)
		return _report
	_mark_anchors()
	_connect()
	var forward: Array[Array] = []
	var backward: Array[Array] = []
	var reach: Array[PackedByteArray] = []
	var back: Array[PackedByteArray] = []
	for tier: int in TIERS.size():
		forward.append(_adjacency(tier, false))
		backward.append(_adjacency(tier, true))
		reach.append(_walk(forward[tier], PackedByteArray()))
		back.append(_walk(backward[tier], PackedByteArray()))
		_report.reached.append(reach[tier].slice(0, _report.surfaces.size()))
	_flag_unreached(reach)
	_flag_no_way_back(reach, back)
	_flag_useless(forward, backward, reach, back)
	return _report

func _find_surfaces() -> void:
	var rows: Array[Array] = []
	var claimed: Dictionary[Vector2i, bool] = {}
	for i: int in _grid.room_count():
		var rect := _grid.room_rect(i)
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var cell := Vector2i(x, y)
				if claimed.has(cell) or not _lattice.is_standing(cell):
					continue
				# A run in water stands apart: it needs Redoma, so it is a song's surface.
				var wet := _lattice.is_wet(cell)
				while _lattice.is_standing(cell + Vector2i.LEFT) and _lattice.is_wet(cell + Vector2i.LEFT) == wet:
					cell += Vector2i.LEFT
				var run: Array[Vector2i] = []
				while _lattice.is_standing(cell) and _lattice.is_wet(cell) == wet:
					claimed[cell] = true
					run.append(cell)
					cell += Vector2i.RIGHT
				rows.append(run)
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y or (a[0].y == b[0].y and a[0].x < b[0].x))
	for run: Array in rows:
		var surface := ReachReport.Surface.new()
		surface.cells.assign(run)
		surface.room = _grid.room_id(_grid.room_at(run[0]))
		_report.surfaces.append(surface)
		_add_node(_Node.SURFACE, surface.cells)

func _classify() -> void:
	var islands := _islands()
	for surface: ReachReport.Surface in _report.surfaces:
		var ground := false
		var platform := false
		if _lattice.is_wet(surface.cells[0]):
			surface.support = ReachReport.Support.SONG
			continue
		for feet: Vector2i in surface.cells:
			for i: int in _lattice.body.x:
				var under := feet + Vector2i(i, 1)
				var flags := _grid.flags(under)
				if flags & ReachGrid.ROOF != 0 or (flags & ReachGrid.SOLID != 0 and not islands.has(under)):
					ground = true
				elif flags & (ReachGrid.SOLID | ReachGrid.ONE_WAY) != 0:
					platform = true
		surface.support = ReachReport.Support.GROUND if ground else ReachReport.Support.PLATFORM if platform else ReachReport.Support.SONG

# Solid cells in 4-connected groups that touch no edge of the room each cell is in.
func _islands() -> Dictionary[Vector2i, bool]:
	var islands: Dictionary[Vector2i, bool] = {}
	var seen: Dictionary[Vector2i, bool] = {}
	for i: int in _grid.room_count():
		var rect := _grid.room_rect(i)
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				var start := Vector2i(x, y)
				if seen.has(start) or _grid.flags(start) & ReachGrid.SOLID == 0:
					continue
				var group: Array[Vector2i] = [start]
				seen[start] = true
				var edge := false
				var next := 0
				while next < group.size():
					var cell := group[next]
					next += 1
					var room := _grid.room_rect(_grid.room_at(cell))
					if cell.x == room.position.x or cell.y == room.position.y or cell.x == room.end.x - 1 or cell.y == room.end.y - 1:
						edge = true
					for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
						var neighbour := cell + step
						if not seen.has(neighbour) and _grid.flags(neighbour) & ReachGrid.SOLID != 0:
							seen[neighbour] = true
							group.append(neighbour)
				if not edge:
					for cell: Vector2i in group:
						islands[cell] = true
	return islands

func _mark_anchors() -> void:
	var marked: Dictionary[int, bool] = {_start: true}
	var cells: Array[Vector2i] = _grid.anchors.duplicate()
	for door: Dictionary in _grid.doors:
		cells.append(door.cell)
	for ends: Array in _grid.stairs:
		cells.append_array(ends)
	for cell: Vector2i in cells:
		var node := _surface_under(cell)
		if node >= 0:
			marked[node] = true
	for i: int in _grid.room_count():
		var rect := _grid.room_rect(i)
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				if _grid.flags(Vector2i(x, y)) & ReachGrid.SECRET == 0:
					continue
				for dy: int in range(-1, _lattice.body.y + 1):
					for dx: int in range(-_lattice.body.x, 2):
						var node: int = _node_of.get(Vector2i(x + dx, y + dy), -1)
						if node >= 0 and _kinds[node] == _Node.SURFACE:
							marked[node] = true
	for node: int in marked:
		_report.surfaces[node].anchor = true
		_anchors.append(node)

func _surface_under(cell: Vector2i) -> int:
	for dy: int in ANCHOR_DROP + 1:
		var node: int = _node_of.get(cell + Vector2i(0, dy), -1)
		if node >= 0 and _kinds[node] == _Node.SURFACE:
			return node
	return -1

# Each door pair of one region and each stair's two ends joined both ways, then one lattice search per node the start
# reaches: an unreached node's edges change no finding.
func _connect() -> void:
	var partners: Dictionary[int, Array] = {}
	var pairs: Array[Array] = _grid.stairs.duplicate()
	var by_link: Dictionary[String, Array] = {}
	for door: Dictionary in _grid.doors:
		var key := "%s/%s" % [door.region, door.link]
		if not by_link.has(key):
			by_link[key] = []
		by_link[key].append(door)
	for key: String in by_link:
		var pair: Array = by_link[key]
		if pair.size() != 2:
			for door: Dictionary in pair:
				_add_door_finding(door)
			continue
		pairs.append([pair[0].cell, pair[1].cell])
	for pair: Array in pairs:
		var ends: Array[int] = [_surface_under(pair[0]), _surface_under(pair[1])]
		if ends.has(-1):
			continue
		for end: int in 2:
			if not partners.has(ends[end]):
				partners[ends[end]] = []
			partners[ends[end]].append(ends[1 - end])
			for tier: int in TIERS.size():
				_edges[tier][ends[end]][ends[1 - end]] = true
	var queued: Dictionary[int, bool] = {_start: true}
	var queue: Array[int] = [_start]
	var next := 0
	while next < queue.size():
		var node := queue[next]
		next += 1
		for other: int in partners.get(node, []):
			if not queued.has(other):
				queued[other] = true
				queue.append(other)
		var found := _lattice.search(_grid, _seeds(node), true, true)
		for cell: Vector2i in found:
			var target := _node_for(cell)
			if target < 0 or target == node:
				continue
			if not queued.has(target):
				queued[target] = true
				queue.append(target)
			var bits: int = found[cell]
			_edges[ReachLattice.Tier.WALL_CLIMB][node][target] = true
			if _kinds[node] == _Node.GRIP or _kinds[target] == _Node.GRIP:
				continue
			_edges[ReachLattice.Tier.DOUBLE_JUMP][node][target] = true
			if bits & ReachLattice.KEPT_AIR != 0:
				_edges[ReachLattice.Tier.BASE][node][target] = true

# Where a node's jumps and falls start: a current sets Ivo down only on its downwind edge.
func _seeds(node: int) -> Array[Vector2i]:
	var seeds: Array[Vector2i] = []
	for cell: Vector2i in _cells[node]:
		if _kinds[node] != _Node.TRANSIT or _lattice.is_climb(cell) or _lattice.is_exit(cell):
			seeds.append(cell)
	return seeds

# The node a reached cell belongs to, adding a root, current or wall slide node the first time one is met.
func _node_for(cell: Vector2i) -> int:
	if _node_of.has(cell):
		return _node_of[cell]
	var group: Array[Vector2i] = []
	if _lattice.is_transit(cell):
		group.append(cell)
		var seen: Dictionary[Vector2i, bool] = {cell: true}
		var next := 0
		while next < group.size():
			var at := group[next]
			next += 1
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbour := at + step
				if not seen.has(neighbour) and not _node_of.has(neighbour) and _lattice.is_transit(neighbour):
					seen[neighbour] = true
					group.append(neighbour)
		return _add_node(_Node.TRANSIT, group)
	if _lattice.is_grip(cell):
		var top := cell
		while _is_free_grip(top + Vector2i.UP):
			top += Vector2i.UP
		while _is_free_grip(top):
			group.append(top)
			top += Vector2i.DOWN
		return _add_node(_Node.GRIP, group)
	return -1

func _is_free_grip(cell: Vector2i) -> bool:
	return _lattice.is_grip(cell) and not _lattice.is_transit(cell) and not _node_of.has(cell)

func _add_node(kind: _Node, cells: Array[Vector2i]) -> int:
	var node := _kinds.size()
	_kinds.append(kind)
	_cells.append(cells)
	for cell: Vector2i in cells:
		_node_of[cell] = node
	while _edges.size() < TIERS.size():
		_edges.append([])
	for tier: int in TIERS.size():
		_edges[tier].append({})
	return node

func _adjacency(tier: int, reverse: bool) -> Array[PackedInt32Array]:
	var lists: Array[PackedInt32Array] = []
	lists.resize(_kinds.size())
	for node: int in _kinds.size():
		for target: int in _edges[tier][node]:
			if reverse:
				lists[target].append(node)
			else:
				lists[node].append(target)
	return lists

# Nodes reached from the start over `lists`, skipping nodes marked in `removed`.
func _walk(lists: Array[PackedInt32Array], removed: PackedByteArray) -> PackedByteArray:
	var reached := PackedByteArray()
	reached.resize(lists.size())
	reached[_start] = 1
	var queue := PackedInt32Array([_start])
	var next := 0
	while next < queue.size():
		var node := queue[next]
		next += 1
		for target: int in lists[node]:
			if reached[target] == 0 and (removed.is_empty() or removed[target] == 0):
				reached[target] = 1
				queue.append(target)
	return reached

func _flag_unreached(reach: Array[PackedByteArray]) -> void:
	var full := reach[ReachLattice.Tier.WALL_CLIMB]
	for node: int in _report.surfaces.size():
		var surface := _report.surfaces[node]
		if full[node] == 0 and surface.support != ReachReport.Support.SONG:
			_add_finding(ReachFinding.Kind.UNREACHABLE, surface.support == ReachReport.Support.PLATFORM, [node])

func _flag_no_way_back(reach: Array[PackedByteArray], back: Array[PackedByteArray]) -> void:
	for node: int in _report.surfaces.size():
		if _report.surfaces[node].support == ReachReport.Support.SONG:
			continue
		for tier: int in TIERS.size():
			if reach[tier][node] == 1 and back[tier][node] == 0:
				_add_finding(ReachFinding.Kind.NO_WAY_BACK, true, [node])
				break

# A reached surface with no anchor that dominates no anchor, in any tier, from the start or on the way back to it.
func _flag_useless(forward: Array[Array], backward: Array[Array], reach: Array[PackedByteArray], back: Array[PackedByteArray]) -> void:
	var useful := PackedByteArray()
	useful.resize(_kinds.size())
	for node: int in _anchors:
		useful[node] = 1
	for tier: int in TIERS.size():
		_mark_dominators(_dominators(forward[tier], backward[tier]), useful)
		_mark_dominators(_dominators(backward[tier], forward[tier]), useful)
	var full := reach[ReachLattice.Tier.WALL_CLIMB]
	var useless := PackedByteArray()
	useless.resize(_kinds.size())
	for node: int in _report.surfaces.size():
		if full[node] == 1 and useful[node] == 0 and _report.surfaces[node].support != ReachReport.Support.SONG:
			useless[node] = 1
	var candidates: Array[int] = []
	var grouped := PackedByteArray()
	grouped.resize(_kinds.size())
	var wall := ReachLattice.Tier.WALL_CLIMB
	for node: int in _report.surfaces.size():
		if useless[node] == 0 or grouped[node] == 1:
			continue
		var group: Array[int] = [node]
		grouped[node] = 1
		var next := 0
		while next < group.size():
			var at := group[next]
			next += 1
			for lists: Array in [forward[wall], backward[wall]]:
				for target: int in lists[at]:
					if useless[target] == 1 and grouped[target] == 0:
						grouped[target] = 1
						group.append(target)
		group.sort()
		# Ground in the group is the pocket; every platform, in a pocket or not, is judged on its own.
		var ground: Array[int] = []
		for member: int in group:
			if _report.surfaces[member].support == ReachReport.Support.GROUND:
				ground.append(member)
			else:
				candidates.append(member)
		if not ground.is_empty():
			_add_finding(ReachFinding.Kind.DEAD_END_POCKET, false, ground)
	candidates.sort()
	var removed := PackedByteArray()
	removed.resize(_kinds.size())
	for node: int in candidates:
		removed[node] = 1
		if _cuts(forward, backward, reach, back, removed):
			removed[node] = 0
			_add_finding(ReachFinding.Kind.REDUNDANT_ROUTE, false, [node])
		else:
			_add_finding(ReachFinding.Kind.LEADS_NOWHERE, true, [node])

# Immediate dominators from the start over `succ` (Cooper, Harvey and Kennedy), -1 where unreached.
func _dominators(succ: Array[PackedInt32Array], pred: Array[PackedInt32Array]) -> PackedInt32Array:
	var count := succ.size()
	var number := PackedInt32Array()
	number.resize(count)
	number.fill(-1)
	var order := PackedInt32Array()
	var visited := PackedByteArray()
	visited.resize(count)
	visited[_start] = 1
	var stack := PackedInt32Array([_start, 0])
	while not stack.is_empty():
		var top := stack.size() - 2
		var node := stack[top]
		var edge := stack[top + 1]
		if edge < succ[node].size():
			stack[top + 1] = edge + 1
			var target := succ[node][edge]
			if visited[target] == 0:
				visited[target] = 1
				stack.append_array([target, 0])
		else:
			number[node] = order.size()
			order.append(node)
			stack.resize(top)
	var idom := PackedInt32Array()
	idom.resize(count)
	idom.fill(-1)
	idom[_start] = _start
	var changed := true
	while changed:
		changed = false
		for i: int in range(order.size() - 1, -1, -1):
			var node := order[i]
			if node == _start:
				continue
			var best := -1
			for parent: int in pred[node]:
				if idom[parent] == -1:
					continue
				best = parent if best == -1 else _intersect(parent, best, idom, number)
			if best != -1 and idom[node] != best:
				idom[node] = best
				changed = true
	return idom

func _intersect(a: int, b: int, idom: PackedInt32Array, number: PackedInt32Array) -> int:
	while a != b:
		while number[a] < number[b]:
			a = idom[a]
		while number[b] < number[a]:
			b = idom[b]
	return a

# Marks every strict dominator of each anchor in `idom`.
func _mark_dominators(idom: PackedInt32Array, useful: PackedByteArray) -> void:
	var walked := PackedByteArray()
	walked.resize(idom.size())
	for anchor: int in _anchors:
		if idom[anchor] == -1:
			continue
		var node := anchor
		while node != _start and walked[node] == 0:
			walked[node] = 1
			node = idom[node]
			useful[node] = 1

# Whether removing the marked nodes leaves an anchor some tier reached, or could return from, cut off.
func _cuts(forward: Array[Array], backward: Array[Array], reach: Array[PackedByteArray], back: Array[PackedByteArray], removed: PackedByteArray) -> bool:
	for tier: int in TIERS.size():
		var ahead := _walk(forward[tier], removed)
		var behind := _walk(backward[tier], removed)
		for anchor: int in _anchors:
			if (reach[tier][anchor] == 1 and ahead[anchor] == 0) or (back[tier][anchor] == 1 and behind[anchor] == 0):
				return true
	return false

func _add_door_finding(door: Dictionary) -> void:
	var cell: Vector2i = door.cell
	var room := _grid.room_at(cell)
	_report.findings.append(ReachFinding.new(ReachFinding.Kind.UNPAIRED_DOOR, true, _grid.room_id(room), cell, cell - _grid.room_rect(room).position, [cell] as Array[Vector2i]))

func _add_finding(kind: ReachFinding.Kind, error: bool, nodes: Array[int]) -> void:
	var cells: Array[Vector2i] = []
	for node: int in nodes:
		cells.append_array(_report.surfaces[node].cells)
	var first: Vector2i = _report.surfaces[nodes[0]].cells[0]
	var room := _grid.room_at(first)
	_report.findings.append(ReachFinding.new(kind, error, _grid.room_id(room), first, first - _grid.room_rect(room).position, cells))
