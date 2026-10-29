class_name SeedPurse
extends RefCounted
## Season seeds held, derived from caches taken and purchases, never stored (systems/seeds-and-the-seller).


static func taken(data: PlayerData) -> int:
	return data.caches_taken.size()

## Seeds paid for every offer bought and every rumour told, at today's prices.
static func spent(data: PlayerData, stock: SeedStock) -> int:
	var total := 0
	for id: StringName in data.offers_bought:
		var offer := stock.get_offer(id)
		if offer != null:
			total += offer.price
	var rumour := stock.rumour()
	if rumour != null:
		total += rumour.price * data.rumours.size()
	return total

## Clamped at 0: a price raised after a save was written never shows a debt.
static func held(data: PlayerData, stock: SeedStock) -> int:
	return maxi(taken(data) - spent(data, stock), 0)

## A MAP or REPLANT offer was bought; a RUMOUR is never "bought", it is told.
static func bought(offer: SeedOffer, data: PlayerData) -> bool:
	return data.offers_bought.has(offer.id)

## The offers the seller shows, in stock order: MAP and REPLANT until bought, RUMOUR while a piece is left to tell.
static func on_sale(stock: SeedStock, found: FoundCatalog, data: PlayerData) -> Array[SeedOffer]:
	var offers: Array[SeedOffer] = []
	for offer: SeedOffer in stock.offers:
		if offer.kind == SeedOffer.Kind.RUMOUR:
			if Rumours.next(found, data) != null:
				offers.append(offer)
		elif not bought(offer, data):
			offers.append(offer)
	return offers

static func can_buy(offer: SeedOffer, stock: SeedStock, found: FoundCatalog, data: PlayerData) -> bool:
	return on_sale(stock, found, data).has(offer) and held(data, stock) >= offer.price

## The `region_key` of every MAP offer bought.
static func bought_map_regions(stock: SeedStock, data: PlayerData) -> PackedStringArray:
	var regions := PackedStringArray()
	for offer: SeedOffer in stock.offers:
		if offer.kind == SeedOffer.Kind.MAP and bought(offer, data):
			regions.append(offer.region_key)
	return regions
