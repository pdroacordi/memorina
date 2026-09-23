class_name WaterSurfaceTexture extends RefCounted

## Packs a WaterSurfaceField (and the ice over it) into the 1xN float texture
## the water shaders read: r = height, g = foam, a = ice solidity. The layout is
## declared once, in water_common.gdshaderinc.
##
## Created once and then only update()d: update() requires the same size and
## format, and recreating the texture every frame is the slow path.

const BYTES_PER_TEXEL := 16

var texture: ImageTexture
var _image: Image
# The texels' bytes, written in place every frame rather than converted from a
# float array (which would allocate a new buffer per frame).
var _bytes := PackedByteArray()

func _init(column_count: int) -> void:
	_image = Image.create_empty(column_count, 1, false, Image.FORMAT_RGBAF)
	texture = ImageTexture.create_from_image(_image)
	_bytes.resize(column_count * BYTES_PER_TEXEL)

## `field` is null for a body with no profile (a lake): its surface is flat.
func write(field: WaterSurfaceField, solidity: PackedFloat32Array) -> void:
	var count := solidity.size()
	for i in count:
		var at := i * BYTES_PER_TEXEL
		_bytes.encode_float(at, field.height(i) if field else 0.0)
		_bytes.encode_float(at + 4, field.energy(i) if field else 0.0)
		_bytes.encode_float(at + 12, solidity[i])
	_image.set_data(count, 1, false, Image.FORMAT_RGBAF, _bytes)
	texture.update(_image)
