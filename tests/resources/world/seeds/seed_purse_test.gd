class_name SeedPurseTest extends GdUnitTestSuite

## Seeds held are caches taken minus what was paid, at today's prices, never below 0 (systems/seeds-and-the-seller).

const LETTER := preload("res://assets/sprites/world/pickups/letter.png")

var _stock: SeedStock
var _found: FoundCatalog
var _map_a: SeedOffer
var _map_b: SeedOffer
var _rumour: SeedOffer
var _replant: SeedOffer


func before_test() -> void:
	_map_a = SeedStockTest.offer(&"map_a", SeedOffer.Kind.MAP, 1, "REGION_A")
	_map_b = SeedStockTest.offer(&"map_b", SeedOffer.Kind.MAP, 2, "REGION_B")
	_rumour = SeedStockTest.offer(&"rumour", SeedOffer.Kind.RUMOUR, 1, "")
	_replant = SeedStockTest.offer(&"replant", SeedOffer.Kind.REPLANT, 3, "")
	_stock = SeedStock.new()
	_stock.offers.append_array([_map_a, _map_b, _rumour, _replant])
	_found = FoundCatalog.new()
	for slot_id: StringName in [&"letter_a", &"letter_b"]:
		var piece := FoundPiece.new()
		piece.slot_id = slot_id
		piece.texture = LETTER
		_found.pieces.append(piece)

func _data(caches: int) -> PlayerData:
	var data := PlayerData.new()
	for i: int in caches:
		data.caches_taken.append(StringName("cache_%d" % i))
	return data

func test_held_is_taken_minus_spent_with_repeated_rumours() -> void:
	var data := _data(6)
	data.offers_bought.append(&"map_b")
	data.rumours.append_array([&"letter_a", &"letter_b"])
	assert_int(SeedPurse.taken(data)).is_equal(6)
	assert_int(SeedPurse.spent(data, _stock)).is_equal(4)
	assert_int(SeedPurse.held(data, _stock)).is_equal(2)

func test_held_is_clamped_at_zero() -> void:
	var data := _data(1)
	data.offers_bought.append(&"replant")
	assert_int(SeedPurse.held(data, _stock)).is_equal(0)

func test_can_buy_refuses_what_the_player_cannot_afford() -> void:
	var data := _data(2)
	assert_bool(SeedPurse.can_buy(_map_b, _stock, _found, data)).is_true()
	assert_bool(SeedPurse.can_buy(_replant, _stock, _found, data)).is_false()

func test_can_buy_refuses_a_map_already_bought() -> void:
	var data := _data(5)
	data.offers_bought.append(&"map_a")
	assert_bool(SeedPurse.bought(_map_a, data)).is_true()
	assert_bool(SeedPurse.can_buy(_map_a, _stock, _found, data)).is_false()

func test_can_buy_refuses_a_rumour_with_none_left() -> void:
	var data := _data(5)
	data.found_pieces.append(&"letter_a")
	data.rumours.append(&"letter_b")
	assert_bool(SeedPurse.can_buy(_rumour, _stock, _found, data)).is_false()

func test_on_sale_keeps_stock_order_and_hides_what_is_gone() -> void:
	var data := _data(0)
	assert_array(SeedPurse.on_sale(_stock, _found, data)).contains_exactly([_map_a, _map_b, _rumour, _replant])
	data.offers_bought.append_array([&"map_b", &"replant"])
	data.rumours.append_array([&"letter_a", &"letter_b"])
	assert_array(SeedPurse.on_sale(_stock, _found, data)).contains_exactly([_map_a])

func test_bought_map_regions() -> void:
	var data := _data(0)
	data.offers_bought.append_array([&"replant", &"map_b"])
	assert_array(Array(SeedPurse.bought_map_regions(_stock, data))).contains_exactly(["REGION_B"])
