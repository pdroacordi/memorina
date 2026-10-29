class_name SeedStockTest extends GdUnitTestSuite

## The shipped stock validates and sells one map per world region but the village (systems/seeds-and-the-seller).

const REGIONS_DIR := "res://scenes/world/rooms"
const NO_MAP: Array[String] = ["home_village"]

var _stock: SeedStock


func before_test() -> void:
	_stock = load(SeedStock.DEFAULT_PATH) as SeedStock

func test_the_shipped_stock_is_valid() -> void:
	assert_array(Array(_stock.validate())).is_empty()
	assert_object(_stock.rumour()).is_not_null()
	assert_int(_stock.rumour().price).is_equal(1)
	assert_int(_stock.get_offer(&"replant_village").price).is_equal(3)

func test_one_map_per_world_region_but_the_village() -> void:
	var expected: Array[String] = []
	for file: String in DirAccess.get_files_at(REGIONS_DIR):
		if file.get_extension() != "tscn" or file.begins_with("trials_") or file.get_basename() in NO_MAP:
			continue
		var region := (load(REGIONS_DIR.path_join(file)) as PackedScene).instantiate() as Region
		expected.append(region.name_key)
		region.free()
	var sold: Array[String] = []
	for offer: SeedOffer in _stock.offers:
		if offer.kind == SeedOffer.Kind.MAP:
			assert_int(offer.price).is_equal(1)
			sold.append(offer.region_key)
	assert_int(expected.size()).is_equal(6)
	assert_array(sold).contains_exactly_in_any_order(expected)

func test_a_bad_stock_reports_each_problem() -> void:
	var bad := SeedStock.new()
	bad.offers.append(offer(&"a", SeedOffer.Kind.MAP, 1, "REGION_X"))
	bad.offers.append(offer(&"a", SeedOffer.Kind.MAP, 0, "REGION_X"))
	bad.offers.append(offer(&"b", SeedOffer.Kind.MAP, 1, ""))
	bad.offers.append(offer(&"", SeedOffer.Kind.RUMOUR, 1, ""))
	var problems := "\n".join(bad.validate())
	assert_str(problems).contains("a is listed twice")
	assert_str(problems).contains("a costs 0 seeds")
	assert_str(problems).contains("sells REGION_X twice")
	assert_str(problems).contains("b names no region")
	assert_str(problems).contains("an offer has no id")
	assert_str(problems).contains("0 offers of kind %d" % SeedOffer.Kind.RUMOUR)
	assert_str(problems).contains("0 offers of kind %d" % SeedOffer.Kind.REPLANT)

static func offer(id: StringName, kind: SeedOffer.Kind, price: int, region_key: String) -> SeedOffer:
	var made := SeedOffer.new()
	made.id = id
	made.kind = kind
	made.price = price
	made.region_key = region_key
	return made
