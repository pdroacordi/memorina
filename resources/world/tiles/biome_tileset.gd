@tool
class_name BiomeTileset
extends Resource
## A biome's look sheets, one corner-Wang sheet per look, drawn on the dual grid; a room names it with `tileset =` (architecture/biome-tilesets).

## Draw order: a later look is laid over an earlier one. Changing it is a room importer FORMAT_VERSION bump.
enum Look { EARTH, STONE, WOOD, WALL }

const DIRECTORY := "res://resources/world/tiles/biomes/"
## 4 columns of 32 px; 3 season bands of GroundAutotile.BAND_ROWS rows.
const SHEET_SIZE := Vector2i(128, 960)
const COLUMNS := 4
## Three season bands.
const ROWS := GroundAutotile.BAND_ROWS * 3
## The crack decals' atlas source id, past every Look; 4 variants across, one row per season band.
const CRACK_SOURCE := 16
const CRACK_VARIANTS := 4
const CRACK_SIZE := Vector2i(128, 96)

# Each setter drops the cached TileSet, so a sheet changed in the inspector shows without a reload.
@export var earth: Texture2D:
	set(value):
		earth = value
		_tile_set = null
@export var stone: Texture2D:
	set(value):
		stone = value
		_tile_set = null
@export var wood: Texture2D:
	set(value):
		wood = value
		_tile_set = null
@export var wall: Texture2D:
	set(value):
		wall = value
		_tile_set = null
## Hairline crack decals a cracked secret cell draws (architecture/secret-false-walls); null when the biome has none.
@export var crack: Texture2D:
	set(value):
		crack = value
		_tile_set = null
## Variants each look's sheet draws of its fill and straight edges, 0..4, indexed by Look.
@export var fill_variants := PackedInt32Array([0, 0, 0, 0])
## Developer text for the map guide.
@export_multiline var description: String = ""

var _tile_set: TileSet


## The biome `id`, or null when no `<id>.tres` exists.
static func find(id: String) -> BiomeTileset:
	var path := DIRECTORY + id + ".tres"
	return load(path) as BiomeTileset if ResourceLoader.exists(path) else null

## The file name: what a room's `tileset =` names.
func id() -> String:
	return resource_path.get_file().get_basename()

func sheet(look: Look) -> Texture2D:
	match look:
		Look.EARTH:
			return earth
		Look.STONE:
			return stone
		Look.WOOD:
			return wood
	return wall

func has_look(look: Look) -> bool:
	return sheet(look) != null

## How many variants of the fill and straight edges `look`'s sheet draws, 0..GroundAutotile.MAX_VARIANTS.
func variants(look: Look) -> int:
	return fill_variants[look] if look < fill_variants.size() else 0

## Sheets off the contract, as messages; empty when the biome is sound.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if fill_variants.size() != Look.size():
		found.append("fill_variants has %d entries, not %d" % [fill_variants.size(), Look.size()])
	for look: int in Look.values():
		var texture := sheet(look)
		if texture != null and Vector2i(texture.get_size()) != SHEET_SIZE:
			found.append("%s sheet is %s, not %s" % [Look.keys()[look].to_lower(), Vector2i(texture.get_size()), SHEET_SIZE])
		if variants(look) < 0 or variants(look) > GroundAutotile.MAX_VARIANTS:
			found.append("%s has %d variants" % [Look.keys()[look].to_lower(), variants(look)])
	if crack != null and Vector2i(crack.get_size()) != CRACK_SIZE:
		found.append("crack sheet is %s, not %s" % [Vector2i(crack.get_size()), CRACK_SIZE])
	return found

## One atlas source per present look, source id = Look; every slot defined (gotchas/tileset-padding-bakes-only-defined-tiles).
func tile_set() -> TileSet:
	if _tile_set == null:
		_tile_set = TileSet.new()
		_tile_set.tile_size = Vector2i(RoomMap.CELL_PX, RoomMap.CELL_PX)
		for look: int in Look.values():
			var texture := sheet(look)
			if texture == null:
				continue
			var source := TileSetAtlasSource.new()
			source.texture = texture
			source.texture_region_size = Vector2i(RoomMap.CELL_PX, RoomMap.CELL_PX)
			for y: int in ROWS:
				for x: int in COLUMNS:
					source.create_tile(Vector2i(x, y))
			_tile_set.add_source(source, look)
		if crack != null:
			var decals := TileSetAtlasSource.new()
			decals.texture = crack
			decals.texture_region_size = Vector2i(RoomMap.CELL_PX, RoomMap.CELL_PX)
			for y: int in 3:
				for x: int in CRACK_VARIANTS:
					decals.create_tile(Vector2i(x, y))
			_tile_set.add_source(decals, CRACK_SOURCE)
	return _tile_set
