class_name MapGrid
extends RefCounted
## One room's seen cells as a bitset; see docs/knowledge/architecture/map-reveal-seen-cells-per-room.md.

## World px per cell. Part of the save format: changing it needs a migration that resamples by world position.
const CELL_PX := 64
## Bytes before the bits: cols then rows, each u16 little-endian.
const HEADER_BYTES := 4
const MAX_SIDE := 0xFFFF

var cols: int:
	get: return _cols
var rows: int:
	get: return _rows

var _cols: int = 0
var _rows: int = 0
## Row-major, bit `i` in byte `i >> 3` at `1 << (i & 7)`.
var _bits: PackedByteArray = PackedByteArray()


func _init(dims: Vector2i = Vector2i.ZERO) -> void:
	_cols = clampi(dims.x, 0, MAX_SIDE)
	_rows = clampi(dims.y, 0, MAX_SIDE)
	_bits.resize(_byte_count(_cols, _rows))
	_bits.fill(0)

## Cells that cover `bounds` (world px), rounded up.
static func dims_for(bounds: Rect2) -> Vector2i:
	return Vector2i(ceili(bounds.size.x / CELL_PX), ceili(bounds.size.y / CELL_PX))

## An empty or malformed value gives an empty grid; a different header keeps the cells both sizes share.
static func from_bytes(bytes: PackedByteArray, dims: Vector2i) -> MapGrid:
	var grid := MapGrid.new(dims)
	if bytes.size() < HEADER_BYTES:
		return grid
	var old_cols := bytes.decode_u16(0)
	var old_rows := bytes.decode_u16(2)
	if bytes.size() != HEADER_BYTES + _byte_count(old_cols, old_rows):
		return grid
	if old_cols == grid._cols and old_rows == grid._rows:
		grid._bits = bytes.slice(HEADER_BYTES)
		return grid
	var old_bits := bytes.slice(HEADER_BYTES)
	for row: int in mini(old_rows, grid._rows):
		for col: int in mini(old_cols, grid._cols):
			if _bit(old_bits, row * old_cols + col):
				grid._set_bit(row * grid._cols + col)
	return grid

func to_bytes() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(HEADER_BYTES)
	bytes.encode_u16(0, _cols)
	bytes.encode_u16(2, _rows)
	bytes.append_array(_bits)
	return bytes

## The cells whose centre lies inside `local_rect` (px from the room's top-left), clipped to the grid.
## With `room_size`, a last cell cut by the room's edge counts by the centre of its part inside the room.
func cells_in(local_rect: Rect2, room_size: Vector2 = Vector2.ZERO) -> Rect2i:
	var first := Vector2i(
		_first_index(local_rect.position.x, _cols),
		_first_index(local_rect.position.y, _rows))
	var end := Vector2i(
		_end_index(local_rect.position.x, local_rect.end.x, _cols, room_size.x),
		_end_index(local_rect.position.y, local_rect.end.y, _rows, room_size.y))
	return Rect2i(first, (end - first).max(Vector2i.ZERO))

## True only if a cell was not seen before.
func mark_cells(cells: Rect2i) -> bool:
	var changed := false
	for row: int in range(cells.position.y, cells.end.y):
		for col: int in range(cells.position.x, cells.end.x):
			var index := row * _cols + col
			if not _bit(_bits, index):
				_set_bit(index)
				changed = true
	return changed

## Marks `cells_in(local_rect, room_size)`; true only if a cell was not seen before.
func mark_rect(local_rect: Rect2, room_size: Vector2 = Vector2.ZERO) -> bool:
	return mark_cells(cells_in(local_rect, room_size))

func is_seen(col: int, row: int) -> bool:
	if col < 0 or row < 0 or col >= _cols or row >= _rows:
		return false
	return _bit(_bits, row * _cols + col)

## One byte per cell (1 seen, 0 not), row-major, inside a border of unseen cells: (cols + 2) x (rows + 2).
func padded_cells() -> PackedByteArray:
	var width := _cols + 2
	var cells := PackedByteArray()
	cells.resize(width * (_rows + 2))
	cells.fill(0)
	for row: int in _rows:
		var bit := row * _cols
		var at := (row + 1) * width + 1
		for col: int in _cols:
			cells[at + col] = (_bits[(bit + col) >> 3] >> ((bit + col) & 7)) & 1
	return cells

func is_empty() -> bool:
	for byte: int in _bits:
		if byte != 0:
			return false
	return true

static func _first_index(start: float, count: int) -> int:
	return clampi(ceili(start / CELL_PX - 0.5), 0, count)

## One past the last cell whose centre is before `end`; the cut last cell's centre is the middle of its part up to `room_end`.
static func _end_index(start: float, end: float, count: int, room_end: float) -> int:
	var index := clampi(ceili(end / CELL_PX - 0.5), 0, count)
	var last := count - 1
	if index == last and room_end > last * CELL_PX and room_end < count * CELL_PX:
		var centre := (last * CELL_PX + room_end) * 0.5
		if start <= centre and centre < end:
			index = count
	return index

static func _byte_count(col_count: int, row_count: int) -> int:
	return (col_count * row_count + 7) >> 3

static func _bit(bits: PackedByteArray, index: int) -> bool:
	return (bits[index >> 3] & (1 << (index & 7))) != 0

func _set_bit(index: int) -> void:
	_bits[index >> 3] |= 1 << (index & 7)
