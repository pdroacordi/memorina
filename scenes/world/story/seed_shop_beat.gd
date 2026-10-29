class_name SeedShopBeat
extends DialogueBeat
## The seller's trade, a beat in his talk: it opens the shop panel, checks and records each purchase, and gives the talk
## back on Leave (systems/seeds-and-the-seller). No WorldFreeze writer, no input reader, no router screen.

# Not exported: tests swap them.
var stock: SeedStock = preload(SeedStock.DEFAULT_PATH)
var found: FoundCatalog = preload(FoundCatalog.DEFAULT_PATH)

@onready var _panel: SeedShopPanel = $Layer/SeedShopPanel


func _ready() -> void:
	_panel.chosen.connect(_on_chosen)
	_panel.left.connect(_on_left)

func start() -> void:
	var data := SaveSystem.player_data
	_panel.open(SeedPurse.on_sale(stock, found, data), SeedPurse.held(data, stock))
	super.start()

func panel() -> SeedShopPanel:
	return _panel

# Re-checked at the press: the panel is a view and may be stale.
func _on_chosen(offer_id: StringName) -> void:
	var data := SaveSystem.player_data
	var offer := stock.get_offer(offer_id)
	if offer == null or not SeedPurse.can_buy(offer, stock, found, data):
		return
	match offer.kind:
		SeedOffer.Kind.MAP:
			SaveSystem.buy_offer(offer.id)
			_refresh()
			_panel.say("SHOP_SAID_MAP", offer.region_key)
		SeedOffer.Kind.REPLANT:
			SaveSystem.buy_offer(offer.id)
			_refresh()
			_panel.say("SHOP_SAID_REPLANT")
		SeedOffer.Kind.RUMOUR:
			var piece := Rumours.next(found, data)
			SaveSystem.add_rumour(piece.slot_id)
			_refresh()
			_panel.say("SHOP_SAID_RUMOUR", _region_key(piece.room))

func _refresh() -> void:
	var data := SaveSystem.player_data
	_panel.show_offers(SeedPurse.on_sale(stock, found, data), SeedPurse.held(data, stock))

func _on_left() -> void:
	_panel.close()
	finish()

## The `name_key` of the region holding the room `room_id`; empty when no such room is in the world.
func _region_key(room_id: StringName) -> String:
	for room: Room in get_tree().get_nodes_in_group(Room.GROUP):
		if room.id() == room_id:
			return room.get_region().name_key
	push_error("No room %s in the world for a rumour" % room_id)
	return ""
