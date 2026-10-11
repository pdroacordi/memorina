class_name HelixView extends Node2D

## Draws a HelixStair's turning tower (architecture/walkable-helix-stair, Revision): HelixFaces at art resolution into a
## nearest-filtered SubViewport, shown at 2x behind the room's own art. It has no clock: the turn and the eye come from
## the stair's rider and the camera, so it turns in the grey as the camera moves in the grey.

const ART_SCALE := 2
## Behind the room's tiles (0), in front of back walls (-20) and the backdrop (-30).
const Z := -15

## Times the faces were rebuilt and drawn; read by tests.
var redraws := 0

var _stair: HelixStair
## The view's top-left and size in game px, from the axis base.
var _origin := Vector2.ZERO
var _size := Vector2i.ZERO
var _phi := NAN
var _eye := NAN
var _faces: Array[HelixFaces.Face] = []
var _viewport: SubViewport
var _canvas: Node2D
var _sprite: Sprite2D


## Called by HelixStair before the view enters the tree: the rect it covers, px from the axis base (even, on the 2x grid).
func setup(stair: HelixStair, origin: Vector2, size: Vector2i) -> void:
	_stair = stair
	_origin = origin
	_size = size

func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.size = _size / ART_SCALE
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	_canvas = Node2D.new()
	_canvas.name = "Canvas"
	_canvas.draw.connect(_draw_faces)
	_viewport.add_child(_canvas)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = _viewport.get_texture()
	_sprite.centered = false
	_sprite.scale = Vector2(ART_SCALE, ART_SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.position = HelixStair.AXIS + _origin
	_sprite.z_index = Z
	add_child(_sprite)

func _process(_delta: float) -> void:
	refresh(_stair.angle(), _eye_height())

## Rebuilds and redraws when the turn or the eye moved; nothing otherwise.
func refresh(phi: float, eye: float) -> void:
	if phi == _phi and eye == _eye:
		return
	_phi = phi
	_eye = eye
	var half := get_viewport_rect().size.y * 0.5
	_faces = HelixFaces.build(_stair.shape, _stair.look, _stair.hand, phi, eye, eye - half, eye + half, -_origin.y)
	_canvas.queue_redraw()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	redraws += 1

func sprite() -> Sprite2D:
	return _sprite

func viewport() -> SubViewport:
	return _viewport

## The camera's screen-centre height, px from the axis base; the view's middle without a camera.
func _eye_height() -> float:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return _origin.y + _size.y * 0.5
	return camera.get_screen_center_position().y - to_global(HelixStair.AXIS).y

func _draw_faces() -> void:
	for face: HelixFaces.Face in _faces:
		var points := _to_art(face.points)
		if Geometry2D.triangulate_polygon(points).is_empty():
			continue
		_canvas.draw_colored_polygon(points, face.fill)
		if face.line.a > 0.0:
			var closed := points.duplicate()
			closed.append(points[0])
			_canvas.draw_polyline(closed, face.line, 1.0)
		if face.accent_color.a > 0.0:
			var accent := _to_art(face.accent)
			if accent.size() >= 2:
				_canvas.draw_polyline(accent, face.accent_color, 1.0)
	var look := _stair.look
	if look.bell != null:
		var at := HelixProjection.project(_stair.shape, Vector3(0.0, -look.bell_height, 0.0), _eye)
		# The bell's sheet is at 2x density like every sprite; the viewport draws art px.
		var size := look.bell.get_size() / ART_SCALE
		var art := ((at - _origin) / ART_SCALE).round() - Vector2(roundf(size.x * 0.5), 0.0)
		_canvas.draw_texture_rect(look.bell, Rect2(art, size), false)

## Screen px from the axis base to the viewport's art px, on whole pixels.
func _to_art(points: PackedVector2Array) -> PackedVector2Array:
	var art := PackedVector2Array()
	for point: Vector2 in points:
		var at := ((point - _origin) / ART_SCALE).round()
		if art.is_empty() or art[-1] != at:
			art.append(at)
	if art.size() > 1 and art[0] == art[-1]:
		art.remove_at(art.size() - 1)
	return art
