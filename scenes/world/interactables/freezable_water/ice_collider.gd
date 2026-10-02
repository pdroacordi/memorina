class_name IceCollider extends StaticBody2D

## Segment collision for frozen water; segments are one-way and toggled independently.

var _shapes: Array[CollisionShape2D] = []
var _solid := PackedByteArray()
var _thickness := 0

# Thawing ice is not a safe respawn surface.
func _ready() -> void:
	add_to_group(SafeGroundTracker.UNSAFE)

## Builds segments across the width in px, with their tops at `top`.
func build(left: float, width: float, top: float, segment_width: int, thickness: int) -> void:
	assert(is_equal_approx(fmod(width, float(segment_width)), 0.0),
		"The water's width must be a whole number of ice segments")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(segment_width, thickness)
	var count := int(width / segment_width)
	_thickness = thickness
	for i in count:
		var segment := CollisionShape2D.new()
		segment.shape = shape
		segment.one_way_collision = true
		segment.disabled = true
		add_child(segment)
		segment.global_position = Vector2(left + (i + 0.5) * segment_width, top + thickness * 0.5)
		_shapes.append(segment)
	_solid.resize(count)

## Repositions segment tops in px when the water level changes.
func set_top(top: float) -> void:
	for segment: CollisionShape2D in _shapes:
		segment.global_position.y = top + _thickness * 0.5

## Updates changed segments; deferred because collision shapes cannot change during physics flush.
func set_solid(mask: PackedByteArray) -> void:
	for i in mini(mask.size(), _solid.size()):
		if mask[i] != _solid[i]:
			_solid[i] = mask[i]
			_shapes[i].set_deferred(&"disabled", mask[i] == 0)
