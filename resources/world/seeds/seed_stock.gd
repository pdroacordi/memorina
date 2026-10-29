class_name SeedStock
extends Resource
## The seller's offers in shop order (systems/seeds-and-the-seller).

const DEFAULT_PATH := "res://resources/world/seeds/seed_stock.tres"

@export var offers: Array[SeedOffer] = []


## The offer `id`; null when the stock has none.
func get_offer(id: StringName) -> SeedOffer:
	for offer: SeedOffer in offers:
		if offer.id == id:
			return offer
	return null

## The one RUMOUR offer; null in an invalid stock.
func rumour() -> SeedOffer:
	for offer: SeedOffer in offers:
		if offer.kind == SeedOffer.Kind.RUMOUR:
			return offer
	return null

## Every problem found; empty when valid.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var ids: Dictionary[StringName, bool] = {}
	var regions: Dictionary[String, bool] = {}
	var counts: Dictionary[int, int] = {}
	for offer: SeedOffer in offers:
		if offer == null or offer.id == &"":
			problems.append("an offer has no id")
			continue
		if ids.has(offer.id):
			problems.append("%s is listed twice" % offer.id)
		ids[offer.id] = true
		if offer.price < 1:
			problems.append("%s costs %d seeds" % [offer.id, offer.price])
		counts[offer.kind] = counts.get(offer.kind, 0) + 1
		if offer.kind == SeedOffer.Kind.MAP:
			if offer.region_key.is_empty():
				problems.append("%s names no region" % offer.id)
			elif regions.has(offer.region_key):
				problems.append("%s sells %s twice" % [offer.id, offer.region_key])
			regions[offer.region_key] = true
	for kind: SeedOffer.Kind in [SeedOffer.Kind.RUMOUR, SeedOffer.Kind.REPLANT]:
		if counts.get(kind, 0) != 1:
			problems.append("%d offers of kind %d" % [counts.get(kind, 0), kind])
	return problems
