class_name RootCatch extends Node2D

## Roots grown from the earth faces either side of a LoweringPlatform to its edges; they hold it while the pulse covers the faces.

var _body: LoweringPlatform
var _faces := PackedVector2Array()
var _strands: Array[RootStrands] = []
var _sprites: Array[Sprite2D] = []

func _exit_tree() -> void:
	if is_instance_valid(_body):
		_body.let_go(self)

## `faces` and `edges` are world points, left then right; the body is seized at once.
func setup(body: LoweringPlatform, faces: PackedVector2Array, edges: PackedVector2Array, strand: Texture2D) -> void:
	top_level = true
	_body = body
	_faces = faces
	body.seize(self)
	for side in 2:
		_strands.append(RootStrands.new(faces[side].distance_to(edges[side])))
		var sprite := Sprite2D.new()
		sprite.texture = strand
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.region_rect = Rect2(0.0, 0.0, 0.0, RootSpanView.STRAND_THICKNESS)
		sprite.rotation = (edges[side] - faces[side]).angle()
		sprite.offset = Vector2(0.0, -RootSpanView.STRAND_THICKNESS * 0.5)
		sprite.position = faces[side]
		add_child(sprite)
		_sprites.append(sprite)

## Grows or withers the roots; false once they have withered away and let go.
func advance(delta: float, grower: RootGrower) -> bool:
	var bare := true
	for side in 2:
		var strands := _strands[side]
		var held := grower.holds(_faces[side])
		strands.advance(delta, grower.grow_speed, grower.wither_speed, grower.memory_at(_faces[side]), 0.0, held, false)
		_sprites[side].region_rect.size.x = strands.a
		bare = bare and strands.a <= 0.0
	if bare and not grower.holds(_faces[0]) and not grower.holds(_faces[1]):
		_body.let_go(self)
		return false
	return true
