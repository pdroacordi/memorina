class_name SeedOffer
extends Resource
## One thing the village seller trades for season seeds (systems/seeds-and-the-seller).

## Append only: seed_stock.tres stores the number.
enum Kind {
	## The room outlines of one region, drawn faint on the map.
	MAP,
	## Marks the region of the next found piece still lying (Rumours.next); repeatable.
	RUMOUR,
	## The village gardens grow back (village_replanted.tres).
	REPLANT,
}

## The OFFER_BOUGHT fact id of a MAP or REPLANT offer.
@export var id: StringName
@export var kind: Kind = Kind.MAP
## Seeds, 1 or more.
@export var price: int = 1
## MAP only: the bought region's `Region.name_key`; the row shows tr() of it.
@export var region_key: String = ""
