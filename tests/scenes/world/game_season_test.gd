class_name GameSeasonTest extends GdUnitTestSuite

## Game is the only writer of the field's season and palettes: it follows the year of the region Ivo is in, and a
## year's commit reaches the field only while he is there (architecture/story-07-epilogue, "One writer each").

const GAME := preload("res://scenes/world/game.gd")
const CATALOG := preload("res://resources/songs/song_catalog.tres")
const VILLAGE := "res://scenes/world/rooms/home_village.tscn"

var _game: Node2D
var _field: MemoryField
var _village: Region


func before_test() -> void:
	SaveSystem.begin("", true)
	_field = auto_free(MemoryField.new()) as MemoryField
	add_child(_field)
	_village = auto_free((load(VILLAGE) as PackedScene).instantiate()) as Region
	add_child(_village)
	_game = auto_free(GAME.new()) as Node2D
	_game.set(&"song_catalog", CATALOG)
	_game.set(&"_memory_field", _field)

func after_test() -> void:
	SaveSystem.begin("", true)

func _enter(region_year: RegionYear, season: Enums.Season) -> void:
	_game.call(&"_follow_year", region_year)
	_game.call(&"_write_season", season)

func test_a_commit_in_the_village_writes_the_season_and_both_palettes() -> void:
	var year := _village.year
	_enter(year, _village.current_season())
	assert_object(_field.year).is_same(year)
	assert_int(_field.season).is_equal(Enums.Season.SPRING)
	assert_object(_field.palette).is_same(CATALOG.palette_for(Enums.Season.SPRING))
	assert_object(_field.next_palette).is_same(CATALOG.palette_for(Enums.Season.SUMMER))
	year.advance(year.stats.season_seconds)
	assert_int(_field.season).is_equal(Enums.Season.SUMMER)
	assert_object(_field.palette).is_same(CATALOG.palette_for(Enums.Season.SUMMER))
	assert_object(_field.next_palette).is_same(CATALOG.palette_for(Enums.Season.AUTUMN))

func test_elsewhere_the_year_never_reaches_the_field() -> void:
	var year := _village.year
	_enter(year, _village.current_season())
	_enter(null, Enums.Season.WINTER)
	assert_object(_field.year).is_null()
	assert_object(_field.next_palette).is_null()
	year.advance(year.stats.season_seconds)
	assert_int(_field.season).is_equal(Enums.Season.WINTER)
	_enter(year, _village.current_season())
	assert_int(_field.season).is_equal(Enums.Season.SUMMER)
