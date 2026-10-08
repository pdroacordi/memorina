class_name WaterSurfaceTexture extends RefCounted

## Packs water height, foam or clock and floor depth for the water shaders; layout must match water_common.gdshaderinc.

const BYTES_PER_TEXEL := 16

var texture: ImageTexture
var _image: Image
# Reused texel buffer avoids allocating a new byte array every frame.
var _bytes := PackedByteArray()

func _init(column_count: int) -> void:
	_image = Image.create_empty(column_count, 1, false, Image.FORMAT_RGBAF)
	texture = ImageTexture.create_from_image(_image)
	_bytes.resize(column_count * BYTES_PER_TEXEL)

## `floors` contains per-column depths below the rest line, in world pixels; null `field` writes clocks instead of foam.
func write(field: WaterSurfaceField, clocks: PackedFloat32Array, floors: PackedFloat32Array) -> void:
	var count := floors.size()
	for i in count:
		var at := i * BYTES_PER_TEXEL
		_bytes.encode_float(at, field.height(i) if field else 0.0)
		_bytes.encode_float(at + 4, field.energy(i) if field else clocks[i])
		_bytes.encode_float(at + 8, floors[i])
		_bytes.encode_float(at + 12, 0.0)
	_image.set_data(count, 1, false, Image.FORMAT_RGBAF, _bytes)
	texture.update(_image)
