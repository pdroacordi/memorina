@tool
class_name RoomLegendEntry extends Resource

## One character of a room map (docs/maps/README.md). The legend is the only
## place a character means anything: the parser, the importer, the builder and
## the generated map guide all read it, so a new character is a new entry
## here and nothing else.

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

## Exactly one character. Never ".", which is always empty.
@export var symbol: String = ""
@export var kind: Kind = Kind.GROUND
## GROUND and PLATFORM: what it is made of.
@export var ground: Enums.Ground = Enums.Ground.EARTH
## WATER: the WaterLayer preset that pours this kind of water.
@export var water_layer: PackedScene
## ENTITY: what is placed.
@export var scene: PackedScene
@export var anchor: Anchor = Anchor.FEET
## One line for the map guide: what the character is and when to use it.
@export_multiline var description: String = ""
