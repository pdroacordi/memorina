class_name SeedShopBeatTest extends GdUnitTestSuite

## The seller's trade beat opens the panel on the offers on sale and the seeds held, checks each purchase against the
## save, records it, and finishes on Leave (systems/seeds-and-the-seller).

const BEAT := preload("res://scenes/world/story/seed_shop_beat.tscn")
const LETTER := preload("res://assets/sprites/world/pickups/letter.png")

var _beat: SeedShopBeat
var _finished: int = 0
var _stock: SeedStock


func before_test() -> void:
	SaveSystem.begin("", true)
	_finished = 0
	_stock = SeedStock.new()
	_stock.offers.append(SeedStockTest.offer(&"map_threshold", SeedOffer.Kind.MAP, 1, "REGION_THRESHOLD"))
	_stock.offers.append(SeedStockTest.offer(&"rumour", SeedOffer.Kind.RUMOUR, 1, ""))
	_stock.offers.append(SeedStockTest.offer(&"replant_village", SeedOffer.Kind.REPLANT, 3, ""))
	var found := FoundCatalog.new()
	for slot_id: StringName in [&"letter_a", &"letter_b"]:
		var piece := FoundPiece.new()
		piece.slot_id = slot_id
		piece.room = &"threshold_bridge"
		piece.texture = LETTER
		found.pieces.append(piece)
	# The rumour's said line names the region of the piece's room, read from the world.
	add_child(auto_free((load("res://scenes/world/rooms/threshold.tscn") as PackedScene).instantiate()))
	_beat = auto_free(BEAT.instantiate()) as SeedShopBeat
	_beat.stock = _stock
	_beat.found = found
	add_child(_beat)
	_beat.finished.connect(func() -> void: _finished += 1)

func after_test() -> void:
	get_viewport().gui_release_focus()
	# A purchase rebuilds the rows; the old ones are freed at the frame's end.
	await await_idle_frame()
	SaveSystem.begin("", true)

func _take(count: int) -> void:
	for i: int in count:
		SaveSystem.take_cache(StringName("cache_%d" % i))

func test_it_answers_the_seller_shop_cue() -> void:
	assert_str(String(_beat.cue)).is_equal("seller_shop")
	assert_int(_beat.hold).is_equal(DialogueBeat.Hold.STILL)
	assert_object(DialogueBeat.find(get_tree(), &"seller_shop")).is_same(_beat)

func test_start_opens_the_panel_with_the_stock_on_sale_and_the_count() -> void:
	_take(2)
	SaveSystem.buy_offer(&"map_threshold")
	_beat.start()
	var panel := _beat.panel()
	assert_bool(panel.visible).is_true()
	assert_object(panel.row(&"map_threshold")).is_null()
	assert_object(panel.row(&"rumour")).is_not_null()
	assert_str(panel.held_label().text).is_equal(tr("SHOP_SEEDS_HELD") % 1)

func test_a_buy_writes_the_save_and_refreshes_the_panel() -> void:
	_take(4)
	_beat.start()
	_beat.panel().chosen.emit(&"map_threshold")
	assert_array(SaveSystem.player_data.offers_bought).contains_exactly([&"map_threshold"])
	assert_object(_beat.panel().row(&"map_threshold")).is_null()
	assert_str(_beat.panel().held_label().text).is_equal(tr("SHOP_SEEDS_HELD") % 3)
	assert_str(_beat.panel().said_label().text).is_equal(tr("SHOP_SAID_MAP"))
	_beat.panel().chosen.emit(&"replant_village")
	assert_bool(SaveFact.check(SaveFact.Kind.OFFER_BOUGHT, 0, SaveSystem.player_data, &"replant_village")).is_true()
	assert_str(_beat.panel().held_label().text).is_equal(tr("SHOP_SEEDS_HELD") % 0)

func test_an_offer_the_player_cannot_afford_is_refused() -> void:
	_take(2)
	_beat.start()
	_beat.panel().chosen.emit(&"replant_village")
	assert_array(SaveSystem.player_data.offers_bought).is_empty()
	_beat.panel().chosen.emit(&"no_such_offer")
	assert_array(SaveSystem.player_data.offers_bought).is_empty()

func test_a_rumour_records_the_next_piece() -> void:
	_take(2)
	_beat.start()
	_beat.panel().chosen.emit(&"rumour")
	assert_array(SaveSystem.player_data.rumours).contains_exactly([&"letter_a"])
	assert_str(_beat.panel().said_label().text).is_equal(tr("SHOP_SAID_RUMOUR") % tr("REGION_THRESHOLD"))
	_beat.panel().chosen.emit(&"rumour")
	assert_array(SaveSystem.player_data.rumours).contains_exactly([&"letter_a", &"letter_b"])
	assert_object(_beat.panel().row(&"rumour")).is_null()

func test_leave_closes_the_panel_and_finishes_the_beat() -> void:
	_beat.start()
	_beat.panel().left.emit()
	assert_bool(_beat.panel().visible).is_false()
	assert_int(_finished).is_equal(1)

## Over the world's layer 1, whose greyhush pass would shade the panel, and under the menus (bugs/the-seed-shop-panel-draws-under-the-greyhush-and-the-creature-composite).
func test_the_panel_draws_between_the_world_and_the_menus() -> void:
	var game := load("res://scenes/world/game.tscn").instantiate() as Node
	var world_ui := (game.get_node("CanvasLayer") as CanvasLayer).layer
	var menus := (game.get_node("ScreenLayer") as CanvasLayer).layer
	game.free()
	var shop := (BEAT.instantiate() as Node)
	var layer := (shop.get_node("Layer") as CanvasLayer).layer
	shop.free()
	assert_int(layer).is_greater(world_ui)
	assert_int(layer).is_less(menus)
