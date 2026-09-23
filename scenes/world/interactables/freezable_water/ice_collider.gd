class_name IceCollider extends StaticBody2D

## The ice's weight, as a row of fixed-width segments that switch on and off.
##
## A pool of shapes toggled one by one, rather than one shape resized or a
## polygon rebuilt, because the whole mechanic is a DISCONTINUITY - solid here,
## melted there - which one resized shape cannot say, and a rebuilt polygon is
## re-cooked on every assignment while a body is standing on it.
##
## One-way, so a body can jump up through ice from below, and so a segment
## vanishing under Ivo drops him cleanly instead of trapping him inside it.
## Which segments are solid is decided elsewhere (IceFront), conservatively:
## collision never reaches past the ice that looks solid.

var _shapes: Array[CollisionShape2D] = []
var _solid := PackedByteArray()

# Ice thaws: standing on it is never somewhere a hazard sends a body back to.
func _ready() -> void:
	add_to_group(SafeGroundTracker.UNSAFE)

## Lays out one disabled segment per `segment_width` world pixels across
## [left, left + width), their tops on `top`.
func build(left: float, width: float, top: float, segment_width: int, thickness: int) -> void:
	assert(is_equal_approx(fmod(width, float(segment_width)), 0.0),
		"The water's width must be a whole number of ice segments")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(segment_width, thickness)
	var count := int(width / segment_width)
	for i in count:
		var segment := CollisionShape2D.new()
		segment.shape = shape
		segment.one_way_collision = true
		segment.disabled = true
		add_child(segment)
		segment.global_position = Vector2(left + (i + 0.5) * segment_width, top + thickness * 0.5)
		_shapes.append(segment)
	_solid.resize(count)

## One byte per segment. Only the segments that changed are touched, and
## deferred: this runs during the physics step, where a shape must not change.
func set_solid(mask: PackedByteArray) -> void:
	for i in mini(mask.size(), _solid.size()):
		if mask[i] != _solid[i]:
			_solid[i] = mask[i]
			_shapes[i].set_deferred(&"disabled", mask[i] == 0)
