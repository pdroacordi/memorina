class_name PropReach
extends RefCounted
## The room-local rect a contents scene's authored art draws in (props, facades, decals), read from an instance never added
## to the tree. A hidden node counts: a FactStaging may show it (systems/rooms, "Staggered builds").

## Nodes whose drawing is bounded elsewhere: the backdrop by its drawn cells, tiles and entities by the room's cells,
## foreground pieces by the camera.
const SKIPPED: Array[StringName] = [&"Backdrop", &"RoomMap", &"Foreground"]

## `of` by contents scene: authored art never moves.
static var _memo: Dictionary = {}


## The rect `contents`' authored art draws in, in the space of the Room it is added to; empty when it draws none.
static func of(contents: PackedScene) -> Rect2:
	if contents == null:
		return Rect2()
	if _memo.has(contents):
		return _memo[contents]
	var root := contents.instantiate()
	var reach := Rect2()
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != root and node.name in SKIPPED:
			continue
		stack.append_array(node.get_children())
		var drawn := drawn_rect(node)
		if drawn.has_area():
			var placed := _to_root(node) * drawn
			reach = placed if not reach.has_area() else reach.merge(placed)
	root.free()
	_memo[contents] = reach
	return reach

## The rect `node` draws a texture or polygon in, in its own space; empty for anything else.
static func drawn_rect(node: Node) -> Rect2:
	if node is Sprite2D:
		return (node as Sprite2D).get_rect()
	if node is AnimatedSprite2D:
		var sprite := node as AnimatedSprite2D
		var box := Rect2()
		if sprite.sprite_frames == null:
			return box
		for animation: StringName in sprite.sprite_frames.get_animation_names():
			for frame: int in sprite.sprite_frames.get_frame_count(animation):
				var texture := sprite.sprite_frames.get_frame_texture(animation, frame)
				if texture == null:
					continue
				var size := texture.get_size()
				var rect := Rect2((-size * 0.5 if sprite.centered else Vector2.ZERO) + sprite.offset, size)
				box = rect if not box.has_area() else box.merge(rect)
		return box
	if node is Polygon2D:
		var polygon := (node as Polygon2D).polygon
		if polygon.is_empty():
			return Rect2()
		var box := Rect2(polygon[0], Vector2.ZERO)
		for point: Vector2 in polygon:
			box = box.expand(point)
		return Rect2(box.position + (node as Polygon2D).offset, box.size)
	if node is Control:
		return Rect2(Vector2.ZERO, (node as Control).size)
	return Rect2()

# `node`'s transform in the space of the instance's root's parent.
static func _to_root(node: Node) -> Transform2D:
	var xform := Transform2D.IDENTITY
	var at := node
	while at != null:
		if at is Node2D:
			xform = (at as Node2D).transform * xform
		elif at is Control:
			xform = Transform2D(0.0, (at as Control).position) * xform
		at = at.get_parent()
	return xform
