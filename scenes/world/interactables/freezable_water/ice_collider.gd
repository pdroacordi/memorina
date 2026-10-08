class_name IceCollider extends StaticBody2D

## Ice collision as a chain of segments along the sheet's top, toggled independently (docs/knowledge/architecture/ice-is-its-own-sheet.md).

## Steepest segment that is a one-way floor, radians; steeper ones are walls (CharacterBody2D's default floor_max_angle).
const MAX_FLOOR_ANGLE := PI / 4.0

var _shapes: Array[CollisionShape2D] = []
var _solid := PackedByteArray()

# Thawing ice is not a safe respawn surface.
func _ready() -> void:
	add_to_group(SafeGroundTracker.UNSAFE)

## Makes `count` disabled segments; set_profile() places them.
func build(count: int) -> void:
	for i in count:
		var segment := CollisionShape2D.new()
		segment.shape = SegmentShape2D.new()
		segment.one_way_collision = true
		segment.disabled = true
		add_child(segment)
		_shapes.append(segment)
	_solid.resize(count)

## Lays segment i from world `points[i]` to `points[i + 1]`; a segment already solid keeps its place.
func set_profile(points: PackedVector2Array) -> void:
	assert(points.size() == _shapes.size() + 1, "One more point than segments")
	for i in _shapes.size():
		if _solid[i] == 1:
			continue
		var segment := _shapes[i].shape as SegmentShape2D
		segment.a = to_local(points[i])
		segment.b = to_local(points[i + 1])
		_shapes[i].set_deferred(&"one_way_collision", IceSheetShape.walkable(points, i, MAX_FLOOR_ANGLE))

## Updates changed segments; deferred because collision shapes cannot change during physics flush.
func set_solid(mask: PackedByteArray) -> void:
	for i in mini(mask.size(), _solid.size()):
		if mask[i] != _solid[i]:
			_solid[i] = mask[i]
			_shapes[i].set_deferred(&"disabled", mask[i] == 0)

func is_solid(index: int) -> bool:
	return _solid[index] == 1

## World position of segment `index`'s left end.
func segment_start(index: int) -> Vector2:
	return to_global((_shapes[index].shape as SegmentShape2D).a)
