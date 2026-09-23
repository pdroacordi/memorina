class_name WaterSurfaceTexture extends RefCounted

## Packs a WaterSurfaceField (and the ice over it) into the 1xN float texture
## the water shaders read: r = height, g = foam, a = ice solidity. The layout is
## declared once, in water_common.gdshaderinc.
##
## Created once and then only update()d: update() requires the same size and
## format, and recreating the texture every frame is the slow path.

var texture: ImageTexture
var _image: Image
var _data := PackedFloat32Array()

func _init(column_count: int) -> void:
	_image = Image.create_empty(column_count, 1, false, Image.FORMAT_RGBAF)
	texture = ImageTexture.create_from_image(_image)
	_data.resize(column_count * 4)

func write(field: WaterSurfaceField, solidity: PackedFloat32Array) -> void:
	var count := field.column_count()
	for i in count:
		_data[i * 4] = field.height(i)
		_data[i * 4 + 1] = field.energy(i)
		_data[i * 4 + 3] = solidity[i]
	_image.set_data(count, 1, false, Image.FORMAT_RGBAF, _data.to_byte_array())
	texture.update(_image)
