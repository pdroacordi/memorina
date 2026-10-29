class_name SeedShopTextFitTest extends GdUnitTestSuite

## Every shop text fits its place in every shipped language: each row with each region's name beside its price, the
## count at two digits, and each said line inside its two rows (systems/seeds-and-the-seller).

const PANEL := preload("res://scenes/ui/seed_shop/seed_shop_panel.tscn")
const LOCALES: Array[String] = ["en", "pt_BR"]
const REGION_KEYS: Array[String] = [
	"REGION_HOME_VILLAGE", "REGION_THRESHOLD", "REGION_FROST_EDGE", "REGION_SPRING_WOODS", "REGION_FROZEN_LAKE",
	"REGION_WIND_ORCHARDS", "REGION_SUMMER_CALDERA",
]

var _panel: SeedShopPanel
var _locale: String


func before() -> void:
	_locale = TranslationServer.get_locale()

func after() -> void:
	TranslationServer.set_locale(_locale)

func before_test() -> void:
	_panel = auto_free(PANEL.instantiate()) as SeedShopPanel
	add_child(_panel)

func _none() -> Array[SeedOffer]:
	return []

func _width(control: Control, text: String) -> float:
	var font := control.get_theme_font(&"font")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, control.get_theme_font_size(&"font_size")).x

func test_every_row_fits_beside_its_price() -> void:
	var stock := load(SeedStock.DEFAULT_PATH) as SeedStock
	_panel.open(stock.offers, 12)
	await await_idle_frame()
	var room := _panel.text_room()
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		for offer: SeedOffer in stock.offers:
			var text := _panel.row_text(offer)
			assert_float(_width(_panel.leave_button(), text)).override_failure_message(
					"[%s] %s: '%s' is wider than %.0f px" % [locale, offer.id, text, room]).is_less_equal(room)
		var leave := tr("SHOP_LEAVE")
		assert_float(_width(_panel.leave_button(), leave)).is_less_equal(room)

func test_the_count_fits_at_two_digits() -> void:
	_panel.open(_none(), 12)
	await await_idle_frame()
	var label := _panel.held_label()
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		var text := tr("SHOP_SEEDS_HELD") % 99
		assert_float(_width(label, text)).override_failure_message("[%s] '%s'" % [locale, text]).is_less_equal(label.size.x)

func test_every_said_line_fits_its_rows() -> void:
	_panel.open(_none(), 0)
	await await_idle_frame()
	var label := _panel.said_label()
	var font := label.get_theme_font(&"font")
	var font_size := label.get_theme_font_size(&"font_size")
	for locale: String in LOCALES:
		TranslationServer.set_locale(locale)
		var texts: Array[String] = [tr("SHOP_SAID_MAP"), tr("SHOP_SAID_REPLANT")]
		for region: String in REGION_KEYS:
			texts.append(tr("SHOP_SAID_RUMOUR") % tr(region))
		for text: String in texts:
			var needed := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, label.size.x, font_size).y
			assert_float(needed).override_failure_message(
					"[%s] '%s' needs %.0f px, the line has %.0f" % [locale, text, needed, label.size.y]).is_less_equal(label.size.y)
