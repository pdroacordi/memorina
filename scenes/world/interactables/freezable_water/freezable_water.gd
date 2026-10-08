class_name FreezableWater extends Node2D

## Coordinates water and ice when a FREEZE pulse reaches it (design 03 §6.3-6.4, systems/water).
## The ice keeps the height it froze at whatever the water does under it (docs/knowledge/architecture/ice-is-its-own-sheet.md).

## Receiver headroom above the waterline, in world pixels.
const RECEIVER_HEADROOM := 8

@export var ice: IceProfile

var _front: IceFront
var _shape: IceSheetShape
var _solidity := PackedFloat32Array()
var _per_segment := 1

@onready var _water: WaterBody = $Water
@onready var _collider: IceCollider = $IceCollider
@onready var _sheet: IceSheet = $IceSheet
@onready var _receiver_shape: CollisionShape2D = $SongReceiver/CollisionShape2D

func _ready() -> void:
	assert(ice != null, "%s needs an IceProfile" % name)
	var columns := _water.column_count()
	var width := _water.column_width()
	var left := _water.global_position.x - _water.size.x * 0.5
	_front = IceFront.new(columns, width, ice)
	_shape = IceSheetShape.new(columns, width, left)
	_solidity.resize(columns)
	@warning_ignore("integer_division")
	_per_segment = ice.segment_width / width
	_collider.build(_shape.segment_count(_per_segment))
	_sheet.setup(columns, left, width, _water.look.ice_ramp, ice.thickness)
	# Fit the receiver to dimensions authored by WaterLayer.
	_water.fit_area(_receiver_shape, -RECEIVER_HEADROOM)

func _physics_process(delta: float) -> void:
	if not _front.is_active():
		return
	_front.advance(delta, _water.column_rates(), _water.wet_columns())
	var changed := false
	for column in _front.column_count():
		var hold := _front.hold(column)
		_water.set_hold(column, hold)
		_solidity[column] = _front.solidity(column)
		if hold > 0.0 and not _shape.has(column):
			# Whole px, as the water's surface and the collider are drawn.
			var top := roundf(_water.ice_top(column))
			if is_finite(top):
				_shape.capture(column, top, maxf(top, _water.surface_rest_y()) + ice.thickness)
				changed = true
		elif hold <= 0.0 and _shape.has(column):
			_shape.release(column)
			changed = true
	if changed:
		_sheet.relayout(_shape)
		_collider.set_profile(_shape.segment_points(_per_segment))
	_sheet.write(_shape, _solidity)
	_collider.set_solid(_front.solid_segments())

## Whether there is ice on the water; RainBasin refuses to rise under it.
func is_frozen() -> bool:
	return _front.is_active()

func _on_song_entered(_song: Song, origin: Vector2) -> void:
	# A dry basin has no water to freeze.
	if _water.is_dry():
		return
	_front.freeze_from(_water.column_of(origin.x))
