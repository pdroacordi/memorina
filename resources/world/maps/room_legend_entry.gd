@tool
class_name RoomLegendEntry extends Resource

## Defines room-map symbols used by the parser, importer, builder, and map guide (docs/maps/README.md).

enum Kind {
	## Solid ground of `ground`'s material, drawn by GroundAutotile.
	GROUND,
	## A one-tile-high ledge you can jump up through (one-way collision).
	PLATFORM,
	## A cell of water, poured by the `water_layer` preset (a WaterLayer).
	WATER,
	## A scene placed at the cell, configured from the map's [entities].
	ENTITY,
}

## Where in its cell an ENTITY's origin goes.
enum Anchor {
	## Bottom centre: things that stand on the floor below their cell.
	FEET,
	## The cell's centre: things that hang or float.
	CENTER,
}

## Exactly one character; `.` is reserved for empty cells.
@export var symbol: String = ""
@export var kind: Kind = Kind.GROUND
## GROUND and PLATFORM: what it is made of.
@export var ground: Enums.Ground = Enums.Ground.EARTH
## WATER: the WaterLayer preset that pours this kind of water.
@export var water_layer: PackedScene
## WATER: a reach, the level Chuva raises the water under it to; alone it is a dry basin.
@export var reach := false
## WATER: whether a reach painted above it may join it; a lake seen from above never rises.
@export var takes_reach := true
## WATER reach: true where Chuva raises the water to it, false where only Redoma's displaced water does.
@export var rains := true
## ENTITY: what is placed.
@export var scene: PackedScene
@export var anchor: Anchor = Anchor.FEET
## ENTITY: params every placement must give in its [entities] line - an id the
## save remembers it by, which a scene default would quietly share between
## every placement. RoomMapValidator rejects a placement missing one.
@export var required_params: PackedStringArray = PackedStringArray()
## One line for the map guide: what the character is and when to use it.
@export_multiline var description: String = ""
