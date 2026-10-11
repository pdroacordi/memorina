class_name ReachLattice extends RefCounted

## Where Ivo gets from a set of cells in one jump or fall: his real arc (JumpReach) stepped one cell sideways per
## lattice step on a ReachGrid (architecture/room-reachability-audit).

enum Tier { BASE, DOUBLE_JUMP, WALL_CLIMB }

## search() bit: reached without spending the air jump.
const KEPT_AIR := 1
## search() bit: reached at all.
const REACHED := 2
## search() bit: a wall slide, reached only with wall climb.
const GRIP := 4

## Sub-steps per cell an air jump or a fall keeps its height in: 16 px.
const QUANTA := 2
## Rows above a room's top a jump may rise through an open top.
const ABOVE := 10

const _CELL := RoomMap.CELL_PX
const _QUANTUM := _CELL / QUANTA

# Derived per feet cell (bake): footprint clear, standing, holding a root or in a current, against a wall, in water,
# standing only on a song's floor (optional: a fall may pass it), holding a root, at a current's downwind edge. A cell far
# from every room stays 0, a wall the body never passes.
const _OPEN := 1
const _STAND := 2
const _TRANSIT := 4
const _WALL := 8
const _WET := 16
const _SOFT := 32
const _CLIMB := 64
const _EXIT := 128
# Raw cell bit: inside a room.
const _IN_ROOM := 1024

enum _Profile { JUMP, FALL, AIR, TERMINAL }
const _STEPS: Array[int] = [-1, 0, 1]
# Keeps a packed anchor positive.
const _ANCHOR_BIAS := 16384

## The footprint in cells, from the capsule (MapGuide.ivo_body).
var body: Vector2i

# Px above the start per lattice step, per profile (TERMINAL has none).
var _heights: Array[PackedFloat32Array] = []
# Px fallen per lattice step at terminal velocity.
var _terminal_drop := 0.0
# Whether the body hangs far enough past an edge to count the next column as a take-off.
var _overhang := false
var _grid: ReachGrid
var _box := Rect2i()
var _cells := PackedByteArray()

func _init(reach: JumpReach, p_body: Vector2i) -> void:
	body = p_body
	# One lattice step is the time Ivo takes to run one cell.
	var step := float(_CELL) / reach.locomotion.move_speed
	_heights.resize(3)
	_heights[_Profile.JUMP] = _sample(reach.heights(reach.jump.jump_height), step)
	_heights[_Profile.FALL] = _sample(reach.heights(0.0), step)
	_heights[_Profile.AIR] = _sample(reach.heights(reach.double_jump_height), step) if reach.double_jump_height > 0.0 else PackedFloat32Array()
	_terminal_drop = reach.jump.terminal_velocity * step
	_overhang = reach.body_radius * 2.0 >= _CELL * 0.5

## The feet cells reached from `from` in one jump or fall with `tier`'s kit: landings, roots and currents entered,
## and, with wall climb, walls slid on.
func landings(grid: ReachGrid, from: Array[Vector2i], tier: Tier) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var reached := search(grid, from, tier != Tier.BASE, tier == Tier.WALL_CLIMB)
	for cell: Vector2i in reached:
		var bits: int = reached[cell]
		if tier == Tier.WALL_CLIMB or bits & GRIP == 0 or is_standing(cell) or is_transit(cell):
			found.append(cell)
	return found

## Every feet cell reached from `from` in one jump or fall, with KEPT_AIR, REACHED and GRIP bits.
func search(grid: ReachGrid, from: Array[Vector2i], double_jump: bool, wall_climb: bool) -> Dictionary[Vector2i, int]:
	bake(grid)
	var found: Dictionary[Vector2i, int] = {}
	var seen: Dictionary[int, bool] = {}
	var states := PackedInt64Array()
	var width := _box.size.x
	var height := _box.size.y
	var cells := _cells
	var watch := _TRANSIT | (_WALL if wall_climb else 0)
	var can_air := double_jump and not _heights[_Profile.AIR].is_empty()
	for cell: Vector2i in from:
		var local := cell - _box.position
		if not _has(local.x, local.y) or not _is(local.x, local.y, _OPEN):
			continue
		var anchor := (local.y + 1) * QUANTA
		var columns: Array[int] = [local.x]
		if _overhang and _is(local.x, local.y, _STAND):
			for side: int in [-1, 1]:
				if _has(local.x + side, local.y) and _is(local.x + side, local.y, _OPEN) and not _is(local.x + side, local.y, _STAND):
					columns.append(local.x + side)
		# A jump needs a floor, a hold or, with wall climb, a wall slide (Player._try_jump); from a current Ivo only falls,
		# the air jump kept.
		var grounded := _is(local.x, local.y, _STAND) or _is(local.x, local.y, _CLIMB) or (wall_climb and _is(local.x, local.y, _WALL))
		for x: int in columns:
			if grounded:
				_push(states, seen, _key(x, anchor, _Profile.JUMP, 0, 1))
			_push(states, seen, _key(x, anchor, _Profile.FALL, 0, 1))
	var next := 0
	while next < states.size():
		var key := states[next]
		next += 1
		var air := key & 1
		var k := (key >> 1) & 255
		var profile := (key >> 9) & 3
		var anchor := ((key >> 11) & 65535) - _ANCHOR_BIAS
		var x := key >> 27
		var before := _height(profile, k)
		var after := _height(profile, k + 1)
		# Feet px, down positive; a foot on a cell line stands in the row above it.
		var feet := anchor * _QUANTUM - before
		var y := ceili(feet / _CELL) - 1
		if can_air and air == 1:
			# Rounded up a quantum: the air jump keeps its start's height to within _QUANTUM px.
			_push(states, seen, _key(x, floori(feet / _QUANTUM), _Profile.AIR, 0, 0))
		var rising := after > before
		var feet_after := anchor * _QUANTUM - after
		var y1 := ceili(feet_after / _CELL) - 1
		var next_profile := profile
		var next_k := k + 1
		var next_anchor := anchor
		if profile == _Profile.TERMINAL or k + 1 >= _heights[profile].size() - 1:
			next_profile = _Profile.TERMINAL
			next_k = 0
			next_anchor = floori(feet_after / _QUANTUM)
		var bits := REACHED | (KEPT_AIR if air == 1 else 0)
		for dx: int in _STEPS:
			# Sideways first, then the rise or fall.
			var c := x + dx
			if c < 0 or c >= width:
				continue
			var r := y
			var at := cells[r * width + c]
			if at & _OPEN == 0:
				continue
			if dx != 0 and at & watch != 0:
				_reach(found, c, r, bits | (GRIP if at & _TRANSIT == 0 else 0))
			if rising or y1 < r:
				var bumped := false
				while r > y1:
					if r - 1 < 0:
						bumped = true
						break
					at = cells[(r - 1) * width + c]
					if at & _OPEN == 0:
						bumped = true
						break
					r -= 1
					if at & watch != 0:
						_reach(found, c, r, bits | (GRIP if at & _TRANSIT == 0 else 0))
				if bumped:
					_push(states, seen, _key(c, (r + 1) * QUANTA, _Profile.FALL, 0, air))
				else:
					_push(states, seen, _key(c, next_anchor, next_profile, next_k, air))
				continue
			var landed := false
			var dead := false
			while true:
				if at & _STAND != 0:
					if at & _SOFT == 0:
						landed = true
						break
					_reach(found, c, r, bits)
				if r >= y1:
					break
				if r + 1 >= height:
					dead = true
					break
				at = cells[(r + 1) * width + c]
				if at & _OPEN == 0:
					dead = true
					break
				r += 1
				if at & watch != 0:
					_reach(found, c, r, bits | (GRIP if at & _TRANSIT == 0 else 0))
			if landed:
				_reach(found, c, r, bits)
			elif not dead:
				_push(states, seen, _key(c, next_anchor, next_profile, next_k, air))
	var world: Dictionary[Vector2i, int] = {}
	for local: Vector2i in found:
		world[local + _box.position] = found[local]
	return world

## Builds the derived cells for `grid`; landings() calls it, the audit calls it before asking about cells.
func bake(grid: ReachGrid) -> void:
	if grid == _grid:
		return
	_grid = grid
	_box = grid.bounds().grow_individual(1, ABOVE + body.y, 1, 1)
	var raw := PackedInt32Array()
	raw.resize(_box.size.x * _box.size.y)
	for i: int in grid.room_count():
		var rect := grid.room_rect(i)
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				raw[_index(x - _box.position.x, y - _box.position.y)] = grid.flags(Vector2i(x, y)) | _IN_ROOM
	_cells.resize(raw.size())
	_cells.fill(0)
	for i: int in grid.room_count():
		var near := grid.room_rect(i).grow_individual(1, ABOVE + body.y - 1, 1, 0)
		for y: int in range(near.position.y, near.end.y):
			for x: int in range(near.position.x, near.end.x):
				var local := Vector2i(x, y) - _box.position
				_cells[_index(local.x, local.y)] = _derive(raw, local.x, local.y)

## Whether Ivo stands with his feet in `cell`: a clear footprint over a floor, inside a room.
func is_standing(cell: Vector2i) -> bool:
	return _at(cell) & _STAND != 0

## Whether the footprint at `cell` holds a root or is inside a current.
func is_transit(cell: Vector2i) -> bool:
	return _at(cell) & _TRANSIT != 0

## Whether the footprint at `cell` holds a root.
func is_climb(cell: Vector2i) -> bool:
	return _at(cell) & _CLIMB != 0

## Whether the footprint at `cell` is on a current's downwind edge, where it sets Ivo down.
func is_exit(cell: Vector2i) -> bool:
	return _at(cell) & _EXIT != 0

## Whether a body at `cell` slides on a wall its full height.
func is_grip(cell: Vector2i) -> bool:
	return _at(cell) & _WALL != 0

## Whether the footprint at `cell` is in water only a Redoma shell lets Ivo into.
func is_wet(cell: Vector2i) -> bool:
	return _at(cell) & _WET != 0

## Whether the footprint at `cell` is clear of ground and hazards.
func is_open(cell: Vector2i) -> bool:
	return _at(cell) & _OPEN != 0

func _derive(raw: PackedInt32Array, x: int, y: int) -> int:
	var bits := _OPEN
	for j: int in body.y:
		for i: int in body.x:
			var flags := _raw(raw, x + i, y - j)
			if flags & (ReachGrid.SOLID | ReachGrid.HAZARD) != 0:
				return 0
			if flags & ReachGrid.CLIMB != 0:
				bits |= _TRANSIT | _CLIMB
			if flags & ReachGrid.CURRENT != 0:
				bits |= _TRANSIT
			if flags & ReachGrid.CURRENT_EXIT != 0:
				bits |= _EXIT
			if flags & ReachGrid.WATER != 0:
				bits |= _WET
	if _raw(raw, x, y) & _IN_ROOM != 0:
		var under := 0
		for i: int in body.x:
			under |= _raw(raw, x + i, y + 1)
		if under & (ReachGrid.SOLID | ReachGrid.ONE_WAY) != 0:
			bits |= _STAND
		elif under & ReachGrid.SONG_FLOOR != 0:
			bits |= _STAND | _SOFT
	for side: int in [-1, body.x]:
		var wall := true
		for j: int in body.y:
			if _raw(raw, x + side, y - j) & ReachGrid.SOLID == 0:
				wall = false
				break
		if wall:
			bits |= _WALL
	return bits

func _raw(raw: PackedInt32Array, x: int, y: int) -> int:
	return raw[_index(x, y)] if _has(x, y) else 0

func _reach(found: Dictionary[Vector2i, int], x: int, y: int, bits: int) -> void:
	var cell := Vector2i(x, y)
	found[cell] = found.get(cell, 0) | bits

# A state packed in one int: column, anchor, profile, step and whether the air jump is kept.
func _key(x: int, anchor: int, profile: int, k: int, air: int) -> int:
	return (x << 27) | ((anchor + _ANCHOR_BIAS) << 11) | (profile << 9) | (k << 1) | air

func _push(states: PackedInt64Array, seen: Dictionary[int, bool], key: int) -> void:
	# Keeping the air jump dominates having spent it.
	if seen.has(key) or (key & 1 == 0 and seen.has(key | 1)):
		return
	seen[key] = true
	states.append(key)

# Px above the anchor at lattice step `k`.
func _height(profile: int, k: int) -> float:
	if profile == _Profile.TERMINAL:
		return -_terminal_drop * k
	var heights := _heights[profile]
	if k < heights.size():
		return heights[k]
	return heights[heights.size() - 1] - _terminal_drop * (k - heights.size() + 1)

func _sample(heights: PackedFloat32Array, step: float) -> PackedFloat32Array:
	var per := step / JumpReach.STEP
	var sampled := PackedFloat32Array()
	var k := 0
	while k * per <= heights.size() - 1:
		var at := k * per
		var i := floori(at)
		sampled.append(lerpf(heights[i], heights[mini(i + 1, heights.size() - 1)], at - i))
		k += 1
	return sampled

func _at(cell: Vector2i) -> int:
	var local := cell - _box.position
	return _cells[_index(local.x, local.y)] if _has(local.x, local.y) else 0

func _is(x: int, y: int, bit: int) -> bool:
	return _cells[_index(x, y)] & bit != 0

func _has(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < _box.size.x and y < _box.size.y

func _index(x: int, y: int) -> int:
	return y * _box.size.x + x
