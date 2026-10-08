class_name IceSheet extends Node2D

## Draws an IceSheetShape as world art above the water (docs/knowledge/architecture/ice-is-its-own-sheet.md).

const BYTES_PER_TEXEL := 16

var _image: Image
var _texture: ImageTexture
var _bytes := PackedByteArray()
var _rect := Rect2()

# z_index 51, absolute, is authored in the scenes: above WaterQuad.Z, so ice covers water.
func _ready() -> void:
	assert(z_index == WaterQuad.Z + 1 and not z_as_relative, "IceSheet must draw at absolute WaterQuad.Z + 1")
	top_level = true
	global_position = Vector2.ZERO
	material = material.duplicate()

func _draw() -> void:
	if _rect.size.y > 0.0:
		draw_rect(_rect, Color.WHITE)

## Sizes the data for `column_count` columns starting at world x `left`, with the look's ramp.
func setup(column_count: int, left: float, column_width: float, ice_ramp: Texture2D, thickness: float) -> void:
	_image = Image.create_empty(column_count, 1, false, Image.FORMAT_RGBAF)
	_texture = ImageTexture.create_from_image(_image)
	_bytes.resize(column_count * BYTES_PER_TEXEL)
	var shader := material as ShaderMaterial
	shader.set_shader_parameter(&"sheet_data", _texture)
	shader.set_shader_parameter(&"ice_ramp", ice_ramp)
	shader.set_shader_parameter(&"sheet_left", left)
	shader.set_shader_parameter(&"column_width", column_width)
	shader.set_shader_parameter(&"ice_thickness", thickness)
	_rect = Rect2(left, 0.0, column_count * column_width, 0.0)

## Lays the drawn rectangle over every band of `shape`.
func relayout(shape: IceSheetShape) -> void:
	var span := shape.y_range()
	_rect = Rect2(_rect.position.x, span.x, _rect.size.x, span.y - span.x)
	queue_redraw()

## Uploads each column's band and how solid it looks, 0..1.
func write(shape: IceSheetShape, solidity: PackedFloat32Array) -> void:
	for column in shape.column_count():
		var at := column * BYTES_PER_TEXEL
		var band := shape.band(column)
		_bytes.encode_float(at, band.x)
		_bytes.encode_float(at + 4, band.y)
		_bytes.encode_float(at + 8, solidity[column] if shape.has(column) else 0.0)
		_bytes.encode_float(at + 12, 0.0)
	_image.set_data(shape.column_count(), 1, false, Image.FORMAT_RGBAF, _bytes)
	_texture.update(_image)
